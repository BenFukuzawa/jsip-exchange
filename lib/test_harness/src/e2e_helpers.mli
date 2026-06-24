(** Shared helpers for end-to-end tests that use a real server and RPC
    clients. *)

open! Core
open! Async
open Jsip_types
open Jsip_gateway

(** Start a server on an OS-assigned port, run [f], then shut down. *)
val with_server
  :  symbols:Symbol.t list
  -> (server:Exchange_server.t -> port:int -> 'a Deferred.t)
  -> 'a Deferred.t

(** A test client: an open RPC connection to the server with a logged-in
    session. The client automatically subscribes to the session feed and
    prints all received events with a [[ParticipantName]] prefix. *)
type client

(** Connect a client to [port], log in as [participant] via [login_rpc],
    and subscribe to [session_feed_rpc]. Events pushed to this
    participant's session (order accepts, fills, cancels, rejects) are
    printed to stdout with a [[ParticipantName]] prefix as they arrive. *)
val connect_as : port:int -> Participant.t -> client Deferred.t

(** The raw RPC connection, useful for tests that exercise unusual RPC paths
    (audit log subscriptions, second clients on the same connection, etc.). *)
val connection : client -> Rpc.Connection.t

(** Submit an order via RPC. The RPC is one-way: this returns once the server
    has enqueued the request. Participant-targeted events (acceptance, fills,
    rejection) arrive on the session feed and are printed by the background
    listener set up by [connect_as]. *)
val rpc_submit : client -> Order.Request.t -> unit Deferred.t

(** Query the book via RPC. *)
val rpc_book : client -> Symbol.t -> Book.t option Deferred.t
