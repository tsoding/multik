type picture = Nothing

module type Animation =
  sig
    type t
    val init : t
    val render : t -> picture
    val update : float -> t -> t
  end

module type Multik =
  sig
    val run : unit -> unit
  end

module MakeMultik (A: Animation): Multik = struct
  let run () =
    let rec loop (s: A.t): unit =
      if not (Console.should_quit ())
      then
        begin
          (* TODO(#4): Animation is not rendered *)
          Console.render ();
          s |> A.update 0.33 |> loop
        end
      else ()
    in Console.init 800 600;
       loop A.init;
       Console.free ()
end
