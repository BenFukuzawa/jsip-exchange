open! Core
open Virtual_dom

module Color = struct
  let bg_page = "#0b0d10"
  let bg_panel = "#12151a"
  let bg_raised = "#191d24"
  let border = "#232830"
  let text_primary = "#f2f4f8"
  let text_secondary = "#c3cad3"
  let text_tertiary = "#8b93a1"
  let text_faint = "#5c6470"
  let accent = "#3987e5"
  let good = "#0ca30c"
  let warning = "#fab219"
  let serious = "#ec835a"
  let grid_line = "#1c2129"
  let latency_series = [ "#184f95"; "#3987e5"; "#86b6ef" ]
  let memory_series = [ "#3987e5" ]
end

module Font = struct
  let sans = "system-ui, -apple-system, 'Segoe UI', sans-serif"
  let mono = "ui-monospace, 'SF Mono', Menlo, Consolas, monospace"
end

let inline css = Vdom.Attr.create "style" css

let pct fraction =
  [%string
    "%{Float.to_string_hum (fraction *. 100.) ~decimals:2 ~strip_zero:true}%"]
;;

let page =
  inline
    [%string
      "min-height: 100vh; box-sizing: border-box; padding: 12px; \
       background: %{Color.bg_page}; color: %{Color.text_primary}; \
       font-family: %{Font.sans}; font-size: 13px; color-scheme: dark; \
       font-variant-numeric: tabular-nums;"]
;;

let header =
  inline
    [%string
      "display: flex; align-items: center; gap: 12px; padding: 0 2px 10px \
       2px;"]
;;

let header_title =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 13px; font-weight: 600; color: \
       %{Color.text_primary};"]
;;

let header_meta =
  inline
    [%string
      "margin-left: auto; display: flex; align-items: center; gap: 12px; \
       font-family: %{Font.mono}; font-size: 11px; color: \
       %{Color.text_faint};"]
;;

let pane_grid =
  inline
    "display: grid; grid-template-columns: repeat(auto-fit, minmax(420px, \
     1fr)); gap: 10px; align-items: start;"
;;

let panel =
  inline
    [%string
      "background: %{Color.bg_panel}; border: 1px solid %{Color.border}; \
       border-radius: 6px; padding: 10px 12px 12px 12px; min-width: 0;"]
;;

let panel_header =
  inline
    "display: flex; align-items: baseline; gap: 10px; margin-bottom: 8px;"
;;

let panel_title =
  inline
    [%string
      "font-size: 11px; font-weight: 600; text-transform: uppercase; color: \
       %{Color.text_tertiary};"]
;;

let legend =
  inline "margin-left: auto; display: flex; align-items: center; gap: 10px;"
;;

let legend_swatch ~color =
  inline
    [%string
      "display: inline-block; width: 8px; height: 8px; border-radius: 2px; \
       background: %{color};"]
;;

let legend_label =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 10px; color: \
       %{Color.text_tertiary}; margin-left: 4px;"]
;;

let tile_row =
  inline "display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap;"
;;

let tile =
  inline
    [%string
      "flex: 1 1 72px; min-width: 72px; background: %{Color.bg_raised}; \
       border: 1px solid %{Color.border}; border-radius: 4px; padding: 6px \
       8px;"]
;;

let tile_label =
  inline
    [%string
      "font-size: 9px; font-weight: 600; text-transform: uppercase; color: \
       %{Color.text_faint}; white-space: nowrap;"]
;;

let tile_value ~emphasis =
  let color =
    if emphasis then Color.text_primary else Color.text_secondary
  in
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 15px; margin-top: 2px; color: \
       %{color}; white-space: nowrap;"]
;;

let status_chip ~color =
  inline
    [%string
      "display: inline-flex; align-items: center; gap: 6px; padding: 3px \
       8px; border: 1px solid %{Color.border}; border-radius: 4px; \
       background: %{Color.bg_panel}; font-family: %{Font.mono}; font-size: \
       11px; color: %{color};"]
;;

let status_dot ~color =
  inline
    [%string
      "display: inline-block; width: 7px; height: 7px; border-radius: 50%%; \
       background: %{color};"]
;;

let notice ~color =
  inline
    [%string
      "border: 1px solid %{color}; border-radius: 6px; padding: 10px 12px; \
       margin-bottom: 10px; color: %{color}; font-family: %{Font.mono}; \
       font-size: 12px;"]
;;

let occupancy_table =
  inline "display: flex; flex-direction: column; gap: 3px;"
;;

let occupancy_row =
  inline "display: flex; align-items: center; gap: 8px; height: 20px;"
;;

let occupancy_label =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 11px; color: \
       %{Color.text_secondary}; width: 130px; overflow: hidden; \
       text-overflow: ellipsis; white-space: nowrap; flex: none;"]
;;

let occupancy_kind =
  inline
    [%string
      "font-size: 9px; color: %{Color.text_faint}; width: 60px; flex: none;"]
;;

let occupancy_bar_track =
  inline
    [%string
      "flex: 1; height: 10px; background: %{Color.bg_raised}; \
       border-radius: 2px; overflow: hidden;"]
;;

let occupancy_bar ~fraction ~hot =
  let color = if hot then Color.warning else Color.accent in
  inline
    [%string
      "width: %{pct fraction}; height: 100%%; background: %{color}; \
       border-radius: 2px;"]
;;

let occupancy_value ~hot =
  let color = if hot then Color.warning else Color.text_primary in
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 11px; color: %{color}; width: \
       64px; text-align: right; flex: none;"]
;;

let occupancy_footer =
  inline
    [%string
      "margin-top: 8px; font-family: %{Font.mono}; font-size: 10px; color: \
       %{Color.text_faint};"]
;;

(* htop-style fill meter: [| LABEL [||||||||        ]  caption |]. The fill
   goes accent → amber → red as the heap approaches its window peak, echoing
   htop's memory bar. *)
let meter_fill_color fraction =
  if Float.( >= ) fraction 0.85
  then Color.serious
  else if Float.( >= ) fraction 0.6
  then Color.warning
  else Color.accent
;;

let meter_row =
  inline "display: flex; align-items: center; gap: 8px; margin-top: 2px;"
;;

let meter_track =
  inline
    [%string
      "flex: 1; height: 14px; background: %{Color.bg_raised}; border: 1px \
       solid %{Color.border}; border-radius: 3px; overflow: hidden;"]
;;

let meter_fill ~fraction =
  let clamped = Float.max 0. (Float.min 1. fraction) in
  inline
    [%string
      "width: %{pct clamped}; height: 100%%; background: \
       %{meter_fill_color clamped};"]
;;

let meter_caption =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 10px; color: \
       %{Color.text_tertiary}; white-space: nowrap;"]
;;

(* Chart chrome: a fixed-height block with an absolutely positioned y gutter
   on the left, the stretching SVG plot to its right, and a thin x-axis strip
   along the bottom. Fixed pixel heights keep the panes from reflowing as
   data arrives. *)

let chart_height_px = 130
let x_axis_height_px = 14
let y_gutter_width_px = 56

let chart_block =
  inline
    [%string
      "position: relative; height: %{chart_height_px#Int}px; margin-top: \
       4px;"]
;;

let chart_y_gutter =
  inline
    [%string
      "position: absolute; left: 0; top: 0; bottom: \
       %{x_axis_height_px#Int}px; width: %{y_gutter_width_px - 8#Int}px;"]
;;

let chart_y_label ~fraction =
  (* [fraction] is the tick's normalized y (0 = bottom). *)
  inline
    [%string
      "position: absolute; right: 0; top: %{pct (1. -. fraction)}; \
       transform: translateY(-50%%); font-family: %{Font.mono}; font-size: \
       10px; color: %{Color.text_faint};"]
;;

let chart_plot =
  inline
    [%string
      "position: absolute; left: %{y_gutter_width_px#Int}px; right: 2px; \
       top: 0; bottom: %{x_axis_height_px#Int}px;"]
;;

let chart_x_axis =
  inline
    [%string
      "position: absolute; left: %{y_gutter_width_px#Int}px; right: 2px; \
       bottom: 0; height: %{x_axis_height_px - 2#Int}px; display: flex; \
       justify-content: space-between; font-family: %{Font.mono}; \
       font-size: 10px; color: %{Color.text_faint};"]
;;

let chart_series_label ~color ~fraction =
  inline
    [%string
      "position: absolute; right: 2px; top: %{pct (1. -. fraction)}; \
       transform: translateY(-50%%); font-family: %{Font.mono}; font-size: \
       10px; color: %{color}; pointer-events: none;"]
;;

let chart_tooltip ~x_fraction =
  (* Flip sides at the midpoint so the box never overflows the pane. *)
  let translate =
    if Float.( > ) x_fraction 0.5 then "translateX(-100%)" else "none"
  in
  inline
    [%string
      "position: absolute; left: %{pct x_fraction}; top: 2px; transform: \
       %{translate}; background: %{Color.bg_raised}; border: 1px solid \
       %{Color.border}; border-radius: 4px; padding: 5px 8px; z-index: 2; \
       pointer-events: none; min-width: 110px;"]
;;

let tooltip_title =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 10px; color: \
       %{Color.text_faint}; margin-bottom: 3px;"]
;;

let tooltip_line =
  inline "display: flex; justify-content: space-between; gap: 10px;"
;;

let tooltip_label =
  inline [%string "font-size: 10px; color: %{Color.text_tertiary};"]
;;

let tooltip_value =
  inline
    [%string
      "font-family: %{Font.mono}; font-size: 10px; color: \
       %{Color.text_primary};"]
;;
