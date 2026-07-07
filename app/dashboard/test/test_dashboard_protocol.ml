open! Core
open Jsip_dashboard_protocol

(* Wire-shape pin for the dashboard's client/server RPC, in the same spirit
   as [lib/gateway/test/test_rpc_shapes.ml]: both halves of the dashboard are
   built from this tree, but the digest still catches an accidental change to
   what goes over the websocket. *)
let%expect_test "recent-samples RPC" =
  print_s
    [%sexp
      (Async_rpc_kernel.Rpc.Rpc.shapes Dashboard_protocol.recent_samples_rpc
       : Async_rpc_kernel.Rpc_shapes.t)];
  [%expect
    {|
    (Rpc (query 86ba5df747eec837f0b391dd49f33f9e)
     (response 4ec881cbb99d3d7241cace2e4196fa10))
    |}]
;;
