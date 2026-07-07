open! Core
open! Async
open Jsip_gateway
open Jsip_dashboard_protocol

(* Snapshots retained (and served to the client) — the exchange emits one per
   second, so this is a two-minute window: enough for every chart the client
   draws (60s) plus scroll-back slack. *)
let history_capacity = 120
let reconnect_delay = Time_ns.Span.of_int_sec 1

type t =
  { history : Sample_history.t
  ; mutable exchange_connection : Dashboard_protocol.Exchange_connection.t
  }

let create () =
  { history = Sample_history.create_exn ~capacity:history_capacity
  ; exchange_connection = Disconnected
  }
;;

let recent_samples t : Dashboard_protocol.Recent_samples.Response.t =
  { exchange_connection = t.exchange_connection
  ; snapshots = Sample_history.to_list t.history
  }
;;

(* Subscribe to the exchange's stats feed and pump it into [t.history],
   forever. Any failure — exchange not up yet, connection dropped,
   subscription refused — flips the status to [Disconnected] (so the client
   can show a stale-data banner over the buffered window) and retries after
   [reconnect_delay]. *)
let start_exchange_subscription t ~exchange =
  let where_to_connect = Tcp.Where_to_connect.of_host_and_port exchange in
  let rec loop () =
    let%bind () =
      match%bind Rpc.Connection.client where_to_connect with
      | Error (_ : Exn.t) ->
        (* The exchange isn't up (yet); common at start-up, so not worth
           logging on every retry. *)
        return ()
      | Ok connection ->
        (match%bind
           Rpc.Pipe_rpc.dispatch
             Rpc_protocol.exchange_stats_rpc
             connection
             ()
         with
         | Error err | Ok (Error err) ->
           [%log.error
             "dashboard: exchange-stats subscription failed"
               (exchange : Host_and_port.t)
               (err : Error.t)];
           Rpc.Connection.close connection
         | Ok (Ok (snapshots, (_ : Rpc.Pipe_rpc.Metadata.t))) ->
           t.exchange_connection <- Connected;
           let%bind () =
             Pipe.iter_without_pushback
               snapshots
               ~f:(Sample_history.add t.history)
           in
           (* Usually the pipe ended because the connection died, but if the
              exchange only closed the pipe, don't leak the connection while
              dialing a fresh one. *)
           Rpc.Connection.close connection)
    in
    t.exchange_connection <- Disconnected;
    let%bind () = Clock_ns.after reconnect_delay in
    loop ()
  in
  don't_wait_for (loop ())
;;

(* The page shell: everything visible is rendered by the Bonsai client in
   [main.js]; the inline style just keeps the first paint dark instead of
   flashing white while the bundle loads. *)
let index_html =
  {|<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>JSIP Exchange Dashboard</title>
    <style>
      html, body { margin: 0; padding: 0; background: #0b0d10; }
    </style>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.js"></script>
  </body>
</html>
|}
;;

let respond_string = Cohttp_async.Server.respond_string
let content_type value = Cohttp.Header.of_list [ "content-type", value ]

let http_handler t ~client_js_path
  :  body:Cohttp_async.Body.t -> Socket.Address.Inet.t
  -> Cohttp_async.Request.t -> Cohttp_async.Server.response Deferred.t
  =
  fun ~body:(_ : Cohttp_async.Body.t)
    (_ : Socket.Address.Inet.t)
    (request : Cohttp_async.Request.t) ->
  match
    Cohttp.Request.meth request, Uri.path (Cohttp.Request.uri request)
  with
  | `GET, ("/" | "/index.html") ->
    respond_string ~headers:(content_type "text/html") index_html
  | `GET, "/main.js" ->
    (match%bind Sys.file_exists_exn client_js_path with
     | true ->
       Cohttp_async.Server.respond_with_file
         ~headers:(content_type "application/javascript")
         client_js_path
     | false ->
       respond_string
         ~status:`Not_found
         [%string
           "client bundle not found at %{client_js_path} — run [dune build] \
            first, or pass -client-js"])
  | `GET, "/status.sexp" ->
    (* The RPC response as a sexp, so the snapshot feed can be checked with
       [curl] before any browser is involved. *)
    respond_string
      ~headers:(content_type "text/plain")
      (Sexp.to_string_hum
         [%sexp
           (recent_samples t : Dashboard_protocol.Recent_samples.Response.t)])
  | _ -> respond_string ~status:`Not_found "not found"
;;

let implementations t =
  Rpc.Implementations.create_exn
    ~implementations:
      [ Rpc.Rpc.implement'
          Dashboard_protocol.recent_samples_rpc
          (fun () () -> recent_samples t)
      ]
    ~on_unknown_rpc:`Close_connection
    ~on_exception:Log_on_background_exn
;;

(* Accept every websocket request regardless of its [Origin] header. The
   default policy ([Header.origin_and_host_match]) is a CSRF guard that
   rejects a websocket whose [Origin] doesn't match the request [Host] —
   which is exactly what happens when this dashboard is reached through a
   port-forward or reverse proxy (SSH [-L], VS Code port forwarding, an
   EC2 tunnel): the browser's [Origin] points at the proxy while [Host]
   gets rewritten to localhost, and the handshake 403s even though the
   page's HTML loaded fine. This is a local operator tool holding no
   secrets, so accepting all origins is the right trade; a production
   deployment would validate against an allowlist instead. *)
let allow_all_requests
  (_ : Socket.Address.Inet.t)
  (_ :
    (Cohttp.Header.t * [ `is_websocket_request of bool ])
      Rpc_websocket.Rpc.Connection_source.t)
  =
  Deferred.Or_error.return ()
;;

let serve t ~port ~client_js_path =
  Rpc_websocket.Rpc.serve
    ~where_to_listen:(Tcp.Where_to_listen.of_port port)
    ~implementations:(implementations t)
    ~initial_connection_state:
      (fun
        ()
        (_ : Rpc_websocket.Rpc.Connection_initiated_from.t)
        (_ : Socket.Address.Inet.t)
        (_ : Rpc.Connection.t)
      -> ())
    ~http_handler:(fun () -> http_handler t ~client_js_path)
    ~should_process_request:allow_all_requests
    ()
;;

(* When run out of the build tree (the normal [dune exec] workflow), the
   compiled client bundle sits at a fixed spot relative to this binary:
   _build/default/app/dashboard/[{server/bin/main.exe,client/bin/main.bc.js}] *)
let default_client_js_path () =
  Filename.dirname Sys_unix.executable_name ^/ "../../client/bin/main.bc.js"
;;

let main ~port ~exchange ~client_js_path () =
  let t = create () in
  start_exchange_subscription t ~exchange;
  let%bind (_ : (Socket.Address.Inet.t, int) Cohttp_async.Server.t) =
    serve t ~port ~client_js_path
  in
  print_endline [%string "[dashboard] serving http://localhost:%{port#Int}"];
  print_endline
    [%string
      "[dashboard] streaming stats from exchange at \
       %{exchange#Host_and_port}"];
  Deferred.never ()
;;

let command =
  Command.async
    ~summary:
      "Web dashboard for JSIP exchange runtime health: subscribes to the \
       exchange's stats feed and serves a browser UI showing memory, \
       submit/cancel latency percentiles, and subscriber-pipe occupancy."
    (let%map_open.Command port =
       flag
         "-port"
         (optional_with_default 8080 int)
         ~doc:"PORT http port to serve the dashboard on (default 8080)"
     and exchange_host =
       flag
         "-exchange-host"
         (optional_with_default "localhost" string)
         ~doc:"HOST exchange server hostname (default localhost)"
     and exchange_port =
       flag
         "-exchange-port"
         (optional_with_default 12345 int)
         ~doc:"PORT exchange server port (default 12345)"
     and client_js_path =
       flag
         "-client-js"
         (optional string)
         ~doc:
           "PATH compiled dashboard client bundle (default: main.bc.js from \
            this binary's build tree)"
     in
     fun () ->
       let exchange =
         { Host_and_port.host = exchange_host; port = exchange_port }
       in
       let client_js_path =
         Option.value client_js_path ~default:(default_client_js_path ())
       in
       main ~port ~exchange ~client_js_path ())
    ~behave_nicely_in_pipeline:false
;;
