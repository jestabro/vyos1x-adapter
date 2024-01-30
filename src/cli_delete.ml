(* CLI delete path
 *)

let print_res res =
    if res <> "" then
        Printf.printf "%s\n" res
    else
        Printf.printf "no error\n"

let path_arg = ref []
let args = []
let usage = Printf.sprintf "Usage: %s <path>" Sys.argv.(0)

let () = if Array.length Sys.argv = 1 then (Arg.usage args usage; exit 1)
let () = Arg.parse args (fun s -> path_arg := s::!path_arg) usage

let () =
    let path_del = List.rev !path_arg in
    let h = Vyos1x_adapter.handle_init () in
    if not (Vyos1x_adapter.in_config_session_handle h) then
        (Vyos1x_adapter.handle_free h;
        Printf.printf "not in config session\n")
    else
        let res_del = Vyos1x_adapter.delete_path h path_del (List.length path_del) in
        Printf.printf "deleting [%s]\n" (String.concat " " (path_del));
        print_res res_del;
        Vyos1x_adapter.handle_free h

