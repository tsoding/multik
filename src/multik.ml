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
    let rec loop (frames: Picture.t Flow.t): unit =
      let frame_begin = Sys.time () in
      if not (Console.should_quit ())
      then
        match frames with
        | Cons (frame, rest_frames) ->
           begin
             Lazy.force frame |> Picture.render;
             Console.render ();
             let frame_work = Sys.time () -. frame_begin in
             begin
               (delta_time -. frame_work) |> max 0.0 |> Thread.delay;
               Lazy.force rest_frames |> loop
             end
           end
        | Nil -> ()
      else ()
    in Console.init width height;
       loop A.frames;
       Console.free ()
end
