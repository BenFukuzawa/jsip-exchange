(** Tests for the dynamic market maker.

    The maker is driven through [Bot_runtime] with recording
    [submit]/[cancel] closures (the pattern from {!Jsip_bots}'s
    [test_bots.ml]), so we can assert the exact ladder it posts and how it
    re-quotes on a fill without standing up a real exchange. *)

open! Core
open! Async
open Jsip_types
open Jsip_fundamental
open Jsip_bot_runtime
open Jsip_market_maker
open Jsip_test_harness

(* A flat fundamental: zero volatility and zero mean-reversion pin the oracle
   at [initial_price_cents], so the ladder prices are fully determined by the
   maker's own arithmetic. *)
let oracle_config ~initial_price_cents =
  Symbol.Map.of_alist_exn
    [ ( Harness.aapl
      , { Fundamental_oracle.Config.initial_price_cents
        ; volatility_cents_per_sec = 0.0
        ; mean_reversion_strength = 0.0
        ; tick_interval = Time_ns.Span.of_sec 1.0
        } )
    ]
;;

let make_bot
  (config : Market_maker.Market_maker_bot.Config.t)
  ~initial_price_cents
  =
  let submitted = ref [] in
  let cancelled = ref [] in
  let submit request =
    submitted := request :: !submitted;
    return (Ok ())
  in
  let cancel client_order_id =
    cancelled := client_order_id :: !cancelled;
    return (Ok ())
  in
  let oracle =
    Fundamental_oracle.create (oracle_config ~initial_price_cents) ~seed:42
  in
  let bot =
    Bot_runtime.create
      (module Market_maker.Market_maker_bot)
      config
      ~participant:Harness.alice
      ~oracle
      ~rng:(Splittable_random.of_int 7)
      ~submit
      ~cancel
      ~tick_interval:(Time_ns.Span.of_sec 1.0)
  in
  bot, submitted, cancelled
;;

(* The maker posts levels in parallel, so submission order isn't stable. Sort
   by (side, price) to get a deterministic view of the ladder. *)
let print_ladder (submitted : Order.Request.t list ref) =
  !submitted
  |> List.sort ~compare:(fun (a : Order.Request.t) (b : Order.Request.t) ->
    [%compare: Side.t * int]
      (a.side, Price.to_int_cents a.price)
      (b.side, Price.to_int_cents b.price))
  |> List.iter ~f:(fun (req : Order.Request.t) ->
    printf
      !"%{Side} %d@%{Price#dollar}\n"
      req.side
      (Size.to_int req.size)
      req.price)
;;

let print_cancels (cancelled : Client_order_id.t list ref) =
  let ids =
    List.map !cancelled ~f:Client_order_id.to_int
    |> List.sort ~compare:Int.compare
  in
  print_s [%sexp (ids : int list)]
;;

let%expect_test "seeds a symmetric ladder, then re-quotes skewed after a \
                 fill"
  =
  let config : Market_maker.Market_maker_bot.Config.t =
    { symbol = Harness.aapl
    ; symbol_id = Harness.aapl_id
    ; half_spread_cents = 10
    ; size_per_level = 100
    ; num_levels = 3
    ; inventory_skew_cents_per_share = 1
    }
  in
  let bot, submitted, cancelled =
    make_bot config ~initial_price_cents:15000
  in
  let ctx = Bot_runtime.For_testing.context_of bot in
  (* Phase 1: [on_start] seeds the ladder. Inventory is zero, so the skew is
     zero and the ladder sits symmetrically around the 15000 fundamental:
     half-spread of 10c, stepping one cent further out per level. *)
  let%bind () = Market_maker.Market_maker_bot.on_start config ctx in
  print_ladder submitted;
  [%expect
    {|
    BUY 100@$149.88
    BUY 100@$149.89
    BUY 100@$149.90
    SELL 100@$150.10
    SELL 100@$150.11
    SELL 100@$150.12
    |}];
  (* Tell the maker its whole ladder rested, so it has something to cancel. *)
  let%bind () =
    Deferred.List.iteri
      ~how:`Sequential
      !submitted
      ~f:(fun i (request : Order.Request.t) ->
        Bot_runtime.feed_event
          bot
          (Order_accept { order_id = Order_id.For_testing.of_int i; request }))
  in
  submitted := [];
  cancelled := [];
  (* Phase 2: a counterparty (Bob) sells into one of the maker's resting bids
     (client id 1). The maker is the *resting* party, so it buys 100 shares
     and goes long. Two things must happen: the filled order (1) is removed
     from the resting set by the fill itself, so it is *not* among the
     subsequent cancels (cancels are 2..6, not 1..6); and the re-quoted
     ladder is shifted down by inventory * inventory_skew_cents_per_share =
     100 * 1 = 100c. *)
  let fill : Fill.t =
    { fill_id = 1
    ; symbol = Harness.aapl_id
    ; price = Price.of_int_cents 15000
    ; size = Size.of_int 100
    ; aggressor_order_id = Order_id.For_testing.of_int 100
    ; aggressor_client_order_id = Client_order_id.of_int 1000
    ; aggressor_participant = Harness.bob
    ; aggressor_side = Sell
    ; resting_order_id = Order_id.For_testing.of_int 101
    ; resting_client_order_id = Client_order_id.of_int 1
    ; resting_participant = Harness.alice
    }
  in
  let%bind () = Bot_runtime.feed_event bot (Fill fill) in
  print_string "cancelled: ";
  print_cancels cancelled;
  print_ladder submitted;
  [%expect
    {|
    cancelled: (2 3 4 5 6)
    BUY 100@$148.88
    BUY 100@$148.89
    BUY 100@$148.90
    SELL 100@$149.10
    SELL 100@$149.11
    SELL 100@$149.12
    |}];
  return ()
;;
