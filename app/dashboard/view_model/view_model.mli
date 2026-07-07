(** The dashboard's pure state: server response in, renderable pane data out.

    This is the [app/monitor]-style split ([Controller] there, this module
    here): everything that can be computed without Bonsai — chart
    normalization, percentile/byte/rate formatting, occupancy ranking — lives
    in this module as plain data, so [app/dashboard/test/test_view_model.ml]
    can pin it with expect tests. {!Chart} and {!Panes} only draw what this
    module hands them; the Bonsai layer in {!App} only wires polling and
    hover state.

    Chart coordinates are normalized: x and y both live in [0, 1], with x = 1
    the newest sample and y = 1 the top of the pane's y-axis (a "nice"
    rounding of the window's maximum). The view layer scales them to pixels. *)

open! Core
open Jsip_dashboard_protocol

module Trend_chart : sig
  module Tooltip : sig
    type t =
      { title : string (** the sample's UTC wall-clock, e.g. "12:04:05Z" *)
      ; lines : (string * string) list (** label, value rows *)
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Sample_slot : sig
    (** One hoverable time slot; index into {!Trend_chart.t.slots} is the
        hover key. *)
    type t =
      { x : float
      ; tooltip : Tooltip.t
      }
    [@@deriving sexp_of, compare, equal]
  end

  module Series : sig
    type t =
      { label : string
      ; segments : (float * float) list list
      (** contiguous runs of samples; a gap (e.g. a second with no cancels)
          ends one segment and starts the next, so the view draws a break
          instead of interpolating through missing data *)
      ; label_position : (float * float) option
      (** where to anchor the series' direct label: its newest point *)
      }
    [@@deriving sexp_of, compare, equal]
  end

  type t =
    { series : Series.t list (** draw order: later series on top *)
    ; y_ticks : (float * string) list
    (** normalized y, label — gridline positions *)
    ; slots : Sample_slot.t list
    ; x_span : (string * string) option
    (** oldest/newest time labels for the x axis; [None] with one sample *)
    }
  [@@deriving sexp_of, compare, equal]
end

module Memory_pane : sig
  type t =
    { chart : Trend_chart.t (** one series: live major-heap words *)
    ; live_words : string
    ; live_bytes : string
    ; peak_words : string (** largest live_words seen in the window *)
    ; usage_fraction : float
    (** current live_words as a fraction of {!peak_words}, in [0, 1], for
        the htop-style fill meter *)
    ; allocation_rate : string
    (** minor-heap words allocated per second, from successive samples; "—"
        until two samples exist *)
    ; minor_gcs_per_sec : string
    ; major_gcs_per_sec : string
    }
  [@@deriving sexp_of, compare, equal]
end

module Latency_pane : sig
  (** Used twice: submit and cancel. The chart carries p50/p90/p99 as three
      series (in that order — the view colors p99 brightest). *)
  type t =
    { chart : Trend_chart.t
    ; p50 : string
    ; p90 : string
    ; p99 : string
    ; max : string
    ; ops_per_sec : string
    (** operations measured in the newest sample's interval; "0" plus em-dash
        latencies means the path is idle *)
    }
  [@@deriving sexp_of, compare, equal]
end

module Occupancy_pane : sig
  module Row : sig
    type t =
      { label : string (** participant name, symbol, or "audit #n" *)
      ; kind : string (** "SESSION", "MKT DATA", or "AUDIT" *)
      ; length : int
      ; length_text : string
      ; fraction : float (** of the largest queue shown, for the bar *)
      ; is_hot : bool
      (** queue length at or above {!hot_queue_threshold} — render loud *)
      }
    [@@deriving sexp_of, compare, equal]
  end

  type t =
    { rows : Row.t list (** longest queue first, capped *)
    ; hidden_rows : int (** rows dropped by the cap *)
    ; total : string (** every queued event, across all pipes *)
    }
  [@@deriving sexp_of, compare, equal]
end

type t =
  | Waiting_for_first_poll
  (** no response from the dashboard server yet — render skeletons *)
  | No_samples of
      { exchange_connection : Dashboard_protocol.Exchange_connection.t }
  (** server reachable but its buffer is empty (exchange never up since the
      dashboard server started) *)
  | Showing of
      { exchange_connection : Dashboard_protocol.Exchange_connection.t
      (** [Disconnected] means the panes below are a stale buffer *)
      ; last_sample_label : string
      ; memory : Memory_pane.t
      ; submit_latency : Latency_pane.t
      ; cancel_latency : Latency_pane.t
      ; occupancy : Occupancy_pane.t
      }
[@@deriving sexp_of, equal]

(** [window] is how many trailing samples (= seconds) the charts show. *)
val create
  :  ?window:int (** default {!default_window} *)
  -> Dashboard_protocol.Recent_samples.Response.t option
  -> t

(** The [window] used by {!create} when not overridden. Exposed so the
    header's "window 60s" label is derived from the same constant. *)
val default_window : int

(** How often the Bonsai layer polls the dashboard server. Lives in the pure
    core (rather than in [App]) so the header's "poll 1s" label and the
    poller can't drift apart. *)
val poll_interval : Time_ns.Span.t

(** Sessions/pipes with at least this many queued events are flagged
    [is_hot]: at typical scenario event rates it means the consumer has been
    stuck for many seconds, not momentarily behind. *)
val hot_queue_threshold : int

module For_testing : sig
  val format_count : int -> string
  val format_bytes : float -> string
  val nice_ceil : float -> float
  val time_label : Time_ns.t -> string
  val x_positions : window:int -> count:int -> float list

  val segments_of_points
    :  (float * float) option list
    -> (float * float) list list
end
