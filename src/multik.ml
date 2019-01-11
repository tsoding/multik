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
  let f _ = ()

  let run () =
    let rec loop (s: A.t): unit =
      s |> A.render |> f;
      s |> A.update 0.33 |> loop
    in loop A.init
end
