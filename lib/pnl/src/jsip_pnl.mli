(** Per-participant, per-symbol profit-and-loss tracking.

    A [Pnl.t] accumulates trading activity and answers, for any participant:
    what is my position in each symbol, what did I pay for it on average, how
    much cash have I locked in from closed trades ("realized"), and how much
    would I gain or lose if I closed everything now at the last trade price
    ("unrealized")?

    We use {b average-cost} accounting: opening a position or adding to it in
    the same direction blends into a running average entry price; reducing or
    closing a position realizes P&L against that average. Reversing through
    zero (e.g. selling 150 shares out of a 100-share long) closes the old
    position and opens a fresh one in the other direction.

    Feed it the events the matching engine produces:
    - {!apply_fill} for each {!Jsip_types.Fill.t}. A fill has two
      counterparties — the aggressor and the resting order — on opposite
      sides, so both participants' positions are updated.
    - {!apply_trade_report} for each public trade print, which refreshes the
      reference (mark) price used for unrealized P&L.

    {2 Example}
    {[
      let pnl =
        Pnl.empty
        |> Fn.flip Pnl.apply_fill fill
        |> Fn.flip Pnl.apply_trade_report trade_print
      in
      let { per_symbol; totals } = Pnl.summary pnl alice in
      ...
    ]} *)

open! Core
open Jsip_types

type t [@@deriving sexp_of]

(** A [Pnl.t] with no positions and no reference prices. *)
val empty : t

(** Record a fill, updating both the aggressor's and the resting party's
    positions (they trade on opposite sides). *)
val apply_fill : t -> Fill.t -> t

(** Refresh the reference (mark) price for a symbol from a public trade
    print. Only an [Exchange_event.Trade_report] has any effect; every other
    event returns [t] unchanged, so a caller can pipe a whole event stream
    through this function.

    Note: the project has no standalone [Trade_report.t] — a trade report is
    the {!Jsip_types.Exchange_event.Trade_report} variant — so this takes an
    [Exchange_event.t]. *)
val apply_trade_report : t -> Exchange_event.t -> t

(** {2 Summaries} *)

module Symbol_summary : sig
  (** One symbol's P&L for one participant. All cash figures are in integer
      cents, matching {!Jsip_types.Price}. *)
  type t =
    { inventory : int
    (** Signed share position: positive is long, negative is short. *)
    ; average_entry_price : Price.t option
    (** Average price paid/received for the open position, or [None] when
        flat. *)
    ; reference_price : Price.t option
    (** Last trade print seen for this symbol, if any. *)
    ; realized_cents : int (** Cash locked in from closed trades. *)
    ; unrealized_cents : int
    (** Mark-to-market on the open position at [reference_price]:
        [inventory * (reference_price - average_entry_price)]. [0] when flat
        or when no reference price is known yet. *)
    }
  [@@deriving sexp_of]
end

module Totals : sig
  (** A participant's P&L summed across every symbol. *)
  type t =
    { realized_cents : int
    ; unrealized_cents : int
    }
  [@@deriving sexp_of]

  (** [realized_cents + unrealized_cents]. *)
  val total_cents : t -> int
end

type summary =
  { per_symbol : (Symbol.t * Symbol_summary.t) list
  (** One entry per symbol the participant has traded, in symbol order. *)
  ; totals : Totals.t (** Summed across all symbols. *)
  }
[@@deriving sexp_of]

(** The per-symbol breakdown and totals for one participant. A participant
    with no recorded activity yields an empty breakdown and zero totals. *)
val summary : t -> Participant.t -> summary
