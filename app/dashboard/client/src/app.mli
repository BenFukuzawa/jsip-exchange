(** The dashboard's Bonsai layer.

    Everything stateful lives here and nowhere else: the once-per-second
    [Rpc_effect.Rpc.poll] of the dashboard server's [recent-samples] RPC, and
    one hover state per chart. Each response is folded through the pure
    {!View_model.create}; the page then renders with {!Panes} and {!Chart}.
    Mirrors the [app/monitor] split, where [Term_app] wires a pure
    [Controller] into Bonsai. *)

open! Core
open Bonsai_web

val app : local_ Bonsai.graph -> Vdom.Node.t Bonsai.t
