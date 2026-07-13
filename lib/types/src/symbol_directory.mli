(** A bidirectional map between a symbol's human {!Symbol.t} name and its
    wire-visible {!Symbol_id.t}.

    Exercise 4 Phase 2. The wire and the server run entirely on [Symbol_id.t]
    (Phase 1); the directory is the one place that remembers which name each id
    stands for, so humans can still type and read tickers.

    It is built authoritatively in the server's [main] from the ordered symbol
    universe (a symbol's id is its position, matching how
    {!Matching_engine.create} assigns ids), served to clients over the
    [symbol-directory] RPC as [(name, id)] pairs, and rebuilt into a local
    mirror on each client and the monitor at connect. Resolve name->id at the
    parse edge (a human types [BUY AAPL]) and id->name at the render edge
    (printing a book or event). The wire types themselves stay bare
    [Symbol_id.t]; only consumers hold a directory. *)

open! Core

type t

(** Build a directory from the ordered symbol universe: the symbol at position
    [i] is given id [i]. This must match the list [Matching_engine.create] /
    [Exchange_server.start] is given, or ids won't line up. *)
val of_symbols : Symbol.t list -> t

(** The [(name, id)] pairs, in id order, for serving over the directory RPC. *)
val to_alist : t -> (Symbol.t * Symbol_id.t) list

(** Rebuild a directory from the pairs served by the RPC — the inverse of
    {!to_alist}. Used by a client/monitor to mirror the server's directory. *)
val of_alist : (Symbol.t * Symbol_id.t) list -> t

(** Resolve a human name to its id, or [None] if this directory has no such
    symbol. Called at the parse edge. *)
val id_of_name : t -> Symbol.t -> Symbol_id.t option

(** Resolve a wire id back to its human name, or [None] if the id is unknown to
    this directory. Called at the render edge. *)
val name_of_id : t -> Symbol_id.t -> Symbol.t option
