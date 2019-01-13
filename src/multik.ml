open Picture

module type Animation =
  sig
    type t
    val init : t
    val render : t -> picture
    val update : float -> t -> t
    val fps : int
    val resolution : int * int
  end

module type Multik =
  sig
    val run : unit -> unit
  end

module MakeMultik (A: Animation): Multik = struct
  let run () =
    let (width, height) = A.resolution in
    let rec loop (s: A.t): unit =
      if not (Console.should_quit ())
      then
        begin
          Console.clear 0 0 0;
          s |> A.render |> Picture.render;
          Console.render ();
          (* TODO(#5): FPS is not actually maintained *)
          s |> A.update 0.33 |> loop;
        end
      else ()
    in Console.init width height;
       loop A.init;
       Console.free ()
end
