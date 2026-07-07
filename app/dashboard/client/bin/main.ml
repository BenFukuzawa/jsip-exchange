(** Entry point for the dashboard's browser bundle: mounts
    {!Jsip_dashboard_client.App.app} onto the [#app] element of the page
    served by [app/dashboard/server]. Compiled to [main.bc.js] by
    js_of_ocaml; never runs natively. *)

let () = Bonsai_web.Start.start Jsip_dashboard_client.App.app
