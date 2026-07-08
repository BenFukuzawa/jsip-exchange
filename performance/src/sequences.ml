open! Core

module List_seq = struct
  (* TODO: replace the definition of type t and the implementations of
     create, set, and get *)
  type t = int list ref

  let create () = ref []

  let set t ~key ~data =
    let len = List.length !t in
    if key = len
    then t := !t @ [ data ]
    else if key >= 0 && key < len
    then t := List.mapi !t ~f:(fun i x -> if i = key then data else x)
    else
      raise_s
        [%message
          "Sequences.set: index out of range" (key : int) (len : int)]
  ;;

  let get t key = List.nth !t key
end

module Dynarray_seq = struct
  (* TODO: replace the definition of type t and the implementations of
     create, set, and get *)
  type t = int Dynarray.t

  let create () = Dynarray.create ()

  let set t ~key ~data =
    let len = Dynarray.length t in
    if key = len
    then Dynarray.add_last t data
    else if key < len && key >= 0
    then Dynarray.set t key data
    else
      raise_s
        [%message
          "Dynarray_seq.set: index out of range" (key : int) (len : int)]
  ;;

  let get t key =
    match key >= 0 && key < Dynarray.length t with
    | true -> Some (Dynarray.get t key)
    | false -> None
  ;;
end
