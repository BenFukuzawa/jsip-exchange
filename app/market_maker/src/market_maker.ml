open! Core
open! Async
open Jsip_types

module Market_maker_bot = struct
  module Context = Jsip_bot_runtime.Bot_runtime.Context

  module Config = struct
    type t =
      { symbol : Symbol.t
      (** The symbol name, used to read the (name-keyed) fundamental oracle. *)
      ; symbol_id : Symbol_id.t
      (** The wire id of the same symbol, used on orders and to key
          inventory. Must identify the same instrument as [symbol]. *)
      ; half_spread_cents : int
      (** Half-spread in cents around the (skewed) fair value. *)
      ; size_per_level : int (** Shares posted at each price level. *)
      ; num_levels : int (** Number of levels quoted on each side. *)
      ; inventory_skew_cents_per_share : int
      (** How far to shift the ladder per share of inventory. When long,
          [skewed_fair = fair - inventory * this] pulls both quotes down. *)
      }
    [@@deriving sexp_of]
  end

  let name = "market_maker"

  (* Per-run mutable state, keyed by symbol. It lives here rather than being
     threaded through the callbacks because the [Bot] interface hands each
     callback only a [Config] and a [Context] — there is nowhere to pass a
     state value. The consequence is one market-maker instance per process,
     which is all our scenarios need. *)
  module State = struct
    type t =
      { inventory : int Symbol_id.Table.t
      ; resting_orders : Client_order_id.Hash_set.t
      ; mutable next_client_id : int
      }

    let create () =
      { inventory = Symbol_id.Table.create ()
      ; resting_orders = Hash_set.create (module Client_order_id)
      ; next_client_id = 0
      }
    ;;
  end

  let state = State.create ()

  (* A fresh, never-reused client order id. The exchange rejects duplicate
     ids per participant, so the counter must only ever move forward. *)
  let fresh_client_id () =
    state.next_client_id <- state.next_client_id + 1;
    Client_order_id.of_int state.next_client_id
  ;;

  let inventory symbol =
    Hashtbl.find state.inventory symbol |> Option.value ~default:0
  ;;

  (* Compute the (buy, sell) price in cents for one ladder [level] (0-based),
     given the live fundamental and current inventory. Pure: it reads the
     context and inventory but submits nothing.

     The base is the oracle's fundamental for the symbol, skewed against
     inventory so the maker leans toward flattening its position, then
     widened symmetrically by the half-spread plus one cent per level out. *)
  let level_prices (config : Config.t) ctx ~level =
    let fair_price =
      Price.to_int_cents (Context.fundamental ctx config.symbol)
    in
    let inv = inventory config.symbol_id in
    let skewed_fair =
      fair_price - (inv * config.inventory_skew_cents_per_share)
    in
    let buy = skewed_fair - config.half_spread_cents - level in
    let sell = skewed_fair + config.half_spread_cents + level in
    buy, sell
  ;;

  (* Post a fresh ladder: [num_levels] bids and asks around the skewed fair
     value. Submissions are one-way; the accepts/fills come back on the
     session feed and land in [on_event]. *)
  let post_ladder (config : Config.t) ctx =
    Deferred.List.iter
      ~how:`Parallel
      (List.init config.num_levels ~f:Fn.id)
      ~f:(fun level ->
        let buy_cents, sell_cents = level_prices config ctx ~level in
        let submit side price_cents =
          let request : Order.Request.t =
            { client_order_id = fresh_client_id ()
            ; symbol = config.symbol_id
            ; participant = Context.participant ctx
            ; side
            ; price = Price.of_int_cents price_cents
            ; size = Size.of_int config.size_per_level
            ; time_in_force = Day
            }
          in
          let%map (_ : unit Or_error.t) = Context.submit ctx request in
          ()
        in
        let%bind () = submit Buy buy_cents in
        submit Sell sell_cents)
  ;;

  (* Cancel every order we currently believe is resting. A cancel that races
     with a fill comes back as "order not found" and is harmless. *)
  let cancel_all_resting ctx =
    Deferred.List.iter
      ~how:`Parallel
      (Hash_set.to_list state.resting_orders)
      ~f:(fun id ->
        let%map (_ : unit Or_error.t) = Context.cancel ctx id in
        ())
  ;;

  let on_start config ctx = post_ladder config ctx
  let on_tick _config _ctx = return ()

  let on_event (config : Config.t) ctx (event : Exchange_event.t) =
    match event with
    | Order_accept { request; _ } ->
      Hash_set.add state.resting_orders request.client_order_id;
      return ()
    | Order_cancel { client_order_id; _ } ->
      Hash_set.remove state.resting_orders client_order_id;
      return ()
    | Fill fill ->
      let me = Context.participant ctx in
      let is_aggressor = Participant.equal me fill.aggressor_participant in
      let is_resting = Participant.equal me fill.resting_participant in
      (match is_aggressor || is_resting with
       | false -> return ()
       | true ->
         let our_side, our_client_id =
           if is_aggressor
           then fill.aggressor_side, fill.aggressor_client_order_id
           else Side.flip fill.aggressor_side, fill.resting_client_order_id
         in
         let signed_size =
           match our_side with
           | Buy -> Size.to_int fill.size
           | Sell -> -Size.to_int fill.size
         in
         Hashtbl.update state.inventory fill.symbol ~f:(fun current ->
           Option.value current ~default:0 + signed_size);
         Hash_set.remove state.resting_orders our_client_id;
         (* Re-quote: drop the stale ladder and post a fresh, skewed one. *)
         let%bind () = cancel_all_resting ctx in
         post_ladder config ctx)
    | Order_reject _ | Cancel_reject _ | Best_bid_offer_update _
    | Trade_report _ ->
      return ()
  ;;
end
