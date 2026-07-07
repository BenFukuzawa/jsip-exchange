(** A bounded rolling window of the most recent exchange-stats snapshots.

    The dashboard server appends every snapshot the exchange streams to it
    and serves the whole window on each [recent-samples] poll; once
    [capacity] snapshots are held, each append drops the oldest. Pure (no
    Async), so the eviction behavior is testable directly. *)

open! Core
open Jsip_exchange_stats

type t

(** [capacity] is the maximum number of snapshots retained; at one snapshot
    per second it is the window length in seconds. Raises if [capacity] is
    not positive. *)
val create_exn : capacity:int -> t

(** Append the newest snapshot; if the history is already at capacity, the
    oldest snapshot is dropped to make room. *)
val add : t -> Exchange_stats.Snapshot.t -> unit

(** Oldest first. *)
val to_list : t -> Exchange_stats.Snapshot.t list
