(* CLI set path
 *)

module VC = Vyconf.Vyconf_client.Vyconf_client_api

let print_res res =
    if res <> "" then
        Printf.printf "%s\n" res
    else
        Printf.printf "no error\n"

let path_arg = ref []
let args = []
let usage = Printf.sprintf "Usage: %s <path>" Sys.argv.(0)

let legacy = ref false
let no_set = ref false

let () = if Array.length Sys.argv = 1 then (Arg.usage args usage; exit 1)
let () = Arg.parse args (fun s -> path_arg := s::!path_arg) usage

let args = [
  ("--legacy-validate", Arg.Bool (fun s -> legacy := s), "Use legacy validate");
  ("--no-set", Arg.Bool (fun s -> legacy := s), "Validate but do not set in cstore");
]

let () =
    let path_set = List.rev !path_arg in
    if not legacy then
        let token = VC.session_init in
        let res_valid = VC.validate_path token path in
        VC.session_free;
        Printf.printf "%s\n", res_valid;
    if legacy or not no_set then
        let h = Vyos1x_adapter.cstore_handle_init () in
        if not (Vyos1x_adapter.cstore_in_config_session_handle h) then
            (Vyos1x_adapter.cstore_handle_free h;
            Printf.printf "not in config session\n"; exit 1);
        let res_valid =
            if legacy then
                Vyos1x_adapter.cstore_validate_path h path_set
            else ""
        in
        let res_set =
            if not no_set then
                Printf.printf "\nSetting [%s]\n" (String.concat " " (path_set));
                Vyos1x_adapter.cstore_set_path h path_set
            else ""
        in
        Vyos1x_adapter.cstore_handle_free h;
        if res_valid <> "" then Printf.print "%s\n" res_valid;
        if res_valid <> "" then Printf.print "%s\n" res_set;

