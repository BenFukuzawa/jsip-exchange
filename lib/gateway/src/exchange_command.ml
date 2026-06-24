open! Core
open Jsip_types
(* open Async_log_kernel.Ppx_log_syntax *)

module Verb = struct
  type t =
    | Buy
    | Sell
    | Book
    | Subscribe
  [@@deriving string ~case_insensitive]
end

type t =
  | Submit of Order.Request.t
  | Book of Symbol.t
  | Subscribe of Symbol.t
[@@deriving sexp_of]

(* Default participant when no "as <name>" is specified in the command.
   [parse_command_with_default_participant] overrides this with the
   caller-supplied default. *)

let default_p = Participant.of_string "anonymous"

let parse ?default_participant input =
  let open Result.Let_syntax in
  let input = String.strip input in
  if String.is_empty input
  then Or_error.error_string "empty command"
  else (
    let parts =
      String.split input ~on:' ' |> List.filter ~f:(Fn.non String.is_empty)
    in
    let%bind first_word, rest =
      match parts with
      | [] -> Or_error.error_string "empty command"
      | first_word :: rest ->
        (try Ok ((Verb.of_string first_word : Verb.t), rest) with
         | _ ->
           Or_error.error_string
             [%string
               "unknown command: %{first_word} (expected BUY, SELL, BOOK, \
                or SUBSCRIBE)"])
    in
    match first_word with
    | Buy | Sell ->
      let%bind side =
        match first_word with
        | Buy -> Ok Side.Buy
        | Sell -> Ok Side.Sell
        | _ -> Or_error.error_s [%message "invalid symbol:"]
      in
      let%bind symbol_str, size_str, price_str, rest =
        match rest with
        | symbol_str :: size_str :: price_str :: rest ->
          Ok (symbol_str, size_str, price_str, rest)
        | _ ->
          Or_error.error_string
            [%string
              "expected: BUY|SELL <symbol> <size> <price> [DAY|IOC] [as \
               <name>]"]
      in
      let%bind size =
        match Int.of_string_opt size_str with
        | Some n when n > 0 -> Ok n
        | Some _ -> Or_error.error_string "size must be positive"
        | None -> Or_error.error_string [%string "invalid size: %{size_str}"]
      in
      let%bind price =
        try Ok (Price.of_string price_str) with
        | exn ->
          let exn_str = Exn.to_string exn in
          Or_error.error_string
            [%string "invalid price: %{price_str}\nexception: %{exn_str}"]
      in
      let%bind symbol =
        try Ok (Symbol.of_string symbol_str) with
        | exn ->
          let exn_str = Exn.to_string exn in
          Or_error.error_s
            [%message
              [%string
                "invalid symbol: %{symbol_str}\nexception: %{exn_str}"]]
      in
      let%bind time_in_force, rest =
        match rest with
        | [] -> Ok (Time_in_force.Day, [])
        | tif_str :: rest' ->
          if String.Caseless.equal tif_str "as"
          then Ok (Time_in_force.Day, rest)
          else (
            match Time_in_force.of_string tif_str with
            | tif -> Ok (tif, rest')
            | exception _ ->
              Or_error.error_string
                [%string
                  "unknown time-in-force: %{tif_str} (expected DAY or IOC)"])
      in
      let%bind participant =
        match rest with
        | "as" :: name :: _ | "AS" :: name :: _ ->
          Ok (Participant.of_string name)
        | [] ->
          (match default_participant with
           | None -> Ok default_p
           | Some x -> Ok x)
        | _ ->
          let trailing = String.concat ~sep:" " rest in
          let error_msg = trailing in
          Or_error.error_s [%message error_msg]
      in
      Ok
        (Submit
           { symbol
           ; participant
           ; side
           ; price
           ; size = Size.of_int size
           ; time_in_force
           }
         : t)
    | Book | Subscribe ->
      (match rest with
       | [] ->
         Or_error.error_s [%message "expected: BOOK|SUBSCRIBE <symbol>"]
       | symbol_str :: _ ->
         let symbol = Symbol.of_string (String.uppercase symbol_str) in
         (match first_word with
          | Book -> Ok (Book symbol)
          | Subscribe -> Ok (Subscribe symbol)
          | _ -> Or_error.error_s [%message "invalid symbol:"])))
;;
(* | other -> let unk_command = Verb.to_string first_word in let error_msg =
   [%string "unknown command: %{unk_command} (expected BUY or SELL)"] in
   Or_error.error_s [%message error_msg] *)
