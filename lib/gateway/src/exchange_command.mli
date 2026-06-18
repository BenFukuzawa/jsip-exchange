open! Core
open Jsip_types

type t [@@deriving sexp, bin_io, compare, equal, hash, string]

val parse : ?default_participant:Participant.t -> string -> t Or_error.t
