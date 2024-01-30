val handle_init : unit -> int
val handle_free : int -> unit
val in_config_session_handle : int -> bool
val in_config_session : unit -> bool
val set_path : int -> string list -> int -> string
val delete_path : int -> string list -> int -> string

val test_if_session : unit -> string
