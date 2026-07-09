open! Core
open Jsip_types

type t =
  { ids : Participant_id.t Participant.Table.t (* name -> id *)
  ; names : Participant.t Dynarray.t (* id -> name; the id is the index *)
  }

let create () =
  { ids = Participant.Table.create (); names = Dynarray.create () }
;;

let intern t participant =
  (* TODO(human): get-or-create interning. *)
  ignore (t.ids, participant);
  failwith "TODO: implement Participant_registry.intern"
;;

(* An id is always the index its name was appended at, so resolution is a
   direct array read (raises if the id is out of range). *)
let name t (id : Participant_id.t) = Dynarray.get t.names (id :> int)
