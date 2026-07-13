(** A read-only snapshot of an order book.

    Contains the symbol, all resting price levels on each side (aggregated by
    price), and the BBO. *)

open! Core

type t =
  { symbol : Symbol_id.t
  ; bids : Level.t list
  ; asks : Level.t list
  ; bbo : Bbo.t
  }
[@@deriving sexp, bin_io]

(** Renders the book as multi-line text. The header symbol is the wire
    {!Symbol_id.t} by default; pass [?directory] to show the ticker name
    instead (Exercise 4). *)
val to_string : ?directory:Symbol_directory.t -> t -> string
