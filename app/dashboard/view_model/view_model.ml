open! Core
open Jsip_types
open Jsip_exchange_stats
open Jsip_dashboard_protocol

let default_window = 60
let poll_interval = Time_ns.Span.second
let hot_queue_threshold = 1_000

(* Enough rows to show every scenario bot at once without letting a spammy
   symbol list push the panel off screen. *)
let occupancy_rows_limit = 12
let bytes_per_word = 8.

(* ---------- formatting ---------- *)

let one_decimal value =
  Float.to_string_hum value ~decimals:1 ~strip_zero:false
;;

let format_count count =
  let magnitude = Float.of_int (abs count) in
  let scaled divisor suffix =
    [%string "%{one_decimal (Float.of_int count /. divisor)}%{suffix}"]
  in
  if Float.( >= ) magnitude 1e9
  then scaled 1e9 "B"
  else if Float.( >= ) magnitude 1e6
  then scaled 1e6 "M"
  else if Float.( >= ) magnitude 1e3
  then scaled 1e3 "K"
  else Int.to_string count
;;

let format_bytes bytes =
  let scaled divisor suffix =
    [%string "%{one_decimal (bytes /. divisor)} %{suffix}"]
  in
  if Float.( >= ) bytes 1e9
  then scaled 1e9 "GB"
  else if Float.( >= ) bytes 1e6
  then scaled 1e6 "MB"
  else if Float.( >= ) bytes 1e3
  then scaled 1e3 "KB"
  else [%string "%{bytes#Float} B"]
;;

let format_span span = Time_ns.Span.to_string_hum span ~decimals:1
let format_span_ns ns = format_span (Time_ns.Span.of_ns ns)

(* "12:04:05Z" — sliced out of [Time_ns.to_string_utc]'s "2026-07-07
   12:04:05.123456789Z" so we don't depend on a local timezone database
   inside the browser. *)
let time_label time =
  let full = Time_ns.to_string_utc time in
  match String.lsplit2 full ~on:' ' with
  | None -> full
  | Some ((_ : string), time_part) -> String.prefix time_part 8 ^ "Z"
;;

(* Smallest "round" number (1, 2, or 5 times a power of ten) at or above
   [value], used as the y-axis top so gridline labels stay readable. *)
let nice_ceil value =
  let base = 10. **. Float.round_down (Float.log10 value) in
  List.find
    [ base; 2. *. base; 5. *. base; 10. *. base ]
    ~f:(fun candidate -> Float.( >= ) candidate value)
  |> Option.value ~default:value
;;

(* ---------- chart plumbing ---------- *)

module Trend_chart = struct
  module Tooltip = struct
    type t =
      { title : string
      ; lines : (string * string) list
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Sample_slot = struct
    type t =
      { x : float
      ; tooltip : Tooltip.t
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Series = struct
    type t =
      { label : string
      ; segments : (float * float) list list
      ; label_position : (float * float) option
      }
    [@@deriving sexp_of, compare, equal]
  end

  type t =
    { series : Series.t list
    ; y_ticks : (float * string) list
    ; slots : Sample_slot.t list
    ; x_span : (string * string) option
    }
  [@@deriving sexp_of, compare, equal]
end

(* Newest sample pinned to the right edge; a window that isn't full yet
   leaves empty space on the left, so a freshly started exchange reads as
   "history still accumulating" rather than a stretched line. Positions are
   clamped to [0, 1] in case [count] exceeds [window]. *)
let x_positions ~window ~count =
  match window <= 1 with
  | true -> List.init count ~f:(fun (_ : int) -> 1.)
  | false ->
    let denominator = Float.of_int (window - 1) in
    List.init count ~f:(fun i ->
      Float.max 0. (Float.of_int (window - count + i) /. denominator))
;;

(* Split per-sample optional values into contiguous runs of present points:
   each run renders as one polyline, each [None] as a gap. *)
let segments_of_points points =
  let finish acc segment =
    match segment with [] -> acc | _ :: _ -> List.rev segment :: acc
  in
  let acc, last_segment =
    List.fold points ~init:([], []) ~f:(fun (acc, segment) point ->
      match point with
      | None -> finish acc segment, []
      | Some point -> acc, point :: segment)
  in
  List.rev (finish acc last_segment)
;;

(* [series_values]: per series, one optional y value per snapshot (same
   length as [snapshots]). *)
let build_chart ~window ~snapshots ~series_values ~format_y ~tooltip =
  let count = List.length snapshots in
  let xs = x_positions ~window ~count in
  let y_max =
    List.concat_map series_values ~f:(fun ((_ : string), values) ->
      List.filter_opt values)
    |> List.max_elt ~compare:Float.compare
    |> Option.filter ~f:(fun m -> Float.( > ) m 0.)
    |> Option.value_map ~default:1. ~f:nice_ceil
  in
  let series =
    List.map series_values ~f:(fun (label, values) ->
      let points =
        List.map2_exn xs values ~f:(fun x value ->
          Option.map value ~f:(fun value -> x, value /. y_max))
      in
      let label_position =
        List.fold points ~init:None ~f:(fun newest point ->
          Option.first_some point newest)
      in
      { Trend_chart.Series.label
      ; segments = segments_of_points points
      ; label_position
      })
  in
  let y_ticks =
    [ 0., format_y 0.; 0.5, format_y (y_max /. 2.); 1., format_y y_max ]
  in
  let slots =
    List.map2_exn xs snapshots ~f:(fun x snapshot ->
      { Trend_chart.Sample_slot.x; tooltip = tooltip snapshot })
  in
  let x_span =
    match snapshots with
    | [] | [ _ ] -> None
    | oldest :: (_ :: _ as rest) ->
      let newest = List.last_exn rest in
      Some
        ( time_label oldest.Exchange_stats.Snapshot.sampled_at
        , time_label newest.Exchange_stats.Snapshot.sampled_at )
  in
  { Trend_chart.series; y_ticks; slots; x_span }
;;

(* ---------- panes ---------- *)

module Memory_pane = struct
  type t =
    { chart : Trend_chart.t
    ; live_words : string
    ; live_bytes : string
    ; peak_words : string (** largest live_words seen in the window *)
    ; usage_fraction : float
    (** current live_words as a fraction of [peak_words], for the
        htop-style fill meter; in [0, 1] *)
    ; allocation_rate : string
    ; minor_gcs_per_sec : string
    ; major_gcs_per_sec : string
    }
  [@@deriving sexp_of, compare, equal]
end

(* Change per second between the two newest samples of some cumulative
   counter; [None] until there are two samples. *)
let rate_per_sec ~newest ~previous ~counter =
  Option.bind previous ~f:(fun previous ->
    let dt =
      Time_ns.diff
        newest.Exchange_stats.Snapshot.sampled_at
        previous.Exchange_stats.Snapshot.sampled_at
      |> Time_ns.Span.to_sec
    in
    match Float.( > ) dt 0. with
    | false -> None
    | true -> Some ((counter newest -. counter previous) /. dt))
;;

let words_tooltip (snapshot : Exchange_stats.Snapshot.t) =
  { Trend_chart.Tooltip.title = time_label snapshot.sampled_at
  ; lines =
      [ "LIVE", format_count snapshot.gc.live_words
      ; ( "LIVE MB"
        , format_bytes (Float.of_int snapshot.gc.live_words *. bytes_per_word)
        )
      ; "MINOR GCS", format_count snapshot.gc.minor_collections
      ; "MAJOR GCS", format_count snapshot.gc.major_collections
      ]
  }
;;

let memory_pane ~window snapshots ~newest ~previous : Memory_pane.t =
  let gc (snapshot : Exchange_stats.Snapshot.t) = snapshot.gc in
  let chart =
    build_chart
      ~window
      ~snapshots
      ~series_values:
        [ ( "live words"
          , List.map snapshots ~f:(fun snapshot ->
              Some (Float.of_int (gc snapshot).live_words)) )
        ]
      ~format_y:(fun words -> format_count (Float.to_int words))
      ~tooltip:words_tooltip
  in
  let live_words = (gc newest).live_words in
  let peak_words =
    List.map snapshots ~f:(fun snapshot -> (gc snapshot).live_words)
    |> List.max_elt ~compare:Int.compare
    |> Option.value ~default:live_words
  in
  let rate counter =
    match rate_per_sec ~newest ~previous ~counter with
    | None -> "—"
    | Some rate -> format_count (Float.to_int rate)
  in
  { chart
  ; live_words = format_count live_words
  ; live_bytes = format_bytes (Float.of_int live_words *. bytes_per_word)
  ; peak_words = format_count peak_words
  ; usage_fraction =
      (match peak_words with
       | 0 -> 0.
       | peak -> Float.of_int live_words /. Float.of_int peak)
  ; allocation_rate =
      rate (fun snapshot -> snapshot.Exchange_stats.Snapshot.gc.minor_words)
  ; minor_gcs_per_sec =
      rate (fun snapshot ->
        Float.of_int snapshot.Exchange_stats.Snapshot.gc.minor_collections)
  ; major_gcs_per_sec =
      rate (fun snapshot ->
        Float.of_int snapshot.Exchange_stats.Snapshot.gc.major_collections)
  }
;;

module Latency_pane = struct
  type t =
    { chart : Trend_chart.t
    ; p50 : string
    ; p90 : string
    ; p99 : string
    ; max : string
    ; ops_per_sec : string
    }
  [@@deriving sexp_of, compare, equal]
end

let span_ns span = Float.of_int (Time_ns.Span.to_int_ns span)

let latency_tooltip
  ~ops_label
  ~summary
  (snapshot : Exchange_stats.Snapshot.t)
  =
  let lines =
    match (summary snapshot : Exchange_stats.Latency_summary.t option) with
    | None -> [ ops_label, "0" ]
    | Some { count; p50; p90; p99; max } ->
      [ "p50", format_span p50
      ; "p90", format_span p90
      ; "p99", format_span p99
      ; "max", format_span max
      ; ops_label, format_count count
      ]
  in
  { Trend_chart.Tooltip.title = time_label snapshot.sampled_at; lines }
;;

let latency_pane ~window snapshots ~newest ~summary ~ops_label
  : Latency_pane.t
  =
  let percentile_series label get =
    ( label
    , List.map snapshots ~f:(fun snapshot ->
        Option.map (summary snapshot) ~f:(fun s -> span_ns (get s))) )
  in
  let chart =
    build_chart
      ~window
      ~snapshots
      ~series_values:
        [ percentile_series
            "p50"
            (fun (s : Exchange_stats.Latency_summary.t) -> s.p50)
        ; percentile_series
            "p90"
            (fun (s : Exchange_stats.Latency_summary.t) -> s.p90)
        ; percentile_series
            "p99"
            (fun (s : Exchange_stats.Latency_summary.t) -> s.p99)
        ]
      ~format_y:format_span_ns
      ~tooltip:(latency_tooltip ~ops_label ~summary)
  in
  match (summary newest : Exchange_stats.Latency_summary.t option) with
  | None ->
    { chart; p50 = "—"; p90 = "—"; p99 = "—"; max = "—"; ops_per_sec = "0" }
  | Some { count; p50; p90; p99; max } ->
    { chart
    ; p50 = format_span p50
    ; p90 = format_span p90
    ; p99 = format_span p99
    ; max = format_span max
    ; ops_per_sec = format_count count
    }
;;

module Occupancy_pane = struct
  module Row = struct
    type t =
      { label : string
      ; kind : string
      ; length : int
      ; length_text : string
      ; fraction : float
      ; is_hot : bool
      }
    [@@deriving sexp_of, compare, equal]
  end

  type t =
    { rows : Row.t list
    ; hidden_rows : int
    ; total : string
    }
  [@@deriving sexp_of, compare, equal]
end

let occupancy_pane (occupancy : Exchange_stats.Pipe_occupancy.t)
  : Occupancy_pane.t
  =
  let audit =
    List.mapi occupancy.audit_log ~f:(fun i length ->
      [%string "audit #%{i + 1#Int}"], "AUDIT", length)
  in
  let market_data =
    List.concat_map occupancy.market_data ~f:(fun (symbol, lengths) ->
      List.mapi lengths ~f:(fun i length ->
        [%string "%{symbol#Symbol} #%{i + 1#Int}"], "MKT DATA", length))
  in
  let sessions =
    List.map occupancy.sessions ~f:(fun (participant, length) ->
      Participant.to_string participant, "SESSION", length)
  in
  let all =
    audit @ market_data @ sessions
    |> List.sort
         ~compare:
           (Comparable.lift
              Int.descending
              ~f:(fun ((_ : string), (_ : string), length) -> length))
  in
  let shown, hidden = List.split_n all occupancy_rows_limit in
  let largest =
    List.hd shown
    |> Option.value_map
         ~default:0
         ~f:(fun ((_ : string), (_ : string), length) -> length)
  in
  let rows =
    List.map shown ~f:(fun (label, kind, length) ->
      { Occupancy_pane.Row.label
      ; kind
      ; length
      ; length_text = format_count length
      ; fraction =
          (match largest with
           | 0 -> 0.
           | largest -> Float.of_int length /. Float.of_int largest)
      ; is_hot = length >= hot_queue_threshold
      })
  in
  { rows
  ; hidden_rows = List.length hidden
  ; total = format_count (Exchange_stats.Pipe_occupancy.total occupancy)
  }
;;

(* ---------- top level ---------- *)

type t =
  | Waiting_for_first_poll
  | No_samples of
      { exchange_connection : Dashboard_protocol.Exchange_connection.t }
  | Showing of
      { exchange_connection : Dashboard_protocol.Exchange_connection.t
      ; last_sample_label : string
      ; memory : Memory_pane.t
      ; submit_latency : Latency_pane.t
      ; cancel_latency : Latency_pane.t
      ; occupancy : Occupancy_pane.t
      }
[@@deriving sexp_of, equal]

let create ?(window = default_window) response =
  match response with
  | None -> Waiting_for_first_poll
  | Some
      { Dashboard_protocol.Recent_samples.Response.exchange_connection
      ; snapshots
      } ->
    (match List.length snapshots with
     | 0 -> No_samples { exchange_connection }
     | count ->
       let snapshots = List.drop snapshots (count - window) in
       let newest = List.last_exn snapshots in
       let previous =
         match List.drop_last_exn snapshots with
         | [] -> None
         | _ :: _ as rest -> Some (List.last_exn rest)
       in
       Showing
         { exchange_connection
         ; last_sample_label = time_label newest.sampled_at
         ; memory = memory_pane ~window snapshots ~newest ~previous
         ; submit_latency =
             latency_pane
               ~window
               snapshots
               ~newest
               ~summary:(fun snapshot -> snapshot.submit_latency)
               ~ops_label:"submits"
         ; cancel_latency =
             latency_pane
               ~window
               snapshots
               ~newest
               ~summary:(fun snapshot -> snapshot.cancel_latency)
               ~ops_label:"cancels"
         ; occupancy = occupancy_pane newest.pipe_occupancy
         })
;;

module For_testing = struct
  let format_count = format_count
  let format_bytes = format_bytes
  let nice_ceil = nice_ceil
  let time_label = time_label
  let x_positions = x_positions
  let segments_of_points = segments_of_points
end
