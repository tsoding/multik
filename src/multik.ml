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
      (* s |> A.render |> f; *)
      s |> A.update 0.33 |> loop
    in Foo.console_init 800 600;
       loop A.init;
       Foo.console_free ()
end
