open! Core
open! Async
open Jsip_types
open Jsip_order_book
open Jsip_exchange_stats

module Connection_state = struct
  type t = { mutable session : Session.t option }

  let participant t = Option.map t.session ~f:Session.participant
end

(* What sits in the request queue between the [submit_order_rpc] handler and
   the matching loop. [received_at] is stamped when the handler runs so the
   loop can measure receipt-to-handled latency; it lives here, not on
   [Order.Request.t], because the queue is server-internal and the wire shape
   of [Order.Request.t] is pinned by [test_rpc_shapes.ml]. *)
module Queued_request = struct
  type t =
    { request : Order.Request.t
    ; received_at : Time_ns.t
    }
end

type t =
  { engine : Matching_engine.t
  ; dispatcher : Dispatcher.t
  ; request_writer : Queued_request.t Pipe.Writer.t
  ; tcp_server : (Socket.Address.Inet.t, int) Tcp.Server.t
  ; port : int
  }

(* Bound how many client requests can sit in the queue waiting for the
   matching engine. Once the queue is full, [Pipe.write] returns a pending
   deferred and the [submit_order_rpc] handler blocks until the engine has
   processed enough requests to free up space — clients get backpressure
   without the server's memory growing unboundedly. *)
let request_queue_size_budget = 1024

(* How often the server samples itself for the exchange-stats feed. The
   part-3 exercises assume at least one snapshot per second, and the
   dashboard's "per second" tiles (ops/s, alloc/s) assume exactly one — if
   this changes, the dashboard's rate labels need revisiting. *)
let stats_sampling_interval = Time_ns.Span.second

let handle_submit ~request_writer (request : Order.Request.t) =
  let queued = { Queued_request.request; received_at = Time_ns.now () } in
  let%map () = Pipe.write_if_open request_writer queued in
  Ok ()
;;

let start_matching_loop ~engine ~dispatcher ~collector request_reader =
  don't_wait_for
    (Pipe.iter_without_pushback
       request_reader
       ~f:(fun { Queued_request.request; received_at } ->
         let events = Matching_engine.submit engine request in
         Dispatcher.dispatch dispatcher events;
         (* "Handled" includes dispatching the resulting events: fan-out is
            part of the per-order work the spammer stresses, so it belongs in
            the measured interval. *)
         Exchange_stats.Collector.record_submit_latency
           collector
           (Time_ns.diff (Time_ns.now ()) received_at)))
;;

(* The stats feed's subscriber registry, mirroring the subscribe/publish
   shape of [Dispatcher]'s audit feed but kept out of the dispatcher:
   snapshots are infrastructure metrics, not [Exchange_event.t]s, and the
   dispatcher's job is routing market events. Like every other subscriber
   pipe (see section 3a of the part-3 exercises), these writes are unbounded
   — a dashboard that stops reading grows this buffer at one snapshot per
   second. *)
let subscribe_stats stats_subscribers =
  let reader, writer = Pipe.create () in
  let elt = Bag.add stats_subscribers writer in
  don't_wait_for
    (let%map () = Pipe.closed writer in
     Bag.remove stats_subscribers elt);
  reader
;;

let start_stats_loop ~dispatcher ~collector ~stats_subscribers ~stop =
  (* Snapshotting every second regardless of subscribers keeps the
     collector's accumulators drained (bounded memory) and makes the sampling
     cost — [Gc.stat] walks the heap — uniform rather than appearing only
     when a dashboard connects. Note the observer effect: that heap walk
     pauses the scheduler, so a request queued while it runs has the pause
     added to its measured latency — a once-per-second p99 blip the dashboard
     itself causes. *)
  Clock_ns.every ~stop stats_sampling_interval (fun () ->
    let snapshot =
      Exchange_stats.Collector.snapshot
        collector
        ~sampled_at:(Time_ns.now ())
        ~gc:(Exchange_stats.Gc_stats.of_stat (Gc.stat ()))
        ~pipe_occupancy:(Dispatcher.pipe_occupancy dispatcher)
    in
    Bag.iter stats_subscribers ~f:(fun writer ->
      Pipe.write_without_pushback_if_open writer snapshot))
;;

let start ~symbols ~port () =
  let engine = Matching_engine.create symbols in
  let registry = Participant_registry.create () in
  let dispatcher = Dispatcher.create registry in
  let collector = Exchange_stats.Collector.create () in
  let stats_subscribers = Bag.create () in
  let request_reader, request_writer = Pipe.create () in
  Pipe.set_size_budget request_writer request_queue_size_budget;
  start_matching_loop ~engine ~dispatcher ~collector request_reader;
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations:
        [ Rpc.Rpc.implement
            Rpc_protocol.login_rpc
            (fun (state : Connection_state.t) name ->
               let name = String.strip name in
               let%bind.Deferred.Or_error () =
                 (match String.is_empty name with
                  | true -> Or_error.error_string "name must not be empty"
                  | false -> Ok ())
                 |> return
               in
               let participant = Participant.of_string name in
               if Hashtbl.mem
                    dispatcher.active_sessions
                    (Participant_registry.intern
                       dispatcher.registry
                       participant)
               then
                 return
                   (Or_error.error_string
                      [%string "participant %{name} is already logged in"])
               else (
                 let%map () =
                   Dispatcher.set_up_session dispatcher participant
                 in
                 let session =
                   Hashtbl.find_exn
                     dispatcher.active_sessions
                     (Participant_registry.intern
                        dispatcher.registry
                        participant)
                 in
                 state.session <- Some session;
                 Ok participant))
        ; Rpc.Rpc.implement
            Rpc_protocol.submit_order_rpc
            (fun state request ->
               match Connection_state.participant state with
               | None -> return (Or_error.error_string "not logged in")
               | Some participant ->
                 let request = { request with Order.Request.participant } in
                 handle_submit ~request_writer request)
        ; Rpc.Rpc.implement' Rpc_protocol.book_query_rpc (fun state symbol ->
            ignore state;
            Matching_engine.book engine symbol
            |> Option.map ~f:Order_book.snapshot)
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.market_data_rpc
            (fun state symbols ->
               ignore state;
               let reader =
                 Dispatcher.subscribe_market_data dispatcher symbols
               in
               return (Ok reader))
        ; Rpc.Pipe_rpc.implement Rpc_protocol.audit_log_rpc (fun state () ->
            ignore state;
            let reader = Dispatcher.subscribe_audit dispatcher in
            return (Ok reader))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.session_feed_rpc
            (fun (state : Connection_state.t) () ->
               match state.session with
               | None -> return (Or_error.error_string "not active session")
               | Some session -> return (Ok (Session.reader session)))
        ; Rpc.Rpc.implement'
            Rpc_protocol.cancel_order_rpc
            (fun state client_order_id ->
               match Connection_state.participant state with
               | None -> Or_error.error_string "not logged in"
               | Some participant ->
                 (* Unlike submits, cancels run synchronously in the handler
                    (no queue), so the whole measured interval is right here. *)
                 let received_at = Time_ns.now () in
                 let events =
                   Matching_engine.cancel
                     engine
                     ~participant
                     ~client_order_id
                 in
                 Dispatcher.dispatch dispatcher events;
                 Exchange_stats.Collector.record_cancel_latency
                   collector
                   (Time_ns.diff (Time_ns.now ()) received_at);
                 Ok ())
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.exchange_stats_rpc
            (fun (_ : Connection_state.t) () ->
               return (Ok (subscribe_stats stats_subscribers)))
        ]
      ~on_unknown_rpc:`Close_connection
      ~on_exception:Log_on_background_exn
  in
  let%map tcp_server =
    Rpc.Connection.serve
      ~implementations
      ~initial_connection_state:(fun _addr _conn ->
        let state = { Connection_state.session = None } in
        don't_wait_for
          (let%bind () = Rpc.Connection.close_finished _conn in
           match state.session with
           | None -> Deferred.unit
           | Some session -> Dispatcher.clean_up_session dispatcher session);
        state)
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ()
  in
  let actual_port = Tcp.Server.listening_on tcp_server in
  start_stats_loop
    ~dispatcher
    ~collector
    ~stats_subscribers
    ~stop:(Tcp.Server.close_finished tcp_server);
  { engine; dispatcher; request_writer; tcp_server; port = actual_port }
;;

let port t = t.port

let close t =
  Pipe.close t.request_writer;
  Tcp.Server.close t.tcp_server
;;

let close_finished t = Tcp.Server.close_finished t.tcp_server
