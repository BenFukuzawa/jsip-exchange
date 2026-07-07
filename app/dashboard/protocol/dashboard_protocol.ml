open! Core
open Async_rpc_kernel
open Jsip_exchange_stats

module Exchange_connection = struct
  type t =
    | Connected
    | Disconnected
  [@@deriving sexp, bin_io, compare, equal]
end

module Recent_samples = struct
  module Response = struct
    type t =
      { exchange_connection : Exchange_connection.t
      ; snapshots : Exchange_stats.Snapshot.t list
      }
    [@@deriving sexp, bin_io, compare, equal]
  end
end

let recent_samples_rpc =
  Rpc.Rpc.create
    ~name:"recent-samples"
    ~version:1
    ~bin_query:Unit.bin_t
    ~bin_response:Recent_samples.Response.bin_t
    ~include_in_error_count:Only_on_exn
;;
