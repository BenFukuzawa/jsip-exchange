open! Core
open Jsip_types
module H = Jsip_test_harness.Harness

(* A hand-built fill. The matching engine assigns real ids; for P&L only the
   participants, side, price, and size matter, so the ids are arbitrary. *)
let make_fill ~aggressor ~aggressor_side ~resting ~symbol ~price_cents ~size =
  { Fill.fill_id = 0
  ; symbol
  ; price = Price.of_int_cents price_cents
  ; size = Size.of_int size
  ; aggressor_order_id = Order_id.of_string "1"
  ; aggressor_participant = aggressor
  ; aggressor_side
  ; resting_order_id = Order_id.of_string "2"
  ; resting_participant = resting
  ; aggressor_client_order_id = Client_order_id.of_int 0
  ; resting_client_order_id = Client_order_id.of_int 1
  }
;;

let trade_print ~symbol ~price_cents =
  Exchange_event.Trade_report
    { symbol; price = Price.of_int_cents price_cents; size = Size.of_int 0 }
;;

let show_symbol (symbol, (s : Jsip_pnl.Symbol_summary.t)) =
  let price = function None -> "-" | Some p -> Price.to_string_dollar p in
  printf
    "  %s  inv=%d avg=%s ref=%s realized=%dc unrealized=%dc\n"
    (Symbol_id.to_string symbol)
    s.inventory
    (price s.average_entry_price)
    (price s.reference_price)
    s.realized_cents
    s.unrealized_cents
;;

let show pnl participant =
  let { Jsip_pnl.per_symbol; totals } = Jsip_pnl.summary pnl participant in
  printf "%s:\n" (Participant.to_string participant);
  List.iter per_symbol ~f:show_symbol;
  printf
    "  total realized=%dc unrealized=%dc net=%dc\n"
    totals.realized_cents
    totals.unrealized_cents
    (Jsip_pnl.Totals.total_cents totals)
;;

(* Alice buys 100 AAPL @ $150 from Bob, then the tape prints $151. Both sides
   of the one fill are booked: Alice is long, Bob is short. No position is
   closed, so this test does not exercise the realized-P&L path. *)
let%expect_test "opening fill + trade print marks both sides" =
  let pnl =
    Jsip_pnl.empty
    |> fun p ->
    Jsip_pnl.apply_fill
      p
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Buy
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15000
         ~size:100)
  in
  let pnl =
    Jsip_pnl.apply_trade_report
      pnl
      (trade_print ~symbol:H.aapl_id ~price_cents:15100)
  in
  show pnl H.alice;
  show pnl H.bob;
  [%expect
    {|
    Alice:
      0  inv=100 avg=$150.00 ref=$151.00 realized=0c unrealized=10000c
      total realized=0c unrealized=10000c net=10000c
    Bob:
      0  inv=-100 avg=$150.00 ref=$151.00 realized=0c unrealized=-10000c
      total realized=0c unrealized=-10000c net=-10000c
    |}]
;;

(* Alice buys 100 @ $150, then sells 60 @ $152, closing part of the long.
   Closing 60 shares bought at $150 and sold at $152 realizes 60 * $2 = $120
   = 12000c for Alice, and the mirror -12000c for Bob. The tape then prints
   $152, marking the 40 shares still open. *)
let%expect_test "partial close realizes P&L" =
  let pnl =
    Jsip_pnl.empty
    |> fun p ->
    Jsip_pnl.apply_fill
      p
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Buy
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15000
         ~size:100)
  in
  let pnl =
    Jsip_pnl.apply_fill
      pnl
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Sell
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15200
         ~size:60)
  in
  let pnl =
    Jsip_pnl.apply_trade_report
      pnl
      (trade_print ~symbol:H.aapl_id ~price_cents:15200)
  in
  show pnl H.alice;
  show pnl H.bob;
  [%expect
    {|
    Alice:
      0  inv=40 avg=$150.00 ref=$152.00 realized=12000c unrealized=8000c
      total realized=12000c unrealized=8000c net=20000c
    Bob:
      0  inv=-40 avg=$150.00 ref=$152.00 realized=-12000c unrealized=-8000c
      total realized=-12000c unrealized=-8000c net=-20000c
    |}]
;;

(* Alice is long 40 @ $150, then sells 60 @ $153. That closes all 40 long
   shares (realizing 40 * $3 = $120 = 12000c on top of the earlier 12000c)
   and opens a fresh 20-share short at $153. The tape prints $153, so the
   brand-new short is flat to the mark. *)
let%expect_test "selling through zero flips the position" =
  let pnl =
    Jsip_pnl.empty
    |> fun p ->
    Jsip_pnl.apply_fill
      p
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Buy
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15000
         ~size:100)
  in
  let pnl =
    Jsip_pnl.apply_fill
      pnl
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Sell
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15200
         ~size:60)
  in
  let pnl =
    Jsip_pnl.apply_fill
      pnl
      (make_fill
         ~aggressor:H.alice
         ~aggressor_side:Side.Sell
         ~resting:H.bob
         ~symbol:H.aapl_id
         ~price_cents:15300
         ~size:60)
  in
  let pnl =
    Jsip_pnl.apply_trade_report
      pnl
      (trade_print ~symbol:H.aapl_id ~price_cents:15300)
  in
  show pnl H.alice;
  [%expect
    {|
    Alice:
      0  inv=-20 avg=$153.00 ref=$153.00 realized=24000c unrealized=0c
      total realized=24000c unrealized=0c net=24000c
    |}]
;;
