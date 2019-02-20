module type T =
  sig
    val frames : Picture.t Flow.t
    val fps : int
    val resolution : int * int
  end

(* TODO: there is no default "No Animation Loaded" animation *)
let current : (module T) option ref = ref None

let get_current () =
  match !current with
  | Some animation -> animation
  | None -> failwith "No animation loaded"

let load (module A: T): unit =
  current := Some (module A: T)
