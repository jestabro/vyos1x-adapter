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
   ]


let () =
    let () = Arg.parse args (fun _ -> ()) usage in
(*    let path_set = List.rev !path_arg in *)
(*    let path_set = Vyos1x.Util.list_of_path !path_opt in *)
    if not !legacy then
        let token = VC.session_init () in
        print_endline token;
        let out = VC.session_status token in
        print_endline out
(*        let res_valid = VC.session_validate_path token path_set in *)
(*        let res_valid = VC.session_show_config token path_set in
        Printf.printf "%s\n" res_valid;
    *)
(*        ignore(VC.session_free token); *)
(*
    let h = Vyos1x_adapter.cstore_handle_init () in
    if not (Vyos1x_adapter.cstore_in_config_session_handle h) then
        (Vyos1x_adapter.cstore_handle_free h;
        Printf.printf "not in config session\n")
    else
        let res_valid =
        if !legacy then
            Vyos1x_adapter.legacy_validate_path h path_set
        else ""
        in
        let res_set = Vyos1x_adapter.cstore_set_path h path_set in
        Printf.printf "\nSetting [%s]\n" (String.concat " " (path_set));
        print_res (res_valid ^ "\n" ^ res_set);
        Vyos1x_adapter.cstore_handle_free h
*)

