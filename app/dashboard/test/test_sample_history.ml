open! Core
open Jsip_exchange_stats.Exchange_stats
module Sample_history = Jsip_dashboard_server.Sample_history

(* A minimal snapshot whose identity is readable back out of the history:
   [sampled_at] is [i] seconds past the epoch. *)
let snapshot i : Snapshot.t =
  { sampled_at = Time_ns.add Time_ns.epoch (Time_ns.Span.of_int_sec i)
  ; gc =
      { live_words = 0
      ; heap_words = 0
      ; minor_words = 0.
      ; promoted_words = 0.
      ; minor_collections = 0
      ; major_collections = 0
      }
  ; submit_latency = None
  ; cancel_latency = None
  ; pipe_occupancy = { audit_log = []; market_data = []; sessions = [] }
  }
;;

let print_contents history =
  Sample_history.to_list history
  |> List.map ~f:(fun (snapshot : Snapshot.t) ->
    Time_ns.to_span_since_epoch snapshot.sampled_at
    |> Time_ns.Span.to_int_sec)
  |> [%sexp_of: int list]
  |> print_s
;;

let%expect_test "the window keeps the newest [capacity] snapshots" =
  let history = Sample_history.create_exn ~capacity:3 in
  print_contents history;
  [%expect {| () |}];
  List.iter [ 1; 2; 3 ] ~f:(fun i -> Sample_history.add history (snapshot i));
  print_contents history;
  [%expect {| (1 2 3) |}];
  (* One past capacity: the oldest falls off the front. *)
  Sample_history.add history (snapshot 4);
  print_contents history;
  [%expect {| (2 3 4) |}]
;;

let%expect_test "zero capacity is a caller bug" =
  Expect_test_helpers_core.require_does_raise (fun () ->
    Sample_history.create_exn ~capacity:0);
  [%expect {| ("Sample_history capacity must be positive" (capacity 0)) |}]
;;
