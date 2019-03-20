open Picture

(* TODO(#35): The project mixes up camel case and snake case for function names *)

external init: int -> int -> unit = "console_init"
external free: unit -> unit = "console_free"
external should_quit: unit -> bool = "console_should_quit"
external present: unit -> unit = "console_present"
external texture: unit -> SdlTexture.t = "console_texture"

let renderPicture (p: Picture.t): unit =
  Cairo.with_texture (texture ())
    (fun c ->
      Cairo.fill_chess_pattern c;
      Cairo.render c p)
