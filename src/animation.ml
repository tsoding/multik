module type T =
  sig
    val frames : Picture.t Flow.t
    val fps : int
    val resolution : int * int
  end
