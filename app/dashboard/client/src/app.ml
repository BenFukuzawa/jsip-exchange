open! Core
open Bonsai_web
open! Bonsai.Let_syntax
open Jsip_dashboard_protocol
open Jsip_dashboard_view_model

(* One chart with its own hover state; the state is per-component, so
   hovering the submit chart doesn't light up the cancel chart. *)
let trend_chart ?(mode = `Line) ~palette chart (local_ graph) =
  let hovered, set_hovered = Bonsai.state (None : int option) graph in
  let%arr chart and hovered and set_hovered in
  Chart.view ~mode ~chart ~palette ~hovered ~set_hovered ()
;;

let app (local_ graph) =
  let response =
    Rpc_effect.Rpc.poll
      Dashboard_protocol.recent_samples_rpc
      ~equal_query:[%equal: unit]
      ~every:(Bonsai.return View_model.poll_interval)
      ~output_type:Rpc_effect.Poll_result.Output_type.Last_ok_response
      (Bonsai.return ())
      graph
  in
  let view_model =
    let%arr response in
    View_model.create response
  in
  match%sub view_model with
  | View_model.Waiting_for_first_poll -> Bonsai.return Panes.waiting_page
  | No_samples { exchange_connection } ->
    let%arr exchange_connection in
    Panes.no_samples_page ~exchange_connection
  | Showing
      { exchange_connection
      ; last_sample_label
      ; memory
      ; submit_latency
      ; cancel_latency
      ; occupancy
      } ->
    let memory_chart =
      trend_chart
        ~mode:`Bars
        ~palette:Styles.Color.memory_series
        (let%arr memory in
         memory.chart)
        graph
    in
    let submit_chart =
      trend_chart
        ~palette:Styles.Color.latency_series
        (let%arr submit_latency in
         submit_latency.chart)
        graph
    in
    let cancel_chart =
      trend_chart
        ~palette:Styles.Color.latency_series
        (let%arr cancel_latency in
         cancel_latency.chart)
        graph
    in
    let%arr exchange_connection
    and last_sample_label
    and memory
    and submit_latency
    and cancel_latency
    and occupancy
    and memory_chart
    and submit_chart
    and cancel_chart in
    Panes.showing_page
      ~exchange_connection
      ~last_sample_label
      ~memory
      ~memory_chart
      ~submit_latency
      ~submit_chart
      ~cancel_latency
      ~cancel_chart
      ~occupancy
;;
