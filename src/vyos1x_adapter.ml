open Ctypes
open Foreign

let libvyatta = Dl.dlopen ~flags:[Dl.RTLD_LAZY] ~filename:"libvyatta-cfg.so"

let cstore_init = foreign ~from:libvyatta "vy_cstore_init" (void @-> returning uint64_t)
let cstore_free = foreign ~from:libvyatta "vy_cstore_free" (uint64_t @-> returning void)
let in_session = foreign ~from:libvyatta "vy_in_session" (uint64_t @-> returning int)
let vy_set_path = foreign ~from:libvyatta "vy_set_path" (uint64_t @-> (ptr void) @-> size_t @-> returning string)
let vy_del_path = foreign ~from:libvyatta "vy_delete_path" (uint64_t @-> (ptr void) @-> size_t @-> returning string)

let handle_init () = Unsigned.UInt64.to_int (cstore_init ())
let handle_free h = cstore_free (Unsigned.UInt64.of_int h)
let in_config_session_handle h = in_session (Unsigned.UInt64.of_int h) = 1
let in_config_session () = in_config_session_handle (handle_init ())
let set_path handle path len =
    let arr = CArray.of_list string path in
    vy_set_path (Unsigned.UInt64.of_int handle) (to_voidp (CArray.start arr)) (Unsigned.Size_t.of_int len)

let delete_path handle path len =
    let arr = CArray.of_list string path in
    vy_del_path (Unsigned.UInt64.of_int handle) (to_voidp (CArray.start arr)) (Unsigned.Size_t.of_int len)

let set_path_reversed handle path len =
    let path = List.rev path in
    set_path handle path len

let delete_path_reversed handle path len =
    let path = List.rev path in
    delete_path handle path len

open Vyos1x

module CT = Config_tree
module CD = Config_diff

module ValueSet = Set.Make(String)

let add_value handle acc out v =
    let acc = v :: acc in
    out ^ (set_path_reversed handle acc (List.length acc))

let add_values handle acc out vs =
    match vs with
    | [] -> out ^ (set_path_reversed handle acc (List.length acc))
    | _ -> List.fold_left (add_value handle acc) out vs

let rec add_path handle acc out (node : CT.t) =
    let acc = (Vytree.name_of_node node) :: acc in
    let children = Vytree.children_of_node node in
    match children with
    | [] -> let data = Vytree.data_of_node node in
            let values = data.values in
            add_values handle acc out values
    | _  -> List.fold_left (add_path handle acc) out children

let del_value handle acc out v =
    let acc = v :: acc in
    out ^ (delete_path_reversed handle acc (List.length acc))

let del_values handle acc out vs =
    match vs with
    | [] -> out ^ (delete_path_reversed handle acc (List.length acc))
    | _ -> List.fold_left (del_value handle acc) out vs

let del_path handle path out =
    out ^ (delete_path handle path (List.length path))

(*
let update_data (CD.Diff_cstore data) m =
    CD.Diff_cstore { data with out = m; }
*)

let cstore_diff ?recurse:_ (path : string list) (CD.Diff_cstore res) (m : CD.change) =
    let handle = res.handle in
    match m with
    | Added -> let node = Vytree.get res.right path in
               let acc = List.tl (List.rev path) in
               CD.Diff_cstore { res with out = add_path handle acc res.out node }
    | Subtracted -> CD.Diff_cstore { res with out = del_path handle path res.out }
    | Unchanged -> CD.Diff_cstore (res)
    | Updated v ->
            let ov = CT.get_values res.left path in
            let acc = List.rev path in
            match ov, v with
            | [x], [y] -> let out = del_value handle acc res.out x in
                          let out = add_value handle acc out y in
                          CD.Diff_cstore { res with out = out }
            | _, _ -> let ov_set = ValueSet.of_list ov in
                      let v_set = ValueSet.of_list v in
                      let sub_vals = ValueSet.elements (ValueSet.diff ov_set v_set) in
                      let add_vals = ValueSet.elements (ValueSet.diff v_set ov_set) in
                      let out = del_values handle acc res.out sub_vals in
                      let out = add_values handle acc out add_vals in
                      CD.Diff_cstore { res with out = out }

let load_config left right =
    let h = handle_init () in
    if not (in_config_session_handle h) then
        (handle_free h;
        let out = "not in config session\n" in
        out)
    else
        let dcstore = CD.make_diff_cstore left right h in
        let dcstore = CD.diff [] cstore_diff dcstore (Option.some left, Option.some right) in
        let ret = CD.eval_result dcstore in
        handle_free h;
        ret.out
