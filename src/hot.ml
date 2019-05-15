IFDEF PROFILE THEN
module Hot =
  struct
    let load (module A: Animation.T): unit = ()
  end

INCLUDE "./samples/swirl.ml"

let get_current () = (module Swirl: Animation.T)
let loadfile(filepath: string): unit = ()
ELSE
(* TODO(#55): there is no default "No Animation Loaded" animation *)
let current : (module Animation.T) option ref = ref None

let get_current () =
  match !current with
  | Some animation -> animation
  | None -> failwith "No animation loaded"

let load (module A: Animation.T): unit =
  current := Some (module A: Animation.T)

let loadfile(filepath: string): unit =
  Dynlink.loadfile(filepath)

ENDIF
