open! Core

type t =
  { symbol : Symbol_id.t
  ; bids : Level.t list
  ; asks : Level.t list
  ; bbo : Bbo.t
  }
[@@deriving sexp, bin_io]

(* Render a wire [Symbol_id.t] for display: id by default, ticker name when a
   [directory] is supplied (Exercise 4), falling back to the id if unknown. *)
let symbol_to_display ?directory symbol =
  match directory with
  | None -> Symbol_id.to_string symbol
  | Some d ->
    Symbol_directory.name_of_id d symbol
    |> Option.map ~f:Symbol.to_string
    |> Option.value ~default:(Symbol_id.to_string symbol)
;;

let to_string ?directory { symbol; bids; asks; bbo } =
  let symbol = symbol_to_display ?directory symbol in
  let format_side label levels =
    match levels with
    | [] -> [%string "  %{label}: (empty)"]
    | _ ->
      let lines =
        List.map levels ~f:(fun level -> [%string "    %{level#Level}"])
        |> String.concat ~sep:"\n"
      in
      [%string "  %{label}:\n%{lines}"]
  in
  String.concat
    ~sep:"\n"
    [ [%string "=== %{symbol} ==="]
    ; format_side "BIDS" bids
    ; format_side "ASKS" asks
    ; [%string "  BBO: %{bbo#Bbo}"]
    ]
;;
