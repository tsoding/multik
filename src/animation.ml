module type Animation =
  sig
    val frames : Picture.t Flow.t
    val fps : int
    val resolution : int * int
  end

let currentAnimation : (module Animation) option ref = ref None
let getCurrentAnimation () =
  match !currentAnimation with
  | Some animation -> animation
  | None -> failwith "No animation loaded"
