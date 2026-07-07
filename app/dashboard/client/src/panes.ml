open! Core
open Virtual_dom
open Vdom.Html_syntax
open Jsip_dashboard_protocol
open Jsip_dashboard_view_model

module Status_chip = struct
  let view ~color text =
    {%html|
      <span %{Styles.status_chip ~color}>
        <span %{Styles.status_dot ~color}></span>
        #{text}
      </span>
    |}
  ;;

  let of_connection (connection : Dashboard_protocol.Exchange_connection.t) =
    match connection with
    | Connected -> view ~color:Styles.Color.good "LIVE"
    | Disconnected -> view ~color:Styles.Color.serious "EXCHANGE OFFLINE"
  ;;
end

module Header = struct
  let view ~chip ~meta =
    let meta_spans =
      List.map meta ~f:(fun text -> {%html|<span>#{text}</span>|})
    in
    {%html|
      <div %{Styles.header}>
        <span %{Styles.header_title}>JSIP EXCHANGE · RUNTIME MONITOR</span>
        %{chip}
        <div %{Styles.header_meta}>*{meta_spans}</div>
      </div>
    |}
  ;;
end

module Panel = struct
  let view ~title ?legend children =
    let legend =
      match legend with None -> Vdom.Node.none | Some legend -> legend
    in
    {%html|
      <section %{Styles.panel}>
        <div %{Styles.panel_header}>
          <span %{Styles.panel_title}>#{title}</span>
          %{legend}
        </div>
        *{children}
      </section>
    |}
  ;;
end

module Legend = struct
  (* Series identity chips for a multi-series chart; the labels also sit on
     the plot itself (direct labels), this is the at-a-glance key. *)
  let view ~palette ~labels =
    let entries =
      List.mapi labels ~f:(fun index label ->
        let color =
          List.nth palette index |> Option.value ~default:Styles.Color.accent
        in
        {%html|
          <span>
            <span %{Styles.legend_swatch ~color}></span>
            <span %{Styles.legend_label}>#{label}</span>
          </span>
        |})
    in
    {%html|<div %{Styles.legend}>*{entries}</div>|}
  ;;
end

module Tile = struct
  let view ?(emphasis = false) ~label ~value () =
    {%html|
      <div %{Styles.tile}>
        <div %{Styles.tile_label}>#{label}</div>
        <div %{Styles.tile_value ~emphasis}>#{value}</div>
      </div>
    |}
  ;;
end

let tile_row tiles = {%html|<div %{Styles.tile_row}>*{tiles}</div>|}

let memory_meter (memory : View_model.Memory_pane.t) =
  {%html|
    <div %{Styles.meter_row}>
      <div %{Styles.meter_track}>
        <div %{Styles.meter_fill ~fraction:memory.usage_fraction}></div>
      </div>
      <span %{Styles.meter_caption}>
        #{[%string "%{memory.live_words} / %{memory.peak_words} peak"]}
      </span>
    </div>
  |}
;;

let memory_panel (memory : View_model.Memory_pane.t) ~chart =
  Panel.view
    ~title:"PROCESS MEMORY · LIVE WORDS"
    [ chart
    ; memory_meter memory
    ; tile_row
        [ Tile.view ~emphasis:true ~label:"live" ~value:memory.live_words ()
        ; Tile.view ~label:"live bytes" ~value:memory.live_bytes ()
        ; Tile.view ~label:"alloc/s" ~value:memory.allocation_rate ()
        ; Tile.view ~label:"minor gc/s" ~value:memory.minor_gcs_per_sec ()
        ; Tile.view ~label:"major gc/s" ~value:memory.major_gcs_per_sec ()
        ]
    ]
;;

let latency_panel (latency : View_model.Latency_pane.t) ~title ~chart =
  Panel.view
    ~title
    ~legend:
      (Legend.view
         ~palette:Styles.Color.latency_series
         ~labels:[ "p50"; "p90"; "p99" ])
    [ chart
    ; tile_row
        [ Tile.view ~label:"p50" ~value:latency.p50 ()
        ; Tile.view ~label:"p90" ~value:latency.p90 ()
        ; Tile.view ~emphasis:true ~label:"p99" ~value:latency.p99 ()
        ; Tile.view ~label:"max" ~value:latency.max ()
        ; Tile.view ~label:"ops/s" ~value:latency.ops_per_sec ()
        ]
    ]
;;

let occupancy_row (row : View_model.Occupancy_pane.Row.t) =
  let hot = row.is_hot in
  {%html|
    <div %{Styles.occupancy_row}>
      <span %{Styles.occupancy_label}>#{row.label}</span>
      <span %{Styles.occupancy_kind}>#{row.kind}</span>
      <div %{Styles.occupancy_bar_track}>
        <div %{Styles.occupancy_bar ~fraction:row.fraction ~hot}></div>
      </div>
      <span %{Styles.occupancy_value ~hot}>#{row.length_text}</span>
    </div>
  |}
;;

let occupancy_panel (occupancy : View_model.Occupancy_pane.t) =
  let body =
    match occupancy.rows with
    | [] ->
      [ {%html|
          <div %{Styles.occupancy_footer}>
            no subscriber pipes yet — connect a client, monitor, or
            scenario to see queue depths here
          </div>
        |}
      ]
    | rows ->
      let hidden =
        match occupancy.hidden_rows with
        | 0 -> ""
        | hidden -> [%string " · +%{hidden#Int} more pipes"]
      in
      [ {%html|<div %{Styles.occupancy_table}>*{List.map rows ~f:occupancy_row}</div>|}
      ; {%html|
          <div %{Styles.occupancy_footer}>
            #{[%string "%{occupancy.total} events queued across all pipes%{hidden}"]}
          </div>
        |}
      ]
  in
  Panel.view ~title:"SUBSCRIBER PIPE OCCUPANCY" body
;;

let page ~header ?notice panes =
  let notice =
    match notice with None -> Vdom.Node.none | Some notice -> notice
  in
  {%html|
    <div %{Styles.page}>
      %{header}
      %{notice}
      <div %{Styles.pane_grid}>*{panes}</div>
    </div>
  |}
;;

(* Derived from the constants the poller and charts actually use, so the
   header can't drift from the real cadence. *)
let standard_meta =
  let poll_seconds =
    Float.to_int (Time_ns.Span.to_sec View_model.poll_interval)
  in
  [ [%string "poll %{poll_seconds#Int}s"]
  ; [%string "window %{View_model.default_window#Int}s"]
  ]
;;

let waiting_page =
  let header =
    Header.view
      ~chip:(Status_chip.view ~color:Styles.Color.text_faint "CONNECTING")
      ~meta:standard_meta
  in
  page
    ~header
    [ Panel.view
        ~title:"WAITING FOR DASHBOARD SERVER"
        [ {%html|
            <div %{Styles.occupancy_footer}>
              polling for the first snapshot…
            </div>
          |}
        ]
    ]
;;

let no_samples_page ~exchange_connection =
  let header =
    Header.view
      ~chip:(Status_chip.of_connection exchange_connection)
      ~meta:standard_meta
  in
  page
    ~header
    [ Panel.view
        ~title:"NO SAMPLES YET"
        [ {%html|
            <div %{Styles.occupancy_footer}>
              the dashboard server has no snapshots — start the exchange
              (e.g. [dune exec app/scenario_runner/bin/main.exe -- -scenario
              book-fill -port 12345 -seed 0]) and this page will fill in
              within a second
            </div>
          |}
        ]
    ]
;;

let showing_page
  ~exchange_connection
  ~last_sample_label
  ~memory
  ~memory_chart
  ~submit_latency
  ~submit_chart
  ~cancel_latency
  ~cancel_chart
  ~occupancy
  =
  let header =
    Header.view
      ~chip:(Status_chip.of_connection exchange_connection)
      ~meta:([%string "last sample %{last_sample_label}"] :: standard_meta)
  in
  let notice =
    match
      (exchange_connection : Dashboard_protocol.Exchange_connection.t)
    with
    | Connected -> None
    | Disconnected ->
      Some
        {%html|
          <div %{Styles.notice ~color:Styles.Color.warning}>
            exchange feed lost — showing the last buffered samples;
            reconnecting every second
          </div>
        |}
  in
  page
    ~header
    ?notice
    [ memory_panel memory ~chart:memory_chart
    ; latency_panel
        submit_latency
        ~title:"SUBMIT LATENCY · QUEUE→HANDLED"
        ~chart:submit_chart
    ; latency_panel
        cancel_latency
        ~title:"CANCEL LATENCY · RPC HANDLER"
        ~chart:cancel_chart
    ; occupancy_panel occupancy
    ]
;;
