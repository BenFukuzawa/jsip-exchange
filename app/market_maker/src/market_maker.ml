open! Core
open! Async
open Jsip_types
open Jsip_gateway

module Config = struct
  type t =
    { participant : Participant.t
    ; symbol : Symbol.t
    ; fair_value_cents : int
    ; half_spread_cents : int
    ; size_per_level : int
    ; num_levels : int
    }
  [@@deriving sexp_of]
end

module State = struct
  type t =
    { participant : Participant.t
    ; inventory : int Symbol.Table.t
    ; resting_orders : Client_order_id.Hash_set.t
    }

  let create participant =
    { participant
    ; inventory = Symbol.Table.create ()
    ; resting_orders = Hash_set.create (module Client_order_id)
    }
  ;;
end

let seed_book (config : Config.t) conn =
  let submit request =
    let%map result =
      Rpc.Rpc.dispatch_exn Rpc_protocol.submit_order_rpc conn request
    in
    match result with
    | Ok () -> ()
    | Error msg ->
      [%log.error
        "market_maker: submit failed"
          (request : Order.Request.t)
          (msg : Error.t)]
  in
  Deferred.List.iter
    ~how:`Parallel
    (List.init config.num_levels ~f:Fn.id)
    ~f:(fun level ->
      let offset = config.half_spread_cents + level in
      let%bind () =
        submit
          ({ client_order_id = Client_order_id.of_int 0
           ; symbol = config.symbol
           ; participant = config.participant
           ; side = Buy
           ; price = Price.of_int_cents (config.fair_value_cents - offset)
           ; size = Size.of_int config.size_per_level
           ; time_in_force = Day
           }
           : Order.Request.t)
      and () =
        submit
          ({ client_order_id = Client_order_id.of_int 0
           ; symbol = config.symbol
           ; participant = config.participant
           ; side = Sell
           ; price = Price.of_int_cents (config.fair_value_cents + offset)
           ; size = Size.of_int config.size_per_level
           ; time_in_force = Day
           }
           : Order.Request.t)
      in
      Deferred.unit)
;;

let handle_event (t : State.t) (event : Exchange_event.t) =
  match event with
  | Order_accept { request; _ } ->
    Hash_set.add t.resting_orders request.client_order_id
  | Order_cancel { client_order_id; _ } ->
    Hash_set.remove t.resting_orders client_order_id
  | Order_reject _ | Best_bid_offer_update _ | Trade_report _
  | Cancel_reject _ ->
    ()
  | Fill fill ->
    let is_aggressor =
      Participant.equal t.participant fill.aggressor_participant
    in
    let is_resting =
      Participant.equal t.participant fill.resting_participant
    in
    (match is_aggressor || is_resting with
     | true ->
       let our_side =
         if is_aggressor
         then fill.aggressor_side
         else Side.flip fill.aggressor_side
       in
       let our_client_id =
         if is_aggressor
         then fill.aggressor_client_order_id
         else fill.resting_client_order_id
       in
       Hashtbl.change t.inventory fill.symbol ~f:(fun current_inv_opt ->
         let current_inv =
           match current_inv_opt with None -> 0 | Some inv -> inv
         in
         let size_int = Size.to_int fill.size in
         match our_side with
         | Buy -> Some (current_inv + size_int)
         | Sell -> Some (current_inv - size_int));
       Hash_set.remove t.resting_orders our_client_id
     | false -> ())
;;

let run ~port (config : Config.t) =
  let where =
    Tcp.Where_to_connect.of_host_and_port { host = "localhost"; port }
  in
  let%bind conn = Rpc.Connection.client where >>| Result.ok_exn in
  let%bind (_ : Participant.t) =
    Rpc.Rpc.dispatch_exn
      Rpc_protocol.login_rpc
      conn
      (Participant.to_string config.participant)
    >>| Or_error.ok_exn
  in
  let%bind session_feed, _metadata =
    Rpc.Pipe_rpc.dispatch_exn Rpc_protocol.session_feed_rpc conn ()
  in
  let state = State.create config.participant in
  don't_wait_for
    (Pipe.iter_without_pushback session_feed ~f:(fun event ->
       handle_event state event));
  let%bind () = seed_book config conn in
  Deferred.never ()
;;
