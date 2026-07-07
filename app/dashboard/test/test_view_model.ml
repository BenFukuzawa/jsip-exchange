open! Core
open Jsip_exchange_stats.Exchange_stats
open Jsip_dashboard_protocol
module View_model = Jsip_dashboard_view_model.View_model
module For_testing = View_model.For_testing

(* ---------- formatting helpers ---------- *)

let%expect_test "format_count picks the right magnitude" =
  List.iter [ 0; 42; 999; 1_234; 6_500_000; 1_200_000_000 ] ~f:(fun n ->
    print_endline [%string "%{n#Int} -> %{For_testing.format_count n}"]);
  [%expect
    {|
    0 -> 0
    42 -> 42
    999 -> 999
    1234 -> 1.2K
    6500000 -> 6.5M
    1200000000 -> 1.2B
    |}]
;;

let%expect_test "format_bytes picks the right magnitude" =
  List.iter [ 512.; 49_400.; 52_000_000.; 3_200_000_000. ] ~f:(fun bytes ->
    print_endline [%string "%{For_testing.format_bytes bytes}"]);
  [%expect {|
    512. B
    49.4 KB
    52.0 MB
    3.2 GB
    |}]
;;

let%expect_test "nice_ceil rounds up to 1/2/5 times a power of ten" =
  List.iter [ 0.7; 3.2; 5.0; 750.; 10_001. ] ~f:(fun value ->
    print_endline
      [%string "%{value#Float} -> %{For_testing.nice_ceil value#Float}"]);
  [%expect
    {|
    0.7 -> 1.
    3.2 -> 5.
    5. -> 5.
    750. -> 1000.
    10001. -> 20000.
    |}]
;;

let%expect_test "time_label is the sample's UTC clock time" =
  let time = Time_ns.of_string_with_utc_offset "2026-07-07 12:04:05Z" in
  print_endline (For_testing.time_label time);
  [%expect {| 12:04:05Z |}]
;;

(* ---------- chart plumbing ---------- *)

let%expect_test "x positions pin the newest sample to the right edge" =
  (* A full window spans [0, 1]; a partial one leaves the left empty. *)
  print_s [%sexp (For_testing.x_positions ~window:5 ~count:5 : float list)];
  [%expect {| (0 0.25 0.5 0.75 1) |}];
  print_s [%sexp (For_testing.x_positions ~window:5 ~count:3 : float list)];
  [%expect {| (0.5 0.75 1) |}]
;;

let%expect_test "gaps split a series into separate segments" =
  let point x = Some (x, x) in
  print_s
    [%sexp
      (For_testing.segments_of_points
         [ point 0.1; point 0.2; None; None; point 0.5; None; point 0.7 ]
       : (float * float) list list)];
  [%expect {| (((0.1 0.1) (0.2 0.2)) ((0.5 0.5)) ((0.7 0.7))) |}]
;;

(* ---------- end-to-end view model ---------- *)

let gc ~live_words ~minor_words : Gc_stats.t =
  { live_words
  ; heap_words = 2 * live_words
  ; minor_words
  ; promoted_words = 0.
  ; minor_collections = 10
  ; major_collections = 2
  }
;;

let snapshot ~at_sec ~live_words ~minor_words ~submit_ms ~sessions
  : Snapshot.t
  =
  { sampled_at = Time_ns.add Time_ns.epoch (Time_ns.Span.of_int_sec at_sec)
  ; gc = gc ~live_words ~minor_words
  ; submit_latency =
      Latency_summary.of_samples
        (List.map submit_ms ~f:Time_ns.Span.of_int_ms)
  ; cancel_latency = None
  ; pipe_occupancy = { audit_log = [ 2 ]; market_data = []; sessions }
  }
;;

let response snapshots : Dashboard_protocol.Recent_samples.Response.t =
  { exchange_connection = Connected; snapshots }
;;

let%expect_test "the three empty-ish states are distinguished" =
  print_s [%sexp (View_model.create None : View_model.t)];
  [%expect {| Waiting_for_first_poll |}];
  print_s
    [%sexp
      (View_model.create
         (Some { exchange_connection = Disconnected; snapshots = [] })
       : View_model.t)];
  [%expect {| (No_samples (exchange_connection Disconnected)) |}]
;;

let%expect_test "a live window renders every pane" =
  let harness_alice = Jsip_test_harness.Harness.alice in
  let harness_bob = Jsip_test_harness.Harness.bob in
  let snapshots =
    [ snapshot
        ~at_sec:10
        ~live_words:1_000_000
        ~minor_words:5_000_000.
        ~submit_ms:[ 1; 2; 3; 4 ]
        ~sessions:[ harness_alice, 0; harness_bob, 1_500 ]
    ; snapshot
        ~at_sec:11
        ~live_words:2_000_000
        ~minor_words:8_000_000.
        ~submit_ms:[]
        ~sessions:[ harness_alice, 4; harness_bob, 4_000 ]
    ; snapshot
        ~at_sec:12
        ~live_words:4_000_000
        ~minor_words:12_000_000.
        ~submit_ms:[ 10; 20 ]
        ~sessions:[ harness_alice, 6; harness_bob, 9_000 ]
    ]
  in
  match View_model.create ~window:4 (Some (response snapshots)) with
  | Waiting_for_first_poll
  | No_samples
      { exchange_connection = (_ : Dashboard_protocol.Exchange_connection.t)
      } ->
    print_endline "unexpectedly empty"
  | Showing
      { exchange_connection = (_ : Dashboard_protocol.Exchange_connection.t)
      ; last_sample_label
      ; memory
      ; submit_latency
      ; cancel_latency
      ; occupancy
      } ->
    print_endline [%string "last sample: %{last_sample_label}"];
    print_s [%sexp (memory : View_model.Memory_pane.t)];
    print_s [%sexp (submit_latency : View_model.Latency_pane.t)];
    (* The cancel path saw no traffic: tiles show em-dashes and the chart has
       no segments, but slots still exist for hover. *)
    print_s
      [%message
        ""
          ~cancel_p99:(cancel_latency.p99 : string)
          ~cancel_ops:(cancel_latency.ops_per_sec : string)
          ~cancel_segments:
            (List.map cancel_latency.chart.series ~f:(fun series ->
               List.length series.segments)
             : int list)];
    print_s [%sexp (occupancy : View_model.Occupancy_pane.t)];
    [%expect
      {|
      last sample: 00:00:12Z
      ((chart
        ((series
          (((label "live words")
            (segments
             (((0.33333333333333331 0.2) (0.66666666666666663 0.4) (1 0.8))))
            (label_position ((1 0.8))))))
         (y_ticks ((0 0) (0.5 2.5M) (1 5.0M)))
         (slots
          (((x 0.33333333333333331)
            (tooltip
             ((title 00:00:10Z)
              (lines
               ((LIVE 1.0M) ("LIVE MB" "8.0 MB") ("MINOR GCS" 10) ("MAJOR GCS" 2))))))
           ((x 0.66666666666666663)
            (tooltip
             ((title 00:00:11Z)
              (lines
               ((LIVE 2.0M) ("LIVE MB" "16.0 MB") ("MINOR GCS" 10) ("MAJOR GCS" 2))))))
           ((x 1)
            (tooltip
             ((title 00:00:12Z)
              (lines
               ((LIVE 4.0M) ("LIVE MB" "32.0 MB") ("MINOR GCS" 10) ("MAJOR GCS" 2))))))))
         (x_span ((00:00:10Z 00:00:12Z)))))
       (live_words 4.0M) (live_bytes "32.0 MB") (peak_words 4.0M)
       (usage_fraction 1) (allocation_rate 4.0M) (minor_gcs_per_sec 0)
       (major_gcs_per_sec 0))
      ((chart
        ((series
          (((label p50) (segments (((0.33333333333333331 0.1)) ((1 0.5))))
            (label_position ((1 0.5))))
           ((label p90) (segments (((0.33333333333333331 0.2)) ((1 1))))
            (label_position ((1 1))))
           ((label p99) (segments (((0.33333333333333331 0.2)) ((1 1))))
            (label_position ((1 1))))))
         (y_ticks ((0 0ns) (0.5 10ms) (1 20ms)))
         (slots
          (((x 0.33333333333333331)
            (tooltip
             ((title 00:00:10Z)
              (lines ((p50 2ms) (p90 4ms) (p99 4ms) (max 4ms) (submits 4))))))
           ((x 0.66666666666666663)
            (tooltip ((title 00:00:11Z) (lines ((submits 0))))))
           ((x 1)
            (tooltip
             ((title 00:00:12Z)
              (lines ((p50 10ms) (p90 20ms) (p99 20ms) (max 20ms) (submits 2))))))))
         (x_span ((00:00:10Z 00:00:12Z)))))
       (p50 10ms) (p90 20ms) (p99 20ms) (max 20ms) (ops_per_sec 2))
      ((cancel_p99 "\226\128\148") (cancel_ops 0) (cancel_segments (0 0 0)))
      ((rows
        (((label Bob) (kind SESSION) (length 9000) (length_text 9.0K) (fraction 1)
          (is_hot true))
         ((label Alice) (kind SESSION) (length 6) (length_text 6)
          (fraction 0.00066666666666666664) (is_hot false))
         ((label "audit #1") (kind AUDIT) (length 2) (length_text 2)
          (fraction 0.00022222222222222223) (is_hot false))))
       (hidden_rows 0) (total 9.0K))
      |}]
;;
