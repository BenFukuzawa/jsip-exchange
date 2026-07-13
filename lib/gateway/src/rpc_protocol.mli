(** RPC definitions for client-server communication.

    Defines the RPCs that clients use to interact with the exchange server.
    Each RPC has a query type (what the client sends) and a response type
    (what the server returns).

    We use Async RPCs, but on a production exchange, clients would connect
    over a binary protocol like FIX or a proprietary format. *)

open! Core
open! Async
open Jsip_types
open Jsip_exchange_stats

(** Submit an order to the exchange.

    This is a one-way RPC. The server enqueues the order and returns as soon
    as possible. The matching engine processes the queued request on a
    background worker and hands the resulting [Exchange_event.t]s to the
    [Dispatcher], which routes participant-targeted events (acceptance,
    fills, rejection) to the owning participant's [Session]. The per-session
    RPC that lets a client read its session feed does not exist yet (planned
    for week 2); until it does, those events are printed on the server's
    stdout.

    The error case covers connection-level failures only — connection closed,
    server shutting down, etc. — not domain errors like unknown symbols
    (those arrive as [Order_reject] events on the session feed). *)
val submit_order_rpc : (Order.Request.t, unit Or_error.t) Rpc.Rpc.t

(** Query the order book for a given symbol id. Returns a structured snapshot
    of all resting orders on both sides, if a book for that id exists. As of
    Exercise 4 the query is a wire-visible {!Jsip_types.Symbol_id.t}; the client
    resolves its name via the symbol directory. *)
val book_query_rpc : (Symbol_id.t, Book.t option) Rpc.Rpc.t

(** Fetch the exchange's symbol directory: the full name<->id mapping the
    server built from its symbol universe. Clients dispatch this once right
    after connecting so they can render wire-visible {!Jsip_types.Symbol_id.t}s
    as human ticker names and resolve typed tickers back to ids on the parse
    edge. *)
val symbol_directory_rpc : (unit, (Symbol.t * Symbol_id.t) list) Rpc.Rpc.t

(** Subscribe to market data for one or more symbols. The server pushes BBO
    updates and trade reports as they happen via a single pipe. The query is
    the list of symbols to subscribe to; using one RPC for the whole list
    avoids the overhead of opening a separate pipe per symbol when a client
    cares about several. *)
val market_data_rpc
  : (Symbol_id.t list, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t

(** Subscribe to the full audit log: every [Exchange_event.t] the matching
    engine produces, across every symbol and participant.

    This RPC is intended for the exchange operator's monitoring and audit
    tools (e.g. the bonsai_term monitor in [app/monitor]) only. Ordinary
    participants — automated bots, human-driven clients — should use
    [market_data_rpc] for public events, and (once it exists, week 2) a
    per-participant session-feed RPC for their own order-lifecycle events. A
    production exchange would gate this RPC behind operator-level
    credentials; this simulator does not, but the same intent applies. *)
val audit_log_rpc : (unit, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t

(* Validates the name and allows users to log onto their session *)
val login_rpc : (string, Participant.t Or_error.t) Rpc.Rpc.t

(* Informs the client when an order of their's has been executed *)
val session_feed_rpc : (unit, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t
val cancel_order_rpc : (Client_order_id.t, unit Or_error.t) Rpc.Rpc.t

(** Subscribe to per-second {!Exchange_stats.Snapshot.t}s of the server's
    runtime health: GC state, submit/cancel handling latency, and
    subscriber-pipe occupancy. Like {!audit_log_rpc}, this is an operator
    tool (the [app/dashboard] web dashboard is the intended consumer), not
    something ordinary participants should poll. Metrics stream on their own
    RPC rather than as [Exchange_event.t]s so the audit log stays a record of
    market activity. *)
val exchange_stats_rpc
  : (unit, Exchange_stats.Snapshot.t, Error.t) Rpc.Pipe_rpc.t
