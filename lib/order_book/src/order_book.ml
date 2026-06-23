open! Core
open Jsip_types
open Async_log_kernel.Ppx_log_syntax

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

(* returns map of the appropriate side needed *)
let side_map t side =
  match (side : Side.t) with Buy -> t.bids | Sell -> t.asks
;;

(* sets the kv pair that we want and deals with duplicative keys *)
let set_side_map t side key order =
  match (side : Side.t) with
  | Buy -> t.bids <- Map.set ~key ~data:order t.bids
  | Sell ->
    t.asks <- Map.set ~key ~data:order t.asks;
    t.order_ids <- Map.set ~key:(Order.order_id order) ~data:key t.order_ids
;;

let add t order =
  let key = Order.price order, Order.order_id order in
  let side = Order.side order in
  set_side_map t side key order
;;

(* old remove system where we search through the list for the right order and
   we return a new list. refactor this for constant time *)
let remove' t order_id =
  let remove_from t side order_id =
    let remove_key = Map.find t.order_ids order_id in
    match remove_key with
    | None -> None
    | Some removal -> set_side_map t side ap.remove (side_map t side) removal
    (* let orders = side_map t side in match List.partition_tf orders ~f:(fun
       o -> Order_id.equal (Order.order_id o) order_id) with | [], _ -> None
       | [ found ], rest -> set_side_map t side rest; Some found | matches, _
       ->
       [%log.info "BUG: More than one order matching order_id found when removing" (order_id : Order_id.t) (matches : Order.t list) (t.symbol : Symbol.t) (side : Side.t)];
       None *)
  in
  match remove_from t Buy order_id with
  | Some _ as result -> result
  | None -> remove_from t Sell order_id
;;

let remove t order_id = ignore (remove' t order_id : Order.t option)

let find t order_id =
  let find_in side = Map.find (side_map t side) order_id in
  match find_in Buy with Some _ as result -> result | None -> find_in Sell
;;

(* Compares orders order1 and order2 to see which one is better: First sort
   based on higher price (old implementation with list not applicable
   anymore) *)
let compare_better_order ~order1 ~order2 side =
  let compare_val =
    Price.compare (Order.price order1) (Order.price order2)
  in
  if compare_val = 0
  then Order_id.compare (Order.order_id order2) (Order.order_id order1)
  else if Price.is_more_aggressive
            side
            ~price:(Order.price order1)
            ~than:(Order.price order2)
  then 1
  else -1
;;

(* NOTE: This walks the list front-to-back and returns the *first* tradable
   order, not the best-priced one. Orders are in reverse insertion order
   (newest first), so this matches against whatever was most recently added,
   regardless of price. See test_matching_engine.ml for a test that
   demonstrates why this is wrong. *)
let find_match t incoming =
  let incoming_side = Order.side incoming in
  let opposite_side = Side.flip incoming_side in
  let resting_orders = side_map t opposite_side in
  match opposite_side with
  | Buy -> Map.max_elt resting_orders
  | Sell -> Map.min_elt resting_orders
;;

let orders_on_side t side = List.rev (Map.data (side_map t side))
let is_empty t = Map.is_empty t.bids && Map.is_empty t.asks
let count t side = Map.length (side_map t side)

let best_price t side =
  let best_order = side_map t side in
  match side with
  | Buy -> Map.max_elt best_order
  | Sell -> Map.min_elt best_order
;;

(* have to refactor this too *)
let best_level t side : Level.t option =
  match best_price t side with
  | None -> None
  | Some price ->
    let total_size =
      List.fold (side_map t side) ~init:Size.zero ~f:(fun acc order ->
        if Price.equal (Order.price order) price
        then Size.( + ) acc (Order.remaining_size order)
        else acc)
    in
    Some { price; size = total_size }
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
