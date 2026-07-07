(** Design tokens and style attributes for the dashboard, in one place.

    The look is a dense, dark operator terminal: near-black elevation tiers,
    monospace tabular numerals for every figure, one blue accent, and
    reserved status colors (green / amber / red) that never double as series
    colors. Views ({!Chart}, {!Panes}) take attributes from here rather than
    building style strings inline, so spacing and color stay consistent
    across panes. *)

open! Core
open Virtual_dom

(** Raw color tokens, exposed for the SVG layer (which needs hex values, not
    style attributes). *)
module Color : sig
  val bg_page : string
  val bg_panel : string
  val bg_raised : string
  val border : string
  val text_primary : string
  val text_secondary : string
  val text_tertiary : string
  val text_faint : string
  val accent : string
  val good : string
  val warning : string
  val serious : string
  val grid_line : string

  (** Sequential blues for the p50/p90/p99 series, in that order — brightest
      last so the worst percentile pops on the dark surface. Validated with
      the dataviz palette checker (ordinal, dark). *)
  val latency_series : string list

  (** Single-series hue for the memory chart. *)
  val memory_series : string list
end

(** [inline "display: flex"] — the project has no [ppx_css], so styles are
    plain [style] attributes built from the tokens above. *)
val inline : string -> Vdom.Attr.t

val page : Vdom.Attr.t
val header : Vdom.Attr.t
val header_title : Vdom.Attr.t
val header_meta : Vdom.Attr.t
val pane_grid : Vdom.Attr.t
val panel : Vdom.Attr.t
val panel_header : Vdom.Attr.t
val panel_title : Vdom.Attr.t
val legend : Vdom.Attr.t
val legend_swatch : color:string -> Vdom.Attr.t
val legend_label : Vdom.Attr.t
val tile_row : Vdom.Attr.t
val tile : Vdom.Attr.t
val tile_label : Vdom.Attr.t

(** [emphasis] brightens the value; use for the headline figure. *)
val tile_value : emphasis:bool -> Vdom.Attr.t

(** Status chip in the header: dot + label. *)
val status_chip : color:string -> Vdom.Attr.t

val status_dot : color:string -> Vdom.Attr.t

(** Full-width notice band (stale-data warning, empty states). *)
val notice : color:string -> Vdom.Attr.t

(** Occupancy table. *)
val occupancy_table : Vdom.Attr.t

val occupancy_row : Vdom.Attr.t
val occupancy_label : Vdom.Attr.t
val occupancy_kind : Vdom.Attr.t
val occupancy_bar_track : Vdom.Attr.t
val occupancy_bar : fraction:float -> hot:bool -> Vdom.Attr.t
val occupancy_value : hot:bool -> Vdom.Attr.t
val occupancy_footer : Vdom.Attr.t

(** htop-style memory fill meter: a labelled horizontal bar filled to the
    current-vs-peak fraction, colored by how full it is. *)
val meter_row : Vdom.Attr.t

val meter_track : Vdom.Attr.t
val meter_fill : fraction:float -> Vdom.Attr.t
val meter_caption : Vdom.Attr.t

(** Chart chrome (the HTML around the SVG plot). *)
val chart_block : Vdom.Attr.t

val chart_y_gutter : Vdom.Attr.t
val chart_y_label : fraction:float -> Vdom.Attr.t
val chart_plot : Vdom.Attr.t
val chart_x_axis : Vdom.Attr.t
val chart_series_label : color:string -> fraction:float -> Vdom.Attr.t

(** Hover tooltip, positioned at the hovered slot's x fraction. *)
val chart_tooltip : x_fraction:float -> Vdom.Attr.t

val tooltip_title : Vdom.Attr.t
val tooltip_line : Vdom.Attr.t
val tooltip_label : Vdom.Attr.t
val tooltip_value : Vdom.Attr.t
