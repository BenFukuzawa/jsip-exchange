open! Core
open Jsip_exchange_stats.Exchange_stats
module Harness = Jsip_test_harness.Harness

let span_ms ms = Time_ns.Span.of_int_ms ms

let print_summary summary =
  print_s [%sexp (summary : Latency_summary.t option)]
;;

let%expect_test "percentiles of 1..100ms land on the expected ranks" =
  (* With samples 1ms..100ms, nearest-rank percentiles are directly readable:
     p50 = 50ms, p90 = 90ms, p99 = 99ms, max = 100ms. Shuffled input
     demonstrates [of_samples] sorts. *)
  let samples = List.init 100 ~f:(fun i -> span_ms (100 - i)) in
  print_summary (Latency_summary.of_samples samples);
  [%expect
    {| (((count 100) (p50 50ms) (p90 90ms) (p99 99ms) (max 100ms))) |}]
;;

let%expect_test "no samples means no summary" =
  print_summary (Latency_summary.of_samples []);
  [%expect {| () |}]
;;

let%expect_test "a single sample is every percentile" =
  print_summary (Latency_summary.of_samples [ span_ms 7 ]);
  [%expect {| (((count 1) (p50 7ms) (p90 7ms) (p99 7ms) (max 7ms))) |}]
;;

let%expect_test "two samples: p50 is the lower one (nearest rank)" =
  print_summary (Latency_summary.of_samples [ span_ms 10; span_ms 2 ]);
  [%expect {| (((count 2) (p50 2ms) (p90 10ms) (p99 10ms) (max 10ms))) |}]
;;

let%expect_test "pipe-occupancy total sums every family" =
  let occupancy =
    { Pipe_occupancy.audit_log = [ 3; 0 ]
    ; market_data = [ Harness.aapl_id, [ 5; 2 ]; Harness.tsla_id, [ 1 ] ]
    ; sessions = [ Harness.alice, 4; Harness.bob, 0 ]
    }
  in
  print_s [%sexp (Pipe_occupancy.total occupancy : int)];
  [%expect {| 15 |}]
;;

let%expect_test "collector drains its samples into exactly one snapshot" =
  let collector = Collector.create () in
  Collector.record_submit_latency collector (span_ms 4);
  Collector.record_submit_latency collector (span_ms 2);
  Collector.record_cancel_latency collector (span_ms 1);
  let gc : Gc_stats.t =
    { live_words = 50_000
    ; heap_words = 120_000
    ; minor_words = 1_000_000.
    ; promoted_words = 40_000.
    ; minor_collections = 12
    ; major_collections = 3
    }
  in
  let pipe_occupancy =
    { Pipe_occupancy.audit_log = []; market_data = []; sessions = [] }
  in
  let sampled_at =
    Time_ns.of_string_with_utc_offset "2026-07-07 12:00:00Z"
  in
  let take () =
    Collector.snapshot collector ~sampled_at ~gc ~pipe_occupancy
  in
  print_s [%sexp (take () : Snapshot.t)];
  [%expect
    {|
    ((sampled_at (2026-07-07 12:00:00.000000000Z))
     (gc
      ((live_words 50000) (heap_words 120000) (minor_words 1000000)
       (promoted_words 40000) (minor_collections 12) (major_collections 3)))
     (submit_latency (((count 2) (p50 2ms) (p90 4ms) (p99 4ms) (max 4ms))))
     (cancel_latency (((count 1) (p50 1ms) (p90 1ms) (p99 1ms) (max 1ms))))
     (pipe_occupancy ((audit_log ()) (market_data ()) (sessions ()))))
    |}];
  (* A second snapshot sees an empty interval: the first one drained. *)
  let second = take () in
  print_s
    [%message
      ""
        (second.submit_latency : Latency_summary.t option)
        (second.cancel_latency : Latency_summary.t option)];
  [%expect {| ((second.submit_latency ()) (second.cancel_latency ())) |}]
;;
