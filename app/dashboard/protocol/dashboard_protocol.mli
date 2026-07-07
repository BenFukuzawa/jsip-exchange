(** The RPC spoken between the dashboard's web client and its server.

    The dashboard is split in two because a browser cannot open the
    exchange's raw-TCP RPC port: a native server ([app/dashboard/server])
    subscribes to [Jsip_gateway.Rpc_protocol.exchange_stats_rpc] and buffers
    the last couple of minutes of {!Exchange_stats.Snapshot.t}s, and the
    browser client ([app/dashboard/client]) polls it over a websocket with
    {!recent_samples_rpc} and renders the panes.

    This library must stay loadable from js_of_ocaml: [core] and
    [async_rpc_kernel] only — no [Async]. *)

open! Core
open Async_rpc_kernel
open Jsip_exchange_stats

module Exchange_connection : sig
  (** Whether the dashboard server currently holds a live subscription to the
      exchange's stats feed. [Disconnected] tells the client to render its
      "stale data" banner: buffered snapshots are still served, but nothing
      new is arriving. *)
  type t =
    | Connected
    | Disconnected
  [@@deriving sexp, bin_io, compare, equal]
end

module Recent_samples : sig
  module Response : sig
    type t =
      { exchange_connection : Exchange_connection.t
      ; snapshots : Exchange_stats.Snapshot.t list
      (** rolling window, oldest first; at most the server's history capacity
          (about two minutes at one snapshot per second) *)
      }
    [@@deriving sexp, bin_io, compare, equal]
  end
end

(** Fetch the server's whole rolling window. The client polls this once per
    second ([Rpc_effect.Rpc.poll]) rather than holding a pipe: if a browser
    tab is backgrounded it simply stops polling, instead of letting a
    server-side pipe fill — the very pathology the dashboard exists to
    display. *)
val recent_samples_rpc : (unit, Recent_samples.Response.t) Rpc.Rpc.t
