open! Core

type verb =
  | Buy
  | Sell
  | Book
  | Subscribe
[@@deriving string ~case_insensitive]

let to_string verb = verb
let of_string verb = verb

type t =
  | Submit of Order.Request.t
  | Book of Symbol.t
  | Subscribe of Symbol.t
