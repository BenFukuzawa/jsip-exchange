(** Runtime-health metrics for the exchange, as a wire type.

    The exchange samples itself once per second — GC state, submit/cancel
    handling latency, subscriber-pipe occupancy — and streams each
    {!Snapshot} to operator tools over
    [Jsip_gateway.Rpc_protocol.exchange_stats_rpc]. The dashboard under
    [app/dashboard] renders these snapshots as live panes.

    This library is deliberately separate from [jsip_gateway]: the browser
    dashboard client is compiled with js_of_ocaml and cannot link the gateway
    (which pulls in Async's Unix bits), but both sides must agree on the
    snapshot's [bin_io] layout. Keeping the type here — with only [core] and
    [jsip_types] as dependencies — lets the server and the browser share it.
    Metrics are intentionally *not* [Jsip_types.Exchange_event.t] variants:
    the audit log records market events, and infrastructure metrics are a
    different layer.

    {!Collector} is the server-side accumulator: RPC handlers record
    per-request latencies into it, and the sampling loop drains it into a
    {!Snapshot} once per second. *)

open! Core
open Jsip_types

module Gc_stats : sig
  (** A trimmed copy of [Core.Gc.Stat.t]. We copy the fields we chart rather
      than putting Core's record on the wire, so the RPC's bin-shape digest
      is pinned by this file and not by the Core version. Word counts are in
      machine words (8 bytes on 64-bit). *)
  type t =
    { live_words : int (** words reachable on the major heap right now *)
    ; heap_words : int (** total size of the major heap *)
    ; minor_words : float
    (** cumulative words allocated on the minor heap since process start; the
        dashboard differentiates successive samples to get an allocation rate *)
    ; promoted_words : float
    (** cumulative words promoted from the minor to the major heap *)
    ; minor_collections : int (** cumulative minor-GC count *)
    ; major_collections : int (** cumulative major-GC cycle count *)
    }
  [@@deriving sexp, bin_io, compare, equal]

  val of_stat : Gc.Stat.t -> t
end

module Latency_summary : sig
  (** Percentiles of one operation's handling latency over a single sampling
      interval, computed by nearest rank: the p90 of [n] sorted samples is
      the [ceil 0.9*n]-th smallest. With one sample, every percentile is that
      sample. *)
  type t =
    { count : int (** samples observed in the interval *)
    ; p50 : Time_ns.Span.t (** median *)
    ; p90 : Time_ns.Span.t (** worst 1-in-10 *)
    ; p99 : Time_ns.Span.t (** worst 1-in-100 *)
    ; max : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io, compare, equal]

  (** [None] when no samples were recorded in the interval. *)
  val of_samples : Time_ns.Span.t list -> t option
end

module Pipe_occupancy : sig
  (** How many events sit unread in each subscriber pipe, at sampling time. A
      well-behaved subscriber's queue hovers near zero; a slow consumer's
      grows without bound (until part-3 section 3a bounds it). Sessions are
      keyed by participant so a dashboard can name the offender. *)
  type t =
    { audit_log : int list (** one queue length per audit subscriber *)
    ; market_data : (Symbol_id.t * int list) list
    (** per symbol, one queue length per subscriber to that symbol. A
        subscriber registered for several symbols is counted under each, so
        summing across symbols over-counts such subscribers. *)
    ; sessions : (Participant.t * int) list
    (** per logged-in participant, that session feed's queue length *)
    }
  [@@deriving sexp, bin_io, compare, equal]

  (** Sum of every queue length above (with the multi-symbol over-counting
      caveat). *)
  val total : t -> int
end

module Snapshot : sig
  (** One per-second sample of everything the dashboard renders. *)
  type t =
    { sampled_at : Time_ns.t
    ; gc : Gc_stats.t
    ; submit_latency : Latency_summary.t option
    (** latency from "submit RPC handler received the order" to "the matching
        engine handled it and its events were dispatched"; [None] when no
        submits completed this interval *)
    ; cancel_latency : Latency_summary.t option
    (** same, for the cancel path (which runs synchronously in the RPC
        handler rather than through the request queue) *)
    ; pipe_occupancy : Pipe_occupancy.t
    }
  [@@deriving sexp, bin_io, compare, equal]
end

module Collector : sig
  (** Mutable accumulator the server records into between snapshots.

      Typical use in the server:

      {[
        let collector = Collector.create () in
        (* on each request: *)
        Collector.record_submit_latency collector elapsed;
        (* once per second: *)
        let snapshot =
          Collector.snapshot
            collector
            ~sampled_at:(Time_ns.now ())
            ~gc:(Gc_stats.of_stat (Gc.stat ()))
            ~pipe_occupancy
        in
        ...
      ]} *)
  type t

  (** A collector with empty accumulators. *)
  val create : unit -> t

  (** Record one submit's receipt-to-handled latency; O(1), called from the
      matching loop. *)
  val record_submit_latency : t -> Time_ns.Span.t -> unit

  (** Record one cancel's handler latency; O(1), called from the cancel RPC
      handler. *)
  val record_cancel_latency : t -> Time_ns.Span.t -> unit

  (** Build the snapshot for the interval that just ended and reset the
      latency accumulators, so each recorded sample is summarized in exactly
      one snapshot. GC state and pipe occupancy are passed in rather than
      read here, keeping this module pure and testable. *)
  val snapshot
    :  t
    -> sampled_at:Time_ns.t
    -> gc:Gc_stats.t
    -> pipe_occupancy:Pipe_occupancy.t
    -> Snapshot.t
end
