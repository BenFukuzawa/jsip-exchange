open! Core
open Jsip_types

(** One participant's position in one symbol.

    [cost_basis_cents] is the signed total cost of the currently-open
    position: [inventory * average_entry_price]. Storing the total (rather
    than the average) keeps the arithmetic exact — the average is only
    recovered for display. It is positive for longs and negative for shorts,
    so [cost_basis_cents / inventory] is a positive per-share price either
    way. *)
module Position = struct
  type t =
    { inventory : int
    ; cost_basis_cents : int
    ; realized_cents : int
    }
  [@@deriving sexp_of]

  let empty = { inventory = 0; cost_basis_cents = 0; realized_cents = 0 }
end

type t =
  { positions : Position.t Symbol.Map.t Participant.Map.t
  ; reference_prices : Price.t Symbol.Map.t
  }
[@@deriving sexp_of]

let empty =
  { positions = Participant.Map.empty; reference_prices = Symbol.Map.empty }
;;

(** Fold a single signed fill ([qty] > 0 for a buy, < 0 for a sell) into a
    position using average-cost accounting. *)
let same_direction a b = a * b > 0

let apply_signed_fill (position : Position.t) ~qty ~price_cents : Position.t =
  let { Position.inventory; cost_basis_cents; realized_cents } = position in
  if inventory = 0 || same_direction inventory qty
  then
    (* Opening a position, or adding to one in the same direction: no P&L is
       realized, we just grow the cost basis. *)
    { Position.inventory = inventory + qty
    ; cost_basis_cents = cost_basis_cents + (qty * price_cents)
    ; realized_cents
    }
  else (
    (* Reducing, closing, or flipping the position. *)
    let average_entry_cents = cost_basis_cents / inventory in
    let new_inventory = inventory + qty in
    let new_cost_basis_cents =
      if new_inventory = 0 || same_direction new_inventory inventory
      then
        (* Still on the same side (or now flat): the shares that remain keep
           their original average entry price. *)
        new_inventory * average_entry_cents
      else
        (* Flipped through zero: the old position is fully closed and a fresh
           one opens at this fill's price. *)
        new_inventory * price_cents
    in
    (* Only the shares that overlap the existing position close and realize
       P&L; any excess opens the new side (handled by [new_cost_basis_cents]).
       [direction] carries the sign: a long profits when [price > avg], a
       short profits when [price < avg]. *)
    let closed_shares = Int.min (Int.abs qty) (Int.abs inventory) in
    let direction = if inventory > 0 then 1 else -1 in
    let realized_delta =
      (price_cents - average_entry_cents) * closed_shares * direction
    in
    { Position.inventory = new_inventory
    ; cost_basis_cents = new_cost_basis_cents
    ; realized_cents = realized_cents + realized_delta
    })
;;

let update_position t ~participant ~symbol ~f =
  let symbol_map =
    Map.find t.positions participant
    |> Option.value ~default:Symbol.Map.empty
  in
  let position =
    Map.find symbol_map symbol |> Option.value ~default:Position.empty
  in
  let symbol_map = Map.set symbol_map ~key:symbol ~data:(f position) in
  { t with
    positions = Map.set t.positions ~key:participant ~data:symbol_map
  }
;;

let record t ~participant ~symbol ~side ~price ~size =
  let qty = Side.sign side * Size.to_int size in
  let price_cents = Price.to_int_cents price in
  update_position t ~participant ~symbol ~f:(fun position ->
    apply_signed_fill position ~qty ~price_cents)
;;

let apply_fill t (fill : Fill.t) =
  let t =
    record
      t
      ~participant:fill.aggressor_participant
      ~symbol:fill.symbol
      ~side:fill.aggressor_side
      ~price:fill.price
      ~size:fill.size
  in
  record
    t
    ~participant:fill.resting_participant
    ~symbol:fill.symbol
    ~side:(Side.flip fill.aggressor_side)
    ~price:fill.price
    ~size:fill.size
;;

let apply_trade_report t (event : Exchange_event.t) =
  match event with
  | Trade_report { symbol; price; size = _ } ->
    { t with
      reference_prices = Map.set t.reference_prices ~key:symbol ~data:price
    }
  | Order_accept _ | Fill _ | Order_cancel _ | Order_reject _
  | Best_bid_offer_update _ | Cancel_reject _ ->
    t
;;

module Symbol_summary = struct
  type t =
    { inventory : int
    ; average_entry_price : Price.t option
    ; reference_price : Price.t option
    ; realized_cents : int
    ; unrealized_cents : int
    }
  [@@deriving sexp_of]
end

module Totals = struct
  type t =
    { realized_cents : int
    ; unrealized_cents : int
    }
  [@@deriving sexp_of]

  let total_cents t = t.realized_cents + t.unrealized_cents
end

type summary =
  { per_symbol : (Symbol.t * Symbol_summary.t) list
  ; totals : Totals.t
  }
[@@deriving sexp_of]

let symbol_summary t ~(position : Position.t) ~symbol : Symbol_summary.t =
  let inventory = position.inventory in
  let average_entry_price =
    if inventory = 0
    then None
    else Some (Price.of_int_cents (position.cost_basis_cents / inventory))
  in
  let reference_price = Map.find t.reference_prices symbol in
  let unrealized_cents =
    match reference_price with
    | None -> 0
    | Some reference_price ->
      (inventory * Price.to_int_cents reference_price)
      - position.cost_basis_cents
  in
  { Symbol_summary.inventory
  ; average_entry_price
  ; reference_price
  ; realized_cents = position.realized_cents
  ; unrealized_cents
  }
;;

let summary t participant =
  let symbol_map =
    Map.find t.positions participant
    |> Option.value ~default:Symbol.Map.empty
  in
  let per_symbol =
    Map.to_alist symbol_map
    |> List.map ~f:(fun (symbol, position) ->
      symbol, symbol_summary t ~position ~symbol)
  in
  let totals =
    List.fold
      per_symbol
      ~init:{ Totals.realized_cents = 0; unrealized_cents = 0 }
      ~f:(fun acc (_symbol, summary) ->
        { Totals.realized_cents = acc.realized_cents + summary.realized_cents
        ; unrealized_cents = acc.unrealized_cents + summary.unrealized_cents
        })
  in
  { per_symbol; totals }
;;
