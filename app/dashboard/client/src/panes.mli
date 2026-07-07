(** The dashboard's pane and page views: panel chrome, stat tiles, the
    occupancy table, the header with its connection chip, and one full-page
    view per {!View_model.t} state.

    Pure views only ({!Chart} draws the SVG plots; the Bonsai layer in {!App}
    builds those separately because they carry hover state, and passes the
    finished nodes in here). *)

open! Core
open Virtual_dom
open Jsip_dashboard_protocol
open Jsip_dashboard_view_model

(** Skeleton page shown before the first poll answers. *)
val waiting_page : Vdom.Node.t

(** The dashboard server is up but has never heard from the exchange. *)
val no_samples_page
  :  exchange_connection:Dashboard_protocol.Exchange_connection.t
  -> Vdom.Node.t

(** The real dashboard: memory, submit/cancel latency, and occupancy panes.
    The [*_chart] nodes are {!Chart.view} output for the corresponding pane's
    data. *)
val showing_page
  :  exchange_connection:Dashboard_protocol.Exchange_connection.t
  -> last_sample_label:string
  -> memory:View_model.Memory_pane.t
  -> memory_chart:Vdom.Node.t
  -> submit_latency:View_model.Latency_pane.t
  -> submit_chart:Vdom.Node.t
  -> cancel_latency:View_model.Latency_pane.t
  -> cancel_chart:Vdom.Node.t
  -> occupancy:View_model.Occupancy_pane.t
  -> Vdom.Node.t
