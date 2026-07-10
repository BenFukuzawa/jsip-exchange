(** A wire-visible integer id for a trading symbol.

    Exercise 4's "string at the edge, int on the wire". This is the mirror
    image of the gateway's [Participant_id]: same [private int] core, but
    where a participant id stays server-side and so has {e no} [bin_io], a
    [Symbol_id.t] rides on every order, book query, and market-data event — so
    it derives [bin_io] and lives here in [lib/types] beside the other wire
    types.

    It is a [private int]: callers may read it as an array index
    ([(id :> int)] or {!to_int}) but can only mint one through {!of_int},
    reserved for the authoritative symbol registry and for validated wire
    decoding. [lib/types] never turns an id back into a name — that happens at
    the consumer edges via the symbol directory (Phase 2). *)

open! Core

type t = private int [@@deriving sexp, bin_io, compare, equal, hash]

include Comparable.S with type t := t
include Hashable.S with type t := t

(** Renders the raw integer id. [lib/types] stays name-free; humans recover
    the symbol name from the directory at the render site. *)
val to_string : t -> string

(** Mint an id from a raw int. Only the symbol registry (which owns id
    allocation) and validated wire decoding should call this. *)
val of_int : int -> t

(** The underlying int, e.g. to index the engine's book array. *)
val to_int : t -> int
