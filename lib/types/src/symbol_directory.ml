open! Core

(* Two indexes over the same symbol universe: [ids] answers name->id (parse
   edge), [names] answers id->name (render edge), with the id being the
   dynarray position. Both are filled together in [of_symbols] and kept in
   step, so [Dynarray.length names] equals [Hashtbl.length ids]. *)
type t =
  { ids : Symbol_id.t Symbol.Table.t
  ; names : Symbol.t Dynarray.t (* id -> name; the id is the index *)
  }

let of_symbols (symbols : Symbol.t list) : t =
  let dir_t = { ids = Symbol.Table.create (); names = Dynarray.create () } in
  List.iteri symbols ~f:(fun i name ->
    Hashtbl.set dir_t.ids ~key:name ~data:(Symbol_id.of_int i);
    Dynarray.add_last dir_t.names name);
  dir_t
;;

let to_alist t : (Symbol.t * Symbol_id.t) list =
  Dynarray.to_list t.names
  |> List.mapi ~f:(fun i name -> name, Symbol_id.of_int i)
;;

let of_alist (alist : (Symbol.t * Symbol_id.t) list) : t =
  of_symbols (List.map alist ~f:fst)
;;

let id_of_name t (symbol : Symbol.t) : Symbol_id.t option =
  Hashtbl.find t.ids symbol
;;

let name_of_id t (symbol_id : Symbol_id.t) : Symbol.t option =
  let id = Symbol_id.to_int symbol_id in
  match id >= 0 && id < Dynarray.length t.names with
  | false -> None
  | true -> Some (Dynarray.get t.names id)
;;
