(* CLI set path
 *)

open Client

module VC = Vyconf_client_api

let legacy = ref false
let no_set = ref false
let valid = ref false
let output = ref ""
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

let validate_path path_list =
    let socket = get_sockname in
    let token = VC.session_init socket in
    match token with
    | Error e -> (false, e)
    | Ok token ->
        let out = VC.session_validate_path socket token path_list
        in
        let _ = VC.session_free socket token in
        match out with
        | Ok o -> (true, o)
        | Error e -> (false, e)

let () =
    let () = Arg.parse args (fun _ -> ()) usage in
    let path_list = Vyos1x.Util.list_of_path !path_opt in
    let handle =
        if !legacy || not !no_set then
            let h = Vyos1x_adapter.cstore_handle_init () in
            if not (Vyos1x_adapter.cstore_in_config_session_handle h) then
                (Vyos1x_adapter.cstore_handle_free h;
                Printf.printf "not in config session\n"; exit 1)
            else Some h
        else None
    in
    let valid =
        if not !legacy then
            validate_path path_list
        else
            begin
            let out =
                match handle with
                | Some h -> Vyos1x_adapter.legacy_validate_path h path_list
                | None -> "missing session handle"
            in
            match out with
            | "" -> (true, "")
            | _ -> (false, out)
            end
    in
    let res =
        if not !no_set && (fst valid) then
            match handle with
            | Some h ->
        (Printf.printf "\nSetting [%s]\n" (String.concat " " (path_list));
        Vyos1x_adapter.cstore_set_path h path_list)
            | None -> "missing session handle"
        else ""
    in
    let output = (snd valid) ^ "\n" ^ res in
    let () =
        match handle with
        | Some h -> Vyos1x_adapter.cstore_handle_free h
        | None -> ()
    in
    print_endline output
