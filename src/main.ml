let empty_animation_frame (screen_width, screen_height) =
  let label_text = "<no animation>" in
  let label_at position =
    Picture.Text (position, Font.make "Sans" 50.0, label_text)
  in
  Picture.sizeOf
    (label_at (0.0, 0.0))
    (fun (_, _, label_width, label_height) ->
      Picture.Color
        ( Color.red
        , Picture.Text
            (((float_of_int screen_width) *. 0.5 -. label_width *. 0.5,
              (float_of_int screen_height) *. 0.5 -. label_height *. 0.5),
             Font.make "Sans" 50.0, label_text)))

let compose_video_file (dirpath: string) (fps: int) (output_filename: string): Unix.process_status =
  Printf.sprintf "ffmpeg -y -framerate %d -i %s/%%d.png %s" fps dirpath output_filename
  |> Unix.open_process_in
  |> Unix.close_process_in

let temp_dir (prefix: string) (suffix: string): string =
  let filename = Filename.temp_file prefix suffix in
  Sys.remove filename;
  Unix.mkdir filename 0o755;
  filename

(* TODO(#40): if the animation is infinite the rendering will be infinite *)
let render (animation_path: string) (output_filename): unit =
  Dynlink.loadfile(animation_path);
  let module A = (val Animation.get_current () : Animation.T) in
  let n = A.frames |> Flow.length in
  let dirpath = temp_dir "multik" "frames" in
  Printf.printf "Rendering frames to %s\n" dirpath;
  A.frames
  |> Flow.zip (Flow.from 0)
  |> Flow.iter (fun (index, picture) ->
       let filename = dirpath
                      ^ Filename.dir_sep
                      ^ string_of_int index
                      ^ ".png"
       in Printf.sprintf "Rendering frame %d/%d" (index + 1) n |> print_string;
          Console.savePicture A.resolution filename picture;
          print_string "\r";
          flush stdout);
  print_endline "";
  let _ = compose_video_file dirpath A.fps output_filename in ()

let preview (animation_path: string) =
  let rec loop (resolution: int * int) (delta_time: float) (frames: Picture.t Flow.t): unit =
    if not (Console.should_quit ())
    then (if (Watcher.is_file_modified ())
          then (print_endline "reloading";
                Dynlink.loadfile(animation_path);
                let module Reload = (val Animation.get_current () : Animation.T) in
                if Flow.is_nil Reload.frames
                then loop Reload.resolution delta_time Flow.nil
                else Reload.frames |> Flow.cycle |> loop Reload. resolution delta_time)
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
                   loop resolution delta_time rest_frames
                | None -> [empty_animation_frame resolution]
                          |> Flow.of_list
                          |> Flow.cycle
                          |> loop resolution delta_time))
    else ()
  in
    Dynlink.loadfile(animation_path);
    let module A = (val Animation.get_current () : Animation.T) in
    let (width, height) = A.resolution in
    let delta_time = 1.0 /. (float_of_int A.fps) in
    Console.init width height;
    Watcher.init animation_path;
    if Flow.is_nil A.frames
    then loop A.resolution delta_time Flow.nil
    else A.frames |> Flow.cycle |> loop A.resolution delta_time;
    Watcher.free ();
    Console.free ()

let () =
  match Sys.argv |> Array.to_list with
  | _ :: "preview" :: animation_path :: _ ->
     preview animation_path
  | name :: "preview" :: _ ->
     Printf.fprintf stderr "Using %s preview <animation-path>" name
  | _ :: "render" :: animation_path :: output_filename :: _ ->
     render animation_path output_filename
  (* TODO(#58): `./multik render` segfaults *)
  | name :: "render" :: _ ->
     Printf.fprintf stderr "Using: %s render <animation-path> <output-filename>" name
  | name :: _ -> Printf.fprintf stderr "Using: %s <preview|render>" name
  | _ -> Printf.fprintf stderr "Using: <program> <preview|render>"
