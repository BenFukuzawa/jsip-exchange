open! Core
open Jsip_types

(* The order book uses a Map keyed by (Price.t, Order_id.t) per side.
   For the buy side, prices are negated in the key so that Map.min_elt
   always returns the "best" order on both sides:
   - Bids: negated price → min_elt = most negative = highest real price = best bid
   - Asks: natural price → min_elt = lowest price = best ask

   A reverse index (order_ids) maps Order_id.t → Order_key.t for O(log n) removal. *)

module Order_key = struct
  type t = Price.t * Order_id.t [@@deriving compare, sexp]

  include functor Comparable.Make
end

type t =
  { symbol : Symbol.t
  ; mutable bids : Order.t Order_key.Map.t
  ; mutable asks : Order.t Order_key.Map.t
  ; mutable order_ids : Order_key.t Order_id.Map.t
  }
[@@deriving sexp_of]

let create symbol =
  { symbol
  ; bids = Order_key.Map.empty
  ; asks = Order_key.Map.empty
  ; order_ids = Order_id.Map.empty
  }
;;

let symbol t = t.symbol

(* Construct the map key for an order. Buy-side keys use negated prices
   so that Map.min_elt yields the best (highest real price) bid. *)
let make_key (order : Order.t) =
  let price =
    match Order.side order with
    | Buy -> Price.of_int_cents (-(Price.to_int_cents (Order.price order)))
    | Sell -> Order.price order
  in
  price, Order.order_id order
;;

(* Returns map of the appropriate side *)
let side_map t side =
  match (side : Side.t) with Buy -> t.bids | Sell -> t.asks
;;

let set_side_map t side map =
  match (side : Side.t) with Buy -> t.bids <- map | Sell -> t.asks <- map
;;

let add t order =
  let key = make_key order in
  let side = Order.side order in
  set_side_map t side (Map.set (side_map t side) ~key ~data:order);
  t.order_ids <- Map.set t.order_ids ~key:(Order.order_id order) ~data:key
;;

let remove' t order_id =
  match Map.find t.order_ids order_id with
  | None -> None
  | Some key ->
    (* Try bids first, then asks *)
    let found =
      match Map.find t.bids key with
      | Some order ->
        t.bids <- Map.remove t.bids key;
        Some order
      | None ->
        (match Map.find t.asks key with
         | Some order ->
           t.asks <- Map.remove t.asks key;
           Some order
         | None -> None)
    in
    (match found with
     | Some _ -> t.order_ids <- Map.remove t.order_ids order_id
     | None -> ());
    found
;;

let remove t order_id = ignore (remove' t order_id : Order.t option)

let find t order_id =
  match Map.find t.order_ids order_id with
  | None -> None
  | Some key ->
    (match Map.find t.bids key with
     | Some _ as result -> result
     | None -> Map.find t.asks key)
;;

(* find_match: Map.min_elt on the opposite side gives the best resting
   order. Check that the incoming order's price is marketable against
   the resting order's real price. *)
let find_match t incoming =
  let incoming_side = Order.side incoming in
  let opposite_side = Side.flip incoming_side in
  let resting_orders = side_map t opposite_side in
  match Map.min_elt resting_orders with
  | None -> None
  | Some (_, resting) ->
    if Price.is_marketable
         incoming_side
         ~price:(Order.price incoming)
         ~resting_price:(Order.price resting)
    then Some resting
    else None
;;

(* Map.data returns orders in ascending key order (best-first for both sides).
   List.rev flips to worst-first, placing the best prices at the bottom —
   the visual order book layout where bids and asks meet in the middle:
   - Bids: ascending price (best = highest at bottom)
   - Asks: descending price (best = lowest at bottom) *)
let orders_on_side t side = List.rev (Map.data (side_map t side))
let is_empty t = Map.is_empty t.bids && Map.is_empty t.asks
let count t side = Map.length (side_map t side)

let best_level t side : Level.t option =
  match Map.min_elt (side_map t side) with
  | None -> None
  | Some (_, best_order) ->
    let best_price = Order.price best_order in
    let total_size =
      Map.fold (side_map t side) ~init:Size.zero ~f:(fun ~key:_ ~data:order acc ->
        if Price.equal (Order.price order) best_price
        then Size.( + ) acc (Order.remaining_size order)
        else acc)
    in
    Some { price = best_price; size = total_size }
;;

let best_bid_offer t : Bbo.t =
  { bid = best_level t Buy; ask = best_level t Sell }
;;

let snapshot_side t (side : Side.t) =
  orders_on_side t side |> List.map ~f:Level.of_order
;;

let snapshot t =
  { Book.symbol = symbol t
  ; bids = snapshot_side t Buy
  ; asks = snapshot_side t Sell
  ; bbo = best_bid_offer t
  }
;;

module For_testing = struct
  let remove = remove'
end
