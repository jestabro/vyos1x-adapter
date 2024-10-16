(* CLI set path
 *)

open Client

module VC = Vyconf_client_api

let print_res res =
    if res <> "" then
        Printf.printf "%s\n" res
    else
        Printf.printf "no error\n"

let legacy = ref false
let no_set = ref false
(*let path_arg = ref []
let args = []
let usage = Printf.sprintf "Usage: %s <path>" Sys.argv.(0)
*)
let path_opt = ref ""

(*
let () = if Array.length Sys.argv = 1 then (Arg.usage args usage; exit 1)
let () = Arg.parse args (fun s -> path_arg := s::!path_arg) usage
*)
(* Command line arguments *)
let usage = "Usage: " ^ Sys.argv.(0) ^ " [options]"

let args = [
    ("--path", Arg.String (fun s -> path_opt := s), "<string> Configuration path");
    ("--legacy", Arg.Unit (fun _ -> legacy := true), "Use legacy validation");
    ("--no-set", Arg.Unit (fun _ -> no_set := true), "Do not set path");
   ]

let get_sockname =
    "/var/run/vyconfd.sock"

let run socket path_list =
    let%lwt token = VC.session_init socket in
    match token with
    | Error e -> Error e |> Lwt.return
    | Ok token ->
        let%lwt out = VC.session_validate_path socket token path_list
        in
        let%lwt _ = VC.session_free socket token in
        Lwt.return out
(*        match out with
        | Error e -> Lwt.return ("Failed to validate path: " ^ e)
        | Ok _ -> Lwt.return ("Appeared to work")
*)
let validate_path path =
    let socket = get_sockname in
(*    let path_list = Vyos1x.Util.list_of_path path in *)
    let out = Lwt_main.run (run socket path) in
    match out with
    | Ok res ->
        print_endline res; ""
    | Error e ->
        print_endline e; e


let () =
    let () = Arg.parse args (fun _ -> ()) usage in
(*    let path_set = List.rev !path_arg in *)
(*    let path_set = Vyos1x.Util.list_of_path !path_opt in *)
    let path_list = Vyos1x.Util.list_of_path !path_opt in
    let valid =
        if not !legacy then validate_path path_list
        else ""
    in
    if !legacy || not !no_set then
        let h = Vyos1x_adapter.cstore_handle_init () in
        if not (Vyos1x_adapter.cstore_in_config_session_handle h) then
            (Vyos1x_adapter.cstore_handle_free h;
            Printf.printf "not in config session\n")
        else
            let res_valid =
            if !legacy then
                Vyos1x_adapter.legacy_validate_path h path_list
            else ""
            in
            let res_set =
                if not !no_set && valid = "" && res_valid = "" then
                    Vyos1x_adapter.cstore_set_path h path_list
                else ""
            in
            Printf.printf "\nSetting [%s]\n" (String.concat " " (path_list));
            print_res (res_valid ^ "\n" ^ res_set);
            Vyos1x_adapter.cstore_handle_free h
