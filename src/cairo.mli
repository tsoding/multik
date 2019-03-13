(* TODO: the file not named appropriately *)
type t

val with_context : int -> int -> (t -> 'a) -> 'a

external save_to_png : t -> string -> unit = "multik_cairo_save_to_png"
val render : t -> Picture.t -> unit
val boundary : t -> Picture.t -> Rect.t
