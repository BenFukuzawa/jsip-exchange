(** Tests for the market maker, using a real exchange server. *)

open! Core
open! Async
open Jsip_test_harness
open Jsip_market_maker
open E2e_helpers
open Jsip_gateway
open Jsip_types

let default_config : Market_maker.Config.t =
  { participant = Harness.market_maker
  ; symbol = Harness.aapl
  ; fair_value_cents = 15000
  ; half_spread_cents = 10
  ; size_per_level = 100
  ; num_levels = 3
  }
;;

let%expect_test "seed_book: places symmetric bids and asks around fair value"
  =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind mm = connect_as ~port Harness.market_maker2 in
    let%bind () = Market_maker.seed_book default_config (connection mm) in
    [%expect
      {|
      [for MarketMaker2] ACCEPTED id=1 AAPL BUY 100@$149.90 DAY
      [for MarketMaker2] REJECTED AAPL SELL 100@$150.10 reason=duplicate client order id
      [for MarketMaker2] REJECTED AAPL BUY 100@$149.89 reason=duplicate client order id
      [for MarketMaker2] REJECTED AAPL SELL 100@$150.11 reason=duplicate client order id
      [for MarketMaker2] REJECTED AAPL BUY 100@$149.88 reason=duplicate client order id
      [for MarketMaker2] REJECTED AAPL SELL 100@$150.12 reason=duplicate client order id
      |}];
    return ())
;;

let%expect_test "long running market maker: pushes a small sequence of \n\
                \                 events into the market maker's event \
                 handler and asserts \n\
                \                 that the resulting inventory and \
                 outstanding-orders state \n\
                \                 match what you expect."
  =
  with_server ~symbols:[ Harness.aapl ] (fun ~server:_ ~port ->
    let%bind mm = connect_as ~port Harness.market_maker2 in
    don't_wait_for (Market_maker.run default_config (connection mm));
    let%bind () = Clock_ns.after (Time_ns.Span.of_ms 10.) in
    let%bind trader = connect_as ~port Harness.trader in
    let request = Harness.buy ~price_cents:15000 () in
    let%bind (_ : _) =
      Rpc.Rpc.dispatch_exn
        Rpc_protocol.submit_order_rpc
        (connection trader)
        request
    in
    let%bind () = Clock_ns.after (Time_ns.Span.of_ms 10.) in
    [%expect {| [for Trader] ACCEPTED id=2 AAPL BUY 100@$150.00 DAY |}];
    return ())
;;

let%expect_test "Confirm state changed post fill" =
  let participant = Harness.market_maker in
  let symbol = Harness.aapl in
  let state = Market_maker.State.create participant in
  let fake_accept = Exchange_event.Order_accept { order_id = _; request } in
  Market_maker.handle_event state fake_accept;
  (* 3. Assert the state of the resting orders *)
  print_s
    [%sexp (Hash_set.to_list state.resting_orders : Client_order_id.t list)];
  [%expect {| (1) |}];
  (* 4. Push a Fill event *)
  let fake_fill =
    Exchange_event.Fill
      { fill_id = _
      ; symbol = _
      ; price = _
      ; size = _
      ; aggressor_order_id = _
      ; aggressor_participant
      ; aggressor_side = _
      ; resting_order_id = _
      ; resting_participant
      ; aggressor_client_order_id = _
      ; resting_client_order_id = _
      }
  in
  Market_maker.handle_event state fake_fill;
  (* 5. Assert the inventory changed! *)
  print_s [%sexp (Hashtbl.to_alist state.inventory : (Symbol.t * int) list)];
  [%expect {| ((AAPL 100)) |}];
  return ()
;;

(* let%expect_test "Cancel and re-quote on every fill" = with_server
   ~symbols:[ Harness.aapl ] (fun ~server:_ ~port -> let%bind mm = connect_as
   ~port Harness.market_maker2 in don't_wait_for (Market_maker.run
   default_config (connection mm)); let%bind () = Clock_ns.after
   (Time_ns.Span.of_ms 10.) in

   let%bind trader = connect_as ~port Harness.trader in let request =
   Harness.buy ~price_cents:15000 () in let%bind (_ : _) =
   Rpc.Rpc.dispatch_exn Rpc_protocol.submit_order_rpc (connection trader)
   request in let%bind () = Clock_ns.after (Time_ns.Span.of_ms 10.) in
   [%expect {| [for Trader] ACCEPTED id=2 AAPL BUY 100@$150.00 DAY |}];
   return ()) ;; *)
