open Vyos1x

val handle_init : unit -> int
val handle_free : int -> unit
val in_config_session_handle : int -> bool
val in_config_session : unit -> bool
val set_path : int -> string list -> int -> string
val delete_path : int -> string list -> int -> string
val set_path_reversed : int -> string list -> int -> string
val delete_path_reversed : int -> string list -> int -> string

val load_config : Config_tree.t -> Config_tree.t -> string
