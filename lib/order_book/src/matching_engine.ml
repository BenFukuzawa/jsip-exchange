open! Core
open Jsip_types

(* Keep track of the current people in the exchange via their name and their
   own unique order id *)
module Client_key = struct
  module T = struct
    type t = Participant.t * Client_order_id.t
    [@@deriving compare, hash, sexp]
  end

  include T
  include Hashable.Make (T)
end

(* Interns each traded symbol to a small integer id at [create] and stores the
   books in a flat array indexed by that id. Resolving a symbol is then one
   string hash (into [symbol_ids]) plus an O(1) array index, rather than the
   O(log n) string comparisons a [Symbol.Map] does. The symbol set is fixed at
   [create] and never grows, so ids are stable for the engine's life and the
   array can be fixed-size. (This is also the interning layer Exercise 4 later
   pushes onto the wire.) *)
module Symbol_registry = struct
  type t =
    { symbol_ids : int Symbol.Table.t
    ; books : Order_book.t array
    }
  [@@deriving sexp_of]

  (* Assign symbol at position [id] the id [id]; [add_exn] rejects a duplicate
     symbol, matching the old [Symbol.Map.of_alist_exn]. *)
  let create symbols =
    let symbol_ids = Symbol.Table.create () in
    let books =
      List.mapi symbols ~f:(fun id sym ->
        Hashtbl.add_exn symbol_ids ~key:sym ~data:id;
        Order_book.create sym)
      |> Array.of_list
    in
    { symbol_ids; books }
  ;;

  (* [None] for a symbol this engine doesn't trade. *)
  let find t symbol =
    match Hashtbl.find t.symbol_ids symbol with
    | None -> None
    | Some id -> Some t.books.(id)
  ;;

  let find_exn t symbol =
    match find t symbol with
    | Some book -> book
    | None ->
      raise_s
        [%message "Symbol_registry.find_exn: unknown symbol" (symbol : Symbol.t)]
  ;;
end

type t =
  { registry : Symbol_registry.t
  ; order_id_gen : Order_id.Generator.t
  ; mutable next_fill_id : int
  ; seen_client_ids : Order.t Client_key.Table.t
  }
[@@deriving sexp_of]

let create symbols =
  { registry = Symbol_registry.create symbols
  ; order_id_gen = Order_id.Generator.create ()
  ; next_fill_id = 1
  ; seen_client_ids = Client_key.Table.create ()
  }
;;

let book t symbol = Symbol_registry.find t.registry symbol

(** Run the matching loop: repeatedly find a compatible resting order and
    fill against it. Returns the list of Fill and Trade_report events
    produced, and the next fill_id to use. *)
let rec match_loop ~book ~order ~fill_id =
  if Size.( <= ) (Order.remaining_size order) Size.zero
  then [], fill_id
  else (
    match Order_book.find_match book order with
    | None -> [], fill_id
    | Some resting ->
      let fill_size =
        Size.min (Order.remaining_size order) (Order.remaining_size resting)
      in
      Order.fill order ~by:fill_size;
      Order.fill resting ~by:fill_size;
      if Order.is_fully_filled resting
      then Order_book.remove book (Order.order_id resting);
      let fill_event =
        Exchange_event.Fill
          { fill_id
          ; symbol = Order.symbol order
          ; price = Order.price resting
          ; size = fill_size
          ; aggressor_order_id = Order.order_id order
          ; aggressor_participant = Order.participant order
          ; aggressor_side = Order.side order
          ; resting_order_id = Order.order_id resting
          ; resting_participant = Order.participant resting
          ; aggressor_client_order_id = Order.client_order_id order
          ; resting_client_order_id = Order.client_order_id resting
          }
      in
      let trade_event =
        Exchange_event.Trade_report
          { symbol = Order.symbol order
          ; price = Order.price resting
          ; size = fill_size
          }
      in
      let remaining_events, next_fill_id =
        match_loop ~book ~order ~fill_id:(fill_id + 1)
      in
      fill_event :: trade_event :: remaining_events, next_fill_id)
;;

let submit t (request : Order.Request.t) =
  let key = request.participant, request.client_order_id in
  if Hashtbl.mem t.seen_client_ids key
  then
    [ Exchange_event.Order_reject
        { request; reason = "duplicate client order id" }
    ]
  else (
    match Symbol_registry.find t.registry request.symbol with
    | None ->
      [ Exchange_event.Order_reject { request; reason = "unknown symbol" } ]
    | Some book ->
      let order_id = Order_id.Generator.next t.order_id_gen in
      let order = Order.create request ~order_id in
      Hashtbl.set
        t.seen_client_ids
        ~key:(request.participant, request.client_order_id)
        ~data:order;
      let accepted = Exchange_event.Order_accept { order_id; request } in
      (* Snapshot BBO before matching so we can detect changes. *)
      let bbo_before = Order_book.best_bid_offer book in
      (* Match *)
      let fill_events, next_fill_id =
        match_loop ~book ~order ~fill_id:t.next_fill_id
      in
      t.next_fill_id <- next_fill_id;
      (* Post-match: rest on book or cancel unfilled remainder. *)
      let post_events =
        if Size.( > ) (Order.remaining_size order) Size.zero
        then (
          match Order.time_in_force order with
          | Day ->
            Order_book.add book order;
            []
          | Ioc ->
            [ Exchange_event.Order_cancel
                { client_order_id = Order.client_order_id order
                ; order_id
                ; participant = Order.participant order
                ; symbol = Order.symbol order
                ; remaining_size = Order.remaining_size order
                ; reason = Ioc_remainder
                }
            ])
        else []
      in
      (* Emit BBO update if the best bid or ask changed. *)
      let bbo_after = Order_book.best_bid_offer book in
      let bbo_events =
        if Bbo.equal bbo_before bbo_after
        then []
        else
          [ Exchange_event.Best_bid_offer_update
              { symbol = Order.symbol order; bbo = bbo_after }
          ]
      in
      List.concat [ [ accepted ]; fill_events; post_events; bbo_events ])
;;

(* A cancel names an order by [(participant, client_order_id)]. By the time
   we call this we've already found the order in [seen_client_ids] — but that
   table retains every id for the life of the exchange (so ids can't be
   reused), which means a fully-filled or already-cancelled order is still
   "seen" even though it's no longer resting in [book]. Book membership is
   therefore what distinguishes a live, cancellable order from one that's
   already gone.

   Produce the events the cancel yields:
   - if [order] is no longer resting in [book]: a single [Cancel_reject] with
     reason ["order not found"];
   - otherwise: remove it from [book] and emit an [Order_cancel] (reason
     [Participant_requested]), followed by a [Best_bid_offer_update] iff the
     removal changed the best bid or offer (decide this the same way [submit]
     does above). *)
let events_for_cancel ~book ~participant ~client_order_id ~order =
  let id = Order.order_id order in
  match Order_book.find book id with
  | None ->
    [ Exchange_event.Cancel_reject
        { participant; client_order_id; reason = "order not found" }
    ]
  | Some order ->
    let bbo_before = Order_book.best_bid_offer book in
    Order_book.remove book id;
    let cancel =
      [ Exchange_event.Order_cancel
          { client_order_id
          ; order_id = id
          ; participant
          ; symbol = Order.symbol order
          ; remaining_size = Order.remaining_size order
          ; reason = Participant_requested
          }
      ]
    in
    let bbo_after = Order_book.best_bid_offer book in
    let bbo_events =
      if Bbo.equal bbo_before bbo_after
      then []
      else
        [ Exchange_event.Best_bid_offer_update
            { symbol = Order.symbol order; bbo = bbo_after }
        ]
    in
    List.concat [ cancel; bbo_events ]
;;

let cancel t ~participant ~client_order_id =
  let key = participant, client_order_id in
  match Hashtbl.find t.seen_client_ids key with
  | None ->
    (* This participant never used this id, so there is nothing to cancel. We
       deliberately do not remove ids from [seen_client_ids] on cancel
       either: once used, an id stays reserved to prevent accidental reuse. *)
    [ Exchange_event.Cancel_reject
        { participant; client_order_id; reason = "order not found" }
    ]
  | Some order ->
    let book = Symbol_registry.find_exn t.registry (Order.symbol order) in
    events_for_cancel ~book ~participant ~client_order_id ~order
;;
