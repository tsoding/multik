module type Animation =
  sig
    type t
    val init : t
    val render : t -> Picture.t
    val update : float -> t -> t
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
    let rec loop (s: A.t): unit =
      let frame_begin = Sys.time () in
      if not (Console.should_quit ())
      then
        begin
          s |> A.render |> Picture.render;
          Console.render ();
          let s1 = s |> A.update delta_time in
          let frame_work = Sys.time () -. frame_begin in
          begin
            if frame_work < delta_time
            then Thread.delay (delta_time -. frame_work);
            loop s1
          end
        end
      else ()
    in Console.init width height;
       loop A.init;
       Console.free ()
end
