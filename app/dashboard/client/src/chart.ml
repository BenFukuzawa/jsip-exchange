open! Core
open Virtual_dom
open Vdom.Html_syntax
open Jsip_dashboard_view_model

(* The SVG's internal coordinate space; it is stretched to the pane, so only
   ratios matter. *)
let plot_width = 1000.
let plot_height = 300.

(* Normalized chart coords (y up) to SVG coords (y down). *)
let to_plot (x, y) = x *. plot_width, (1. -. y) *. plot_height

let non_scaling_stroke =
  Vdom.Attr.create "vector-effect" "non-scaling-stroke"
;;

let color_of_index palette index =
  List.nth palette index |> Option.value ~default:Styles.Color.accent
;;

let gridline (fraction, (_ : string)) =
  let y = (1. -. fraction) *. plot_height in
  Virtual_dom_svg.Node.line
    ~attrs:
      [ Virtual_dom_svg.Attr.x1 0.
      ; Virtual_dom_svg.Attr.x2 plot_width
      ; Virtual_dom_svg.Attr.y1 y
      ; Virtual_dom_svg.Attr.y2 y
      ; Virtual_dom_svg.Attr.stroke (`Hex Styles.Color.grid_line)
      ; Virtual_dom_svg.Attr.stroke_width 1.
      ; non_scaling_stroke
      ]
    []
;;

(* A one-sample segment has no line to draw; render a short horizontal dash
   so an isolated second of activity is still visible. *)
let dash_half_width = 6.

let segment_node ~color segment =
  let points =
    match segment with
    | [ point ] ->
      let x, y = to_plot point in
      [ x -. dash_half_width, y; x +. dash_half_width, y ]
    | points -> List.map points ~f:to_plot
  in
  Virtual_dom_svg.Node.polyline
    ~attrs:
      [ Virtual_dom_svg.Attr.points points
      ; Virtual_dom_svg.Attr.fill (`Name "none")
      ; Virtual_dom_svg.Attr.stroke (`Hex color)
      ; Virtual_dom_svg.Attr.stroke_width 2.
      ; Virtual_dom_svg.Attr.stroke_linecap `Round
      ; non_scaling_stroke
      ]
    []
;;

let series_nodes ~palette (series : View_model.Trend_chart.Series.t list) =
  List.concat_mapi series ~f:(fun index series ->
    let color = color_of_index palette index in
    List.map series.segments ~f:(segment_node ~color))
;;

(* htop renders memory as a column of blocks that goes green → amber → red as
   it fills; we echo that on the per-second bars so a filling heap reads as
   "getting hot" at a glance, not just "taller". *)
let bar_color ~palette y_fraction =
  if Float.( >= ) y_fraction 0.85
  then Styles.Color.serious
  else if Float.( >= ) y_fraction 0.6
  then Styles.Color.warning
  else color_of_index palette 0
;;

(* Render the first series as vertical bars, one per sample. A 2px surface
   gap between adjacent bars keeps them reading as discrete columns. *)
let bar_nodes ~palette ~slots (series : View_model.Trend_chart.Series.t list) =
  match series with
  | [] -> []
  | first :: _ ->
    let slot_count = Int.max 1 (List.length slots) in
    let slot_width = plot_width /. Float.of_int slot_count in
    let bar_width = Float.max 1. ((slot_width *. 0.8) -. 2.) in
    List.concat_map first.segments ~f:(fun segment ->
      List.map segment ~f:(fun (x, y_fraction) ->
        let center_x = x *. plot_width in
        let height = Float.max 1. (y_fraction *. plot_height) in
        Virtual_dom_svg.Node.rect
          ~attrs:
            [ Virtual_dom_svg.Attr.x (center_x -. (bar_width /. 2.))
            ; Virtual_dom_svg.Attr.y (plot_height -. height)
            ; Virtual_dom_svg.Attr.width bar_width
            ; Virtual_dom_svg.Attr.height height
            ; Virtual_dom_svg.Attr.fill (`Hex (bar_color ~palette y_fraction))
            ]
          []))
;;

let crosshair ~slots ~hovered =
  match Option.bind hovered ~f:(fun index -> List.nth slots index) with
  | None -> []
  | Some
      { View_model.Trend_chart.Sample_slot.x
      ; tooltip = (_ : View_model.Trend_chart.Tooltip.t)
      } ->
    let x = x *. plot_width in
    [ Virtual_dom_svg.Node.line
        ~attrs:
          [ Virtual_dom_svg.Attr.x1 x
          ; Virtual_dom_svg.Attr.x2 x
          ; Virtual_dom_svg.Attr.y1 0.
          ; Virtual_dom_svg.Attr.y2 plot_height
          ; Virtual_dom_svg.Attr.stroke (`Hex Styles.Color.text_faint)
          ; Virtual_dom_svg.Attr.stroke_width 1.
          ; Virtual_dom_svg.Attr.stroke_dasharray [ 3.; 3. ]
          ; non_scaling_stroke
          ]
        []
    ]
;;

(* One invisible full-height column per sample; wider than the 2px mark so
   the whole second is an easy hover target. *)
let hit_columns ~slots ~set_hovered =
  let half_width =
    match List.length slots with
    | 0 | 1 -> plot_width /. 2.
    | count -> plot_width /. Float.of_int (count - 1) /. 2.
  in
  List.mapi slots ~f:(fun index slot ->
    let center = slot.View_model.Trend_chart.Sample_slot.x *. plot_width in
    Virtual_dom_svg.Node.rect
      ~attrs:
        [ Virtual_dom_svg.Attr.x (Float.max 0. (center -. half_width))
        ; Virtual_dom_svg.Attr.y 0.
        ; Virtual_dom_svg.Attr.width (2. *. half_width)
        ; Virtual_dom_svg.Attr.height plot_height
        ; Virtual_dom_svg.Attr.fill (`Name "transparent")
        ; Vdom.Attr.create "pointer-events" "all"
        ; Vdom.Attr.on_mouseenter
            (fun (_ : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) ->
               set_hovered (Some index))
        ]
      [])
;;

let tooltip_node ~slots ~hovered =
  match Option.bind hovered ~f:(fun index -> List.nth slots index) with
  | None -> Vdom.Node.none
  | Some { View_model.Trend_chart.Sample_slot.x; tooltip } ->
    let lines =
      List.map tooltip.lines ~f:(fun (label, value) ->
        {%html|
          <div %{Styles.tooltip_line}>
            <span %{Styles.tooltip_label}>#{label}</span>
            <span %{Styles.tooltip_value}>#{value}</span>
          </div>
        |})
    in
    {%html|
      <div %{Styles.chart_tooltip ~x_fraction:x}>
        <div %{Styles.tooltip_title}>#{tooltip.title}</div>
        *{lines}
      </div>
    |}
;;

let series_labels ~palette (series : View_model.Trend_chart.Series.t list) =
  List.filter_mapi series ~f:(fun index series ->
    Option.map series.label_position ~f:(fun ((_ : float), y_fraction) ->
      let color = color_of_index palette index in
      {%html|
          <span %{Styles.chart_series_label ~color ~fraction:y_fraction}>
            #{series.label}
          </span>
        |}))
;;

let x_axis_node (x_span : (string * string) option) =
  match x_span with
  | None -> Vdom.Node.none
  | Some (oldest, newest) ->
    {%html|
      <div %{Styles.chart_x_axis}>
        <span>#{oldest}</span>
        <span>#{newest}</span>
      </div>
    |}
;;

let view
  ?(mode = `Line)
  ~(chart : View_model.Trend_chart.t)
  ~palette
  ~hovered
  ~set_hovered
  ()
  =
  let marks =
    match mode with
    | `Line -> series_nodes ~palette chart.series
    | `Bars -> bar_nodes ~palette ~slots:chart.slots chart.series
  in
  let svg =
    Virtual_dom_svg.Node.svg
      ~attrs:
        [ Virtual_dom_svg.Attr.viewbox
            ~min_x:0.
            ~min_y:0.
            ~width:plot_width
            ~height:plot_height
        ; Vdom.Attr.create "preserveAspectRatio" "none"
        ; Styles.inline "width: 100%; height: 100%; display: block;"
        ; Vdom.Attr.on_mouseleave
            (fun (_ : Js_of_ocaml.Dom_html.mouseEvent Js_of_ocaml.Js.t) ->
               set_hovered None)
        ]
      (List.concat
         [ List.map chart.y_ticks ~f:gridline
         ; marks
         ; crosshair ~slots:chart.slots ~hovered
         ; hit_columns ~slots:chart.slots ~set_hovered
         ])
  in
  let y_labels =
    List.map chart.y_ticks ~f:(fun (fraction, label) ->
      {%html|<span %{Styles.chart_y_label ~fraction}>#{label}</span>|})
  in
  {%html|
    <div %{Styles.chart_block}>
      <div %{Styles.chart_y_gutter}>*{y_labels}</div>
      <div %{Styles.chart_plot}>
        %{svg}
        *{series_labels ~palette chart.series}
        %{tooltip_node ~slots:chart.slots ~hovered}
      </div>
      %{x_axis_node chart.x_span}
    </div>
  |}
;;
