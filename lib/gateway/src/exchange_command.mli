open! Core
open Jsip_types

module Verb : sig
  type t =
    | Buy
    | Sell
    | Book
    | Subscribe
  [@@deriving string]
end

type t =
  | Submit of Order.Request.t
  | Book of Symbol_id.t
  | Subscribe of Symbol_id.t
[@@deriving sexp_of]

val parse : ?default_participant:Participant.t -> string -> t Or_error.t
