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
  let run () =
    let (width, height) = A.resolution in
    let delta_time = 1.0 /. (float_of_int A.fps) in
    let empty_animation_frame =
      Picture.Color
        ( Color.red
        (* TODO: "No Animation" sign is not rendered at the center of the screen *)
        , Picture.Text ((0.0, 0.0), "No Animation")
        )
    in
    let rec loop (frames: Picture.t Flow.t): unit =
      let frame_begin = Sys.time () in
      if not (Console.should_quit ())
      then
        match Lazy.force frames.flow with
        | Cons (frame, rest_frames) ->
           begin
             Lazy.force frame |> Console.renderPicture;
             Console.render ();
             let frame_work = Sys.time () -. frame_begin in
             begin
               (*
                * TODO: The animation is replayed slower than it supposed to be
                *   1. Create animation with 100 frames and 30 fps
                *   2. Expected animation should last ~3 seconds
                *   3. Observed animation lasts >6 seconds
                *)
               (delta_time -. frame_work) |> max 0.0 |> Thread.delay;
               loop rest_frames
             end
           end
        (* TODO(#19): how should we handle the end of the flow of frames? *)
        | Nil -> ()
      else ()
    in Console.init width height;
       if Flow.is_nil A.frames
       then [empty_animation_frame]
            |> Flow.of_list
            |> Flow.cycle
            |> loop
       else A.frames
            |> Flow.cycle
            |> loop;
       Console.free ()
end
