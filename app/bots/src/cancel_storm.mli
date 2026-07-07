(** A pathological bot: submits an order and immediately cancels it, over
    and over.

    On each [on_tick], [Cancel_storm] runs [Config.cycles_per_tick]
    submit-then-cancel cycles for every configured symbol, keeping up to
    [Config.max_concurrent_cycles] cycles in flight at once. Each cycle
    picks a fresh {!Jsip_types.Client_order_id.t}, submits a resting
    {!Jsip_types.Time_in_force.Day} order priced [Config.passive_offset_cents]
    off the symbol's current fundamental (so it rests rather than fills
    before the cancel lands), then cancels that same order by its client
    order ID. The pressure lands on the cancel path, the
    submit/accept/cancel event flow, and the duplicate-ID bookkeeping from
    Part 2 — every cycle churns a distinct order ID through submit and
    cancel. The bot ignores all incoming events.

    A fresh ID per cycle is essential: reusing one would trip the
    matching engine's duplicate-client-order-id check and every submit
    after the first would be rejected before it could generate any cancel
    traffic. Because cancels run synchronously in the gateway while
    submits queue, a cancel sometimes reaches the engine before its own
    submit has been processed — that is realistic and still exercises the
    cancel path (it produces a [Cancel_reject] instead of an
    [Order_cancel]); the bot does not depend on the cancel succeeding.

    Drive it from the [Cancel_storm] scenario, or spawn it live from the
    dashboard's bot panel. {!Config.t} is per-instance, so a scenario can
    launch several under distinct participants and RNG seeds. It satisfies
    {!Jsip_bot_runtime.Bot_runtime.Bot}. *)

open! Core
open! Async
open Jsip_types
open Jsip_bot_runtime

module Config : sig
  type t =
    { symbols : Symbol.t list
    (** Symbols the storm is spread across; each tick runs
        [cycles_per_tick] submit/cancel cycles for every symbol here. *)
    ; cycles_per_tick : int
    (** Submit-then-cancel cycles, per symbol, per tick. The intensity
        knob: a scenario or the dashboard dials the pathology up or down
        through this (and the tick interval). *)
    ; order_size : int (** Shares per submitted order. *)
    ; passive_offset_cents : int
    (** How far, in cents, each order rests from the current fundamental
        on the passive side — below fair for a [Buy], above for a [Sell].
        Large enough that ordinary drift never lets it cross, so the order
        rests and the cancel has something to cancel. *)
    ; side : Side.t (** Every submitted order is on this side. *)
    ; max_concurrent_cycles : int
    (** Upper bound on cycles in flight at once during a tick. Higher is a
        more aggressive storm; keep it well below
        [cycles_per_tick * List.length symbols] so the client's Async
        scheduler doesn't saturate before the exchange's cancel path
        does. *)
    ; mutable next_client_order_id : int
    (** Internal cursor: the next client order ID to hand out. Set the
        starting value (e.g. [1]) at construction; the bot increments it so
        every cycle uses a distinct ID. *)
    }
  [@@deriving sexp_of]
end

include Bot_runtime.Bot with module Config := Config
