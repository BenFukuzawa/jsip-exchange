(* open! Core open Jsip_types open Async_log_kernel.Ppx_log_syntax

   type verb = | Buy | Sell | Book | Subscribe
   [@@deriving string ~case_insensitive]

   type t = | Submit of Order.Request.t | Book of Symbol.t | Subscribe of
   Symbol.t [@@deriving sexp_of] *)
