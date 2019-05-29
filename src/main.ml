let empty_animation_frame (screen_width, screen_height) =
  let label_text = "<no animation>" in
  let label_at position =
    Picture.Text (Font.make "Sans" 50.0, label_text)
  in
  Picture.sizeOf
    (label_at (0.0, 0.0))
    (fun (_, _, label_width, label_height) ->
      Picture.Color
        ( Color.red
        , Picture.Text (Font.make "Sans" 50.0, label_text)
          |> Picture.translate
               (float_of_int screen_width *. 0.5 -. label_width *. 0.5, float_of_int screen_height *. 0.5 -. label_height *. 0.5)))

let compose_video_file (dirpath: string) (fps: int) (output_filename: string) (flags: string list): Unix.process_status =
  let cli =
    Printf.sprintf "ffmpeg -y -framerate %d -i %s/%%d.png %s %s" fps dirpath output_filename (flags |> String.concat " ")
  in
  print_endline cli;
  cli
  |> Unix.open_process_in
  |> Unix.close_process_in

let temp_dir (prefix: string) (suffix: string): string =
  let filename = Filename.temp_file prefix suffix in
  Sys.remove filename;
  Unix.mkdir filename 0o755;
  filename

let rec rmdir_rec (path: string): unit =
  Printf.printf "Remove %s\n" path;
  if Sys.is_directory path
  then
    (let children = path
                    |> Sys.readdir
                    |> Array.to_list
     in if List.length children > 0
        then children
             |> List.map (Filename.concat path)
             |> List.iter rmdir_rec;
        Unix.rmdir path)
  else Sys.remove path

type render_config_t =
  {
    scaling : float;
    fps_scaling: float;
    ffmpeg_flags: string list;
  }

let string_of_render_config (config: render_config_t): string =
  Printf.sprintf "CONFIG:\n  SCALING: %f\n  FPS_SCALING: %f\n  FFMPEG_FLAGS: %s\n"
    config.scaling
    config.fps_scaling
    (config.ffmpeg_flags |> String.concat " ")

let scale_fps (src_fps: int) (dest_fps: int) (frames: 'a Flow.t): 'a Flow.t =
  let src_dt = 1.0 /. float_of_int src_fps in
  let dest_dt = 1.0 /. float_of_int dest_fps in
  let rec interpolate_frames (t: float) (frames: 'a Flow.t): 'a Flow.t =
    match Flow.uncons frames with
    | Some (x, xs) ->
       if t < src_dt
       then Flow.cons x (interpolate_frames (t +. dest_dt) frames)
       else interpolate_frames (t -. src_dt) xs
    | None -> Flow.nil
  in if src_fps != dest_fps
     then interpolate_frames 0.0 frames
     else frames

let explain_status (status: Unix.process_status): string =
  match status with
  | Unix.WEXITED code -> Printf.sprintf "exited with %d" code
  | Unix.WSIGNALED signal -> Printf.sprintf "was killed by a signal %d" signal
  | Unix.WSTOPPED signal -> Printf.sprintf "was stopped by a signal %d" signal

(* TODO(#40): if the animation is infinite the rendering will be infinite *)
let render (animation_path: string) (output_filename: string) (config: render_config_t): unit =
  string_of_render_config config |> print_endline;
  Hot.loadfile(animation_path);
  let module A = (val Hot.get_current () : Animation.T) in
  let scaled_fps = A.fps |> float_of_int |> ( *. ) config.fps_scaling |> int_of_float in
  let scaled_frames = A.frames
                      |> scale_fps A.fps scaled_fps
                      |> Flow.map (Picture.scale (Vec2.of_float config.scaling)) in
  let n = scaled_frames |> Flow.length in
  let dirpath = temp_dir "multik" "frames" in
  Printf.printf "Rendering frames to %s\n" dirpath;
  let (width, height) = A.resolution in
  let scaled_resolution = ((float_of_int width *. config.scaling)  |> floor |> int_of_float,
                           (float_of_int height *. config.scaling) |> floor |> int_of_float) in
  Cairo.with_context scaled_resolution
    (fun c ->
      scaled_frames
      |> Flow.zip (Flow.from 0)
      |> Flow.for_ (fun (index, picture) ->
             let filename = dirpath
                            ^ Filename.dir_sep
                            ^ string_of_int index
                            ^ ".png"
             in Printf.sprintf "Rendering frame %d/%d" (index + 1) n |> print_string;
                Cairo.render c picture;
                Cairo.save_to_png c filename;
                print_string "\r";
                flush stdout));
  print_endline "";
  compose_video_file dirpath scaled_fps output_filename config.ffmpeg_flags
  |> explain_status
  |> Printf.printf "ffmpeg %s";
  rmdir_rec dirpath

(* TODO(#125): Shadow function is not available to the animations *)
let shadow (p: Picture.t): Picture.t =
  Picture.compose [ p
                    |> Picture.color Color.black
                    |> Picture.translate (3.0, 3.0)
                  ; p ]

let preview (animation_path: string) =
  let render_picture (p: Picture.t): unit =
    Cairo.with_texture (Console.texture ())
      (fun c -> Cairo.render c p)
  in
  let rec loop (delta_time: float) (current_fps: int) (frames: Picture.t Flow.t): unit =
    if not (Console.should_quit ())
    then (if (Watcher.is_file_modified ())
          then (print_endline "reloading";
                Hot.loadfile(animation_path);
                let module Reload = (val Hot.get_current () : Animation.T) in
                if Flow.is_nil Reload.frames
                then loop delta_time current_fps Flow.nil
                else Reload.frames |> Flow.cycle |> loop delta_time current_fps)
          else (let module A = (val Hot.get_current () : Animation.T) in
                let frame_begin = Sys.time () in
                match Flow.uncons frames with
                | Some (frame, rest_frames) ->
                   let (_, _, vx, _) = Console.viewport () in
                   let rx, _ = A.resolution in
                   let s = vx /. float_of_int rx in
                   Picture.compose [ Lazy.force frame
                                   ; Printf.sprintf "FPS: %d" current_fps
                                     |> Picture.text (Font.make "Sans" 100.0)
                                     |> shadow
                                     |> Picture.translate (0.0, 100.0)
                                     |> Picture.color Color.white ]
                   |> Picture.scale (s, s)
                   |> render_picture;
                   Console.present ();
                   let frame_work = Sys.time () -. frame_begin in
                   (delta_time -. frame_work) |> max 0.0 |> Thread.delay;
                   let next_fps = 1.0 /. (max frame_work delta_time) in
                   loop delta_time (int_of_float ((next_fps +. float_of_int current_fps) /. 2.0)) rest_frames
                | None -> [empty_animation_frame A.resolution]
                          |> Flow.of_list
                          |> Flow.cycle
                          |> loop delta_time current_fps))
    else ()
  in
    Hot.loadfile(animation_path);
    let module A = (val Hot.get_current () : Animation.T) in
    let (width, height) = A.resolution in
    let delta_time = 1.0 /. (float_of_int A.fps) in
    Console.init width height;
    Watcher.init animation_path;
    if Flow.is_nil A.frames
    then loop delta_time 0 Flow.nil
    else A.frames |> Flow.cycle |> loop delta_time 0;
    Watcher.free ();
    Console.free ()

(* TODO(#93): flags override each other in a reversed order *)
let rec render_config_of_args (args: string list): render_config_t =
  match args with
  | [] -> { scaling = 1.0; fps_scaling = 1.0; ffmpeg_flags = [] }
  | "--scale" :: factor :: rest_args ->
     { (render_config_of_args rest_args) with
       scaling = float_of_string factor }
  | "--fps-scale" :: fps_factor :: rest_args ->
     { (render_config_of_args rest_args) with
       fps_scaling = float_of_string fps_factor }
  | "--ffmpeg" :: rest_args ->
     {
       scaling = 1.0;
       fps_scaling = 1.0;
       ffmpeg_flags = rest_args
     }
  | unknown_flag :: _ ->
     Printf.sprintf "Unknown flag: %s" unknown_flag |> failwith

let () =
  match Sys.argv |> Array.to_list with
  | _ :: "preview" :: animation_path :: _ ->
     preview animation_path
  | name :: "preview" :: _ ->
     Printf.fprintf stderr "Using %s preview <animation-path>" name
  | _ :: "render" :: animation_path :: output_filename :: args ->
     render_config_of_args args
     |> render animation_path output_filename
  | name :: "render" :: _ ->
    (*
     * TODO(#96): multik does not scale to an absolute resolution
     * It should support both relative and absolute ones.
     *)
     Printf.fprintf stderr "Using: %s render <animation-path> <output-filename> [--scale <factor>] [--fps-scale <fps-factor>] [--ffmpeg <additional-ffmpeg-arguments>]" name
  | name :: _ -> Printf.fprintf stderr "Using: %s <preview|render>" name
  | _ -> Printf.fprintf stderr "Using: <program> <preview|render>"
