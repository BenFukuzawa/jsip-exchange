open! Core

type t [@@deriving sexp, bin_io, compare, equal, hash]

val to_int : t -> int
val of_int : int -> t
