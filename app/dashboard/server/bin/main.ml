(** [jsip-dashboard]: serves the browser dashboard for a running JSIP
    exchange. See {!Jsip_dashboard_server.Server} for what it does; see
    [doc/exercises-part-3.md] section 2 for why it exists. *)

let () = Command_unix.run Jsip_dashboard_server.Server.command
