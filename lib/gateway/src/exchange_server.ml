open! Core
open! Async
open Jsip_types
open Jsip_order_book

module Connection_state = struct
  type t = { mutable session : Session.t option }

  let participant t = Option.map t.session ~f:Session.participant
end

type t =
  { engine : Matching_engine.t
  ; dispatcher : Dispatcher.t
  ; request_writer : Order.Request.t Pipe.Writer.t
  ; tcp_server : (Socket.Address.Inet.t, int) Tcp.Server.t
  ; port : int
  }

(* Bound how many client requests can sit in the queue waiting for the
   matching engine. Once the queue is full, [Pipe.write] returns a pending
   deferred and the [submit_order_rpc] handler blocks until the engine has
   processed enough requests to free up space — clients get backpressure
   without the server's memory growing unboundedly. *)
let request_queue_size_budget = 1024

let handle_submit ~request_writer (request : Order.Request.t) =
  let%map () = Pipe.write_if_open request_writer request in
  Ok ()
;;

let start_matching_loop ~engine ~dispatcher request_reader =
  don't_wait_for
    (Pipe.iter_without_pushback request_reader ~f:(fun request ->
       let events = Matching_engine.submit engine request in
       Dispatcher.dispatch dispatcher events))
;;

let start ~symbols ~port () =
  let engine = Matching_engine.create symbols in
  let dispatcher = Dispatcher.create () in
  let request_reader, request_writer = Pipe.create () in
  Pipe.set_size_budget request_writer request_queue_size_budget;
  start_matching_loop ~engine ~dispatcher request_reader;
  let implementations =
    Rpc.Implementations.create_exn
      ~implementations:
        [ (* Login RPC: validates name, creates session, registers on
             dispatcher. Returns error if name is empty/whitespace-only
             or if the participant is already logged in. *)
          Rpc.Rpc.implement
            Rpc_protocol.login_rpc
            (fun (state : Connection_state.t) name ->
               let name = String.strip name in
               if String.is_empty name
               then return (Or_error.error_string "name must not be empty")
               else (
                 let participant = Participant.of_string name in
                 if Hashtbl.mem dispatcher.active_sessions participant
                 then
                   return
                     (Or_error.error_string
                        [%string
                          "participant %{name} is already logged in"])
                 else (
                   let%map () =
                     Dispatcher.set_up_session dispatcher participant
                   in
                   let session =
                     Hashtbl.find_exn dispatcher.active_sessions participant
                   in
                   state.session <- Some session;
                   Ok participant)))
        ; (* Submit order RPC: requires login. Overrides request
             participant with the logged-in identity. *)
          Rpc.Rpc.implement
            Rpc_protocol.submit_order_rpc
            (fun (state : Connection_state.t) request ->
               match Connection_state.participant state with
               | None ->
                 return (Or_error.error_string "not logged in")
               | Some participant ->
                 let request =
                   { request with Order.Request.participant }
                 in
                 handle_submit ~request_writer request)
        ; Rpc.Rpc.implement'
            Rpc_protocol.book_query_rpc
            (fun _state symbol ->
               Matching_engine.book engine symbol
               |> Option.map ~f:Order_book.snapshot)
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.market_data_rpc
            (fun _state symbols ->
               let reader =
                 Dispatcher.subscribe_market_data dispatcher symbols
               in
               return (Ok reader))
        ; Rpc.Pipe_rpc.implement
            Rpc_protocol.audit_log_rpc
            (fun _state () ->
               let reader = Dispatcher.subscribe_audit dispatcher in
               return (Ok reader))
        ; (* Session feed RPC: returns the logged-in participant's
             session event pipe. *)
          Rpc.Pipe_rpc.implement
            Rpc_protocol.session_feed_rpc
            (fun (state : Connection_state.t) () ->
               match state.session with
               | None ->
                 return (Error (Error.of_string "not logged in"))
               | Some session ->
                 return (Ok (Session.reader session)))
        ]
      ~on_unknown_rpc:`Close_connection
      ~on_exception:Log_on_background_exn
  in
  let%map tcp_server =
    Rpc.Connection.serve
      ~implementations
      ~initial_connection_state:(fun _addr conn ->
        let state = { Connection_state.session = None } in
        (* Clean up the session when the connection closes. *)
        don't_wait_for
          (let%bind () = Rpc.Connection.close_finished conn in
           match state.session with
           | None -> Deferred.unit
           | Some session -> Dispatcher.clean_up_session dispatcher session);
        state)
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ()
  in
  let actual_port = Tcp.Server.listening_on tcp_server in
  { engine; dispatcher; request_writer; tcp_server; port = actual_port }
;;

let port t = t.port

let close t =
  Pipe.close t.request_writer;
  Tcp.Server.close t.tcp_server
;;

let close_finished t = Tcp.Server.close_finished t.tcp_server
