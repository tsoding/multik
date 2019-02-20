open Animation

let empty_animation_frame =
  Picture.Color
    ( Color.red
    (* TODO(#22): "No Animation" sign is not rendered at the center of the screen *)
    , Picture.Text ((0.0, 90.0), Font.make "Sans" 50.0, "No Animation")
    )

(* TODO(#40): if the animation is infinite the rendering will be infinite *)
let render (animation_path: string) (dirpath: string): unit =
  Dynlink.loadfile(animation_path);
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

let preview (animation_path: string) =
  let rec loop (delta_time: float) (frames: Picture.t Flow.t): unit =
    if not (Console.should_quit ())
    then (if (Watcher.is_file_modified ())
          then (print_endline "reloading";
                Dynlink.loadfile(animation_path);
                let module Reload = (val getCurrentAnimation () : Animation) in
                if Flow.is_nil Reload.frames
                then loop delta_time Flow.nil
                else Reload.frames |> Flow.cycle |> loop delta_time)
          else (let frame_begin = Sys.time () in
                match Flow.uncons frames with
                | Some (frame, rest_frames) ->
                   frame |> Console.renderPicture;
                   Console.present ();
                   let frame_work = Sys.time () -. frame_begin in
                   (*
                    * TODO(#23): The animation is replayed slower than it supposed to be
                    *   1. Create animation with 100 frames and 30 fps
                    *   2. Expected animation should last ~3 seconds
                    *   3. Observed animation lasts >6 seconds
                    *)
                   (delta_time -. frame_work) |> max 0.0 |> Thread.delay;
                   loop delta_time rest_frames
                | None -> [empty_animation_frame]
                          |> Flow.of_list
                          |> Flow.cycle
                          |> loop delta_time))
    else ()
  in
    Dynlink.loadfile(animation_path);
    let module A = (val getCurrentAnimation () : Animation) in
    let (width, height) = A.resolution in
    let delta_time = 1.0 /. (float_of_int A.fps) in
    Console.init width height;
    Watcher.init animation_path;
    if Flow.is_nil A.frames
    then loop delta_time Flow.nil
    else A.frames |> Flow.cycle |> loop delta_time;
    Watcher.free ();
    Console.free ()

let () =
  match Sys.argv |> Array.to_list with
  | _ :: "preview" :: animation_path :: _ ->
     preview animation_path
  | name :: "preview" :: _ ->
     Printf.fprintf stderr "Using %s preview <animation-path>" name
  | _ :: "render" :: animation_path :: dirpath :: _ ->
     render animation_path dirpath
  | name :: "render" :: _ ->
     Printf.fprintf stderr "Using: %s render <animation-path> <dirpath>" name
  | name :: _ -> Printf.fprintf stderr "Using: %s <preview|render>" name
  | _ -> Printf.fprintf stderr "Using: <program> <preview|render>"
