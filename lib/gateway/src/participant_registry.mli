(** Server-global registry that interns participant names to
    {!Participant_id.t}.

    Shared across all connections and append-only: an id is minted the first
    time a name logs in and stays valid for the life of the exchange, so a
    participant keeps the same id across reconnects. This is deliberately
    distinct from the dispatcher's [active_sessions], which tracks who is
    *currently* connected and is pruned on disconnect.

    Like {!Participant_id}, this is gateway-local and never crosses the wire. *)

open! Core
open Jsip_types

type t

(** An empty registry. *)
val create : unit -> t

(** Return the id for [participant], minting (and remembering) a fresh one the
    first time the name is seen. Idempotent: the same name always maps to the
    same id. Called at the login edge. *)
val intern : t -> Participant.t -> Participant_id.t

(** The name an id was interned from. Called at the server's edges to resolve
    an id back to a human-readable name. Raises if [id] was not minted by this
    registry. *)
val name : t -> Participant_id.t -> Participant.t
