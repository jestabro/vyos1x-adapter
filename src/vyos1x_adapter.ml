external handle_init: unit -> int = "handle_init"
external handle_free: int -> unit = "handle_free"
external in_config_session_handle: int -> bool = "in_config_session_handle"
external in_config_session: unit -> bool = "in_config_session"
external set_path: int -> string list -> int -> string = "set_path"
external delete_path: int -> string list -> int -> string = "delete_path"

open Vyos1x

module CT = Config_tree
module CD = Config_diff

let update_data (CD.Diff_cstore data) m =
    CD.Diff_cstore { data with out = m; }

let test_if_session () =
    let left = CT.make "left" in
    let right = CT.make "right" in
    let h = handle_init () in
    let diff_cstore = CD.make_diff_cstore left right h in
    let in_session = in_config_session_handle h in
    let msg = match in_session with
        | true -> "in config session"
        | false -> "not in config session"
    in
    let res = update_data diff_cstore msg in
    let result = CD.eval_result res in
    handle_free h;
    result.out
