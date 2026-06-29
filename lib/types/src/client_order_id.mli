open! Core

type t [@@deriving sexp, bin_io, compare, equal, hash]

include Comparable.S with type t := t
include Hashable.S with type t := t

val to_int : t -> int
val of_int : int -> t
