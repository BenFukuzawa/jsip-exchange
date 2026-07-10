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
  match Hashtbl.find t.ids participant with
  | Some id -> id
  | None ->
    let id = Participant_id.of_int (Dynarray.length t.names) in
    Hashtbl.set t.ids ~key:participant ~data:id;
    Dynarray.add_last t.names participant;
    id
;;

(* An id is always the index its name was appended at, so resolution is a
   direct array read (raises if the id is out of range). *)
let name t (id : Participant_id.t) = Dynarray.get t.names (id :> int)
