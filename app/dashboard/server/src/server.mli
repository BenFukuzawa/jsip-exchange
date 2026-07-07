(** The dashboard's native half: exchange poller + web server.

    Holds a persistent subscription to the exchange's
    [Rpc_protocol.exchange_stats_rpc] (retrying once per second if the
    exchange goes away), folds the streamed snapshots into a
    {!Sample_history}, and serves three things on one HTTP port:

    - [GET /] — the dashboard page, which loads the compiled Bonsai client;
    - [GET /main.js] — the js_of_ocaml bundle built from
      [app/dashboard/client];
    - websocket upgrades — [Dashboard_protocol.recent_samples_rpc], which the
      Bonsai client polls once per second.

    There is also [GET /status.sexp], the same response as the RPC as a sexp,
    so the feed can be checked with [curl] before opening a browser. *)

open! Core
open! Async

(** Runs the server; see the [-help] output for flags (dashboard port,
    exchange host/port, client-js override). *)
val command : Command.t
