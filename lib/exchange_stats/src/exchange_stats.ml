open! Core
open Jsip_types

module Gc_stats = struct
  type t =
    { live_words : int
    ; heap_words : int
    ; minor_words : float
    ; promoted_words : float
    ; minor_collections : int
    ; major_collections : int
    }
  [@@deriving sexp, bin_io, compare, equal]

  let of_stat (stat : Gc.Stat.t) =
    { live_words = stat.live_words
    ; heap_words = stat.heap_words
    ; minor_words = stat.minor_words
    ; promoted_words = stat.promoted_words
    ; minor_collections = stat.minor_collections
    ; major_collections = stat.major_collections
    }
  ;;
end

module Latency_summary = struct
  type t =
    { count : int
    ; p50 : Time_ns.Span.t
    ; p90 : Time_ns.Span.t
    ; p99 : Time_ns.Span.t
    ; max : Time_ns.Span.t
    }
  [@@deriving sexp, bin_io, compare, equal]

  let of_samples samples =
    match samples with
    | [] -> None
    | _ :: _ ->
      let sorted = Array.of_list samples in
      Array.sort sorted ~compare:Time_ns.Span.compare;
      let count = Array.length sorted in
      (* Nearest rank: the p-th percentile of [count] sorted samples is the
         [ceil (p * count)]-th smallest, 1-indexed. *)
      let percentile p =
        let rank = Float.iround_up_exn (p *. Float.of_int count) in
        sorted.(Int.max 0 (rank - 1))
      in
      Some
        { count
        ; p50 = percentile 0.5
        ; p90 = percentile 0.9
        ; p99 = percentile 0.99
        ; max = sorted.(count - 1)
        }
  ;;
end

module Pipe_occupancy = struct
  type t =
    { audit_log : int list
    ; market_data : (Symbol.t * int list) list
    ; sessions : (Participant.t * int) list
    }
  [@@deriving sexp, bin_io, compare, equal]

  let total t =
    let sum = List.sum (module Int) ~f:Fn.id in
    sum t.audit_log
    + List.sum (module Int) t.market_data ~f:(fun (_symbol, lengths) ->
      sum lengths)
    + List.sum (module Int) t.sessions ~f:snd
  ;;
end

module Snapshot = struct
  type t =
    { sampled_at : Time_ns.t
    ; gc : Gc_stats.t
    ; submit_latency : Latency_summary.t option
    ; cancel_latency : Latency_summary.t option
    ; pipe_occupancy : Pipe_occupancy.t
    }
  [@@deriving sexp, bin_io, compare, equal]
end

module Collector = struct
  type t =
    { mutable submit_samples : Time_ns.Span.t list
    ; mutable cancel_samples : Time_ns.Span.t list
    }

  let create () = { submit_samples = []; cancel_samples = [] }

  let record_submit_latency t span =
    t.submit_samples <- span :: t.submit_samples
  ;;

  let record_cancel_latency t span =
    t.cancel_samples <- span :: t.cancel_samples
  ;;

  let snapshot t ~sampled_at ~gc ~pipe_occupancy : Snapshot.t =
    let submit_latency = Latency_summary.of_samples t.submit_samples in
    let cancel_latency = Latency_summary.of_samples t.cancel_samples in
    t.submit_samples <- [];
    t.cancel_samples <- [];
    { sampled_at; gc; submit_latency; cancel_latency; pipe_occupancy }
  ;;
end
