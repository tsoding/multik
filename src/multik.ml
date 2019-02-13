open Animation

let empty_animation_frame =
  Picture.Color
    ( Color.red
    (* TODO(#22): "No Animation" sign is not rendered at the center of the screen *)
    , Picture.Text ((0.0, 90.0), 50.0, "No Animation")
    )

(* TODO(#40): if the animation is infinite the rendering will be infinite *)
let render (dirpath: string): unit =
  let module A = (val getCurrentAnimation () : Animation) in
  if not (Sys.file_exists dirpath) then Unix.mkdir dirpath 0o755;
  A.frames
  |> Flow.zip (Flow.from 0)
  |> Flow.iter (fun (index, picture) ->
       let filename = dirpath
                      ^ Filename.dir_sep
                      ^ string_of_int index
                      ^ ".png"
       in Console.savePicture A.resolution filename picture)

let preview () =
  let rec loop (delta_time: float) (frames: Picture.t Flow.t): unit =
    let frame_begin = Sys.time () in
    if not (Console.should_quit ())
    then
      match Flow.uncons frames with
      | Some (frame, rest_frames) ->
         begin
           frame |> Console.renderPicture;
           Console.present ();
           let frame_work = Sys.time () -. frame_begin in
           begin
             (*
              * TODO(#23): The animation is replayed slower than it supposed to be
              *   1. Create animation with 100 frames and 30 fps
              *   2. Expected animation should last ~3 seconds
              *   3. Observed animation lasts >6 seconds
              *)
             (delta_time -. frame_work) |> max 0.0 |> Thread.delay;
             loop delta_time rest_frames
           end
         end
      | None -> [empty_animation_frame]
                |> Flow.of_list
                |> Flow.cycle
                |> loop delta_time
    else ()
  in
    let module A = (val getCurrentAnimation () : Animation) in
    let (width, height) = A.resolution in
    let delta_time = 1.0 /. (float_of_int A.fps) in
    Console.init width height;
    if Flow.is_nil A.frames
    then loop delta_time Flow.nil
    else A.frames |> Flow.cycle |> loop delta_time;
    Console.free ()

let run () =
  match Sys.argv |> Array.to_list with
  | _ :: "preview" :: _ ->
     preview ()
  | _ :: "render" :: dirpath :: _ ->
     render dirpath
  | name :: "render" :: _ ->
     Printf.fprintf stderr "Using: %s render <dirpath>" name
  | name :: _ -> Printf.fprintf stderr "Using: %s <preview|render>" name
  | _ -> Printf.fprintf stderr "Using: <program> <preview|render>"
