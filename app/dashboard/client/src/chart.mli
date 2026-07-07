(** SVG rendering for {!View_model.Trend_chart}.

    Pure view: geometry comes normalized from the view model, colors come
    from the caller (one hex per series, in series order — see
    {!Styles.Color.latency_series}), and hover state is threaded in from the
    Bonsai layer. The plot is an SVG that stretches to its pane
    ([preserveAspectRatio: none] with non-scaling strokes); labels, axes, and
    the tooltip are HTML positioned around it so text never distorts.

    Hovering works per time slot: each sample gets an invisible full-height
    hit column that calls [set_hovered] with its index, and the hovered slot
    renders a crosshair plus tooltip. *)

open! Core
open Virtual_dom
open Jsip_dashboard_view_model

(** [mode] selects line marks (the default, for the latency percentile
    series) or vertical bars (used for the memory pane, giving it the
    htop column-graph look). *)
val view
  :  ?mode:[ `Line | `Bars ]
  -> chart:View_model.Trend_chart.t
  -> palette:string list
  -> hovered:int option
  -> set_hovered:(int option -> unit Vdom.Effect.t)
  -> unit
  -> Vdom.Node.t
