(** A server-local integer id for a participant, interned from the
    participant's name at login.

    Unlike the id types in [lib/types], this deliberately has NO [bin_io]: it
    never crosses the wire, so it lives here in the gateway and is resolved
    back to a {!Jsip_types.Participant.t} name at every server edge. The
    [private int] lets callers read an id as an array index ([(id :> int)])
    without being able to fabricate one. *)

open! Core

type t = private int [@@deriving sexp_of, compare, equal, hash]

include Comparable.S_plain with type t := t
include Hashable.S_plain with type t := t

(** Mint an id from a raw int. Only the participant registry (which owns id
    allocation) should call this. *)
val of_int : int -> t
