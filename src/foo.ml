(* TODO: rename foo -> console *)

external console_init: int -> int -> unit = "console_init"
external console_free: unit -> unit = "console_free"
external console_should_quit: unit -> bool = "console_should_quit"
external console_render: unit -> unit = "console_render"
