let legacy = ref false
let no_set = ref false
let valid = ref false
let output = ref ""
let path_opt = ref []

let usage = "Usage: " ^ Sys.argv.(0) ^ " [options]"

let read_path p =
    path_opt := p::!path_opt

let speclist = [
    ("--legacy", Arg.Unit (fun _ -> legacy := true), "Use legacy validation");
    ("--no-set", Arg.Unit (fun _ -> no_set := true), "Do not set path");
   ]

let () =
    let () = Arg.parse speclist read_path usage in
    let path_list = List.rev !path_opt in
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
            Vyos1x_adapter.vyconf_validate_path path_list
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
                Vyos1x_adapter.cstore_set_path h path_list
            | None -> "missing session handle"
        else ""
    in
    let output = (snd valid) ^ "\n\n" ^ res in
    let () =
        match handle with
        | Some h -> Vyos1x_adapter.cstore_handle_free h
        | None -> ()
    in
    print_endline output
