type t

val with_context : int -> int -> (t -> 'a) -> 'a
val with_texture : SdlTexture.t -> (t -> 'a) -> 'a

external save_to_png : t -> string -> unit = "multik_cairo_save_to_png"
val render : t -> Picture.t -> unit
external fill_chess_pattern : t -> unit = "multik_fill_chess_pattern"
