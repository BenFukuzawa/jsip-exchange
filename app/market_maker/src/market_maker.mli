(** A dynamic market-making bot.

    A market maker provides liquidity by continuously quoting both a bid and
    an ask around its estimate of fair value, profiting from the spread while
    taking on inventory risk. This bot is {e dynamic}: it reacts to its own
    fills by skewing its quotes against its accumulated inventory, nudging
    the market to trade its position back toward flat.

    It is a [Jsip_bot_runtime.Bot_runtime.Bot], so the scenario runner drives
    it like any other bot: [on_start] seeds the initial ladder, and
    [on_event] re-quotes on every fill. Its fair-value anchor is the live
    fundamental from the runtime's oracle ([Context.fundamental]), so the
    ladder drifts with the simulated true price. *)

open! Core
open! Async
open Jsip_types

module Market_maker_bot : sig
  (** Static configuration. Identity, RNG, oracle, and submit/cancel come
      from the [Context] at runtime, so they are deliberately absent here. *)
  module Config : sig
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

  val name : string

  (** Seed the initial quote ladder. Called once before the tick loop. *)
  val on_start
    :  Config.t
    -> Jsip_bot_runtime.Bot_runtime.Context.t
    -> unit Deferred.t

  (** No periodic work: this bot only re-quotes in reaction to fills. *)
  val on_tick
    :  Config.t
    -> Jsip_bot_runtime.Bot_runtime.Context.t
    -> unit Deferred.t

  (** Track resting orders and inventory from session-feed events, and on
      each [Fill] involving this bot, cancel the outstanding ladder and
      re-post a fresh one skewed by the new inventory. *)
  val on_event
    :  Config.t
    -> Jsip_bot_runtime.Bot_runtime.Context.t
    -> Exchange_event.t
    -> unit Deferred.t
end
