module Arkanoid : Animation.T =
  struct
    type t =
      {
        position: float * float;
        direction: float * float;
      }

    let radius = 50.0

    let init =
      {
        position = (100.0, 100.0);
        direction = (1000.0, 1000.0);
      }

    let resolution = (800, 600)

    let render state =
      let (x, y) = state.position in
      let (w, h) = resolution in
      [ Picture.rect 0.0 0.0 (float_of_int w) (float_of_int h)
        |> Picture.color Color.black
      ; Picture.circle x y radius |> Picture.color Color.blue
      ] |> Picture.compose

    let wall_collision (state: t): t =
      let (x, y) = state.position in
      let (dx, dy) = state.direction in
      let (w, h) = resolution in
      { state with
        direction = ((if radius <= x && x <= ((float_of_int w) -. radius) then dx else (dx *. -1.)),
                     (if radius <= y && y <= ((float_of_int h) -. radius) then dy else (dy *. -1.)))
      }

    let move (delta_time: float) (state: t): t =
      let (x, y) = state.position in
      let (dx, dy) = state.direction in
      { state with
        position = (x +. dx *. delta_time, y +. dy *. delta_time)
      }

    let update delta_time state =
      state |> wall_collision |> move delta_time

    let fps = 30

    let frames =
      init
      |> Flow.iterate (update (1.0 /. float_of_int fps))
      |> Flow.map render
      |> Flow.take 100
  end

let () = Animation.load (module Arkanoid : Animation.T)
