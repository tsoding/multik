module type Animation =
  sig
    val frames : Picture.t Flow.t
    val fps : int
    val resolution : int * int
  end

module type Multik =
  sig
    val run : unit -> unit
  end

module Make (A: Animation): Multik = struct
  let (width, height) = A.resolution
  let delta_time = 1.0 /. (float_of_int A.fps)
  let empty_animation_frame =
    Picture.Color
      ( Color.red
      (* TODO(#22): "No Animation" sign is not rendered at the center of the screen *)
      , Picture.Text ((0.0, 90.0), 50.0, "No Animation")
      )

  (* TODO(#40): if the animation is infinite the rendering will be infinite *)
  let render (dirpath: string): unit =
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
    let rec loop (frames: Picture.t Flow.t): unit =
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
               loop rest_frames
             end
           end
        | None -> [empty_animation_frame]
                  |> Flow.of_list
                  |> Flow.cycle
                  |> loop
      else ()
    in Console.init width height;
       if Flow.is_nil A.frames
       then loop Flow.nil
       else A.frames |> Flow.cycle |> loop;
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
end
