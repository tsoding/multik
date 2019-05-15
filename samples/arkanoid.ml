module Arkanoid : Animation.T =
  struct
    type t =
      {
        position: Vec2.t;
        direction: Vec2.t;
        angle: float;
      }

    let radius = 50.0

    let init =
      {
        position = (100.0, 100.0);
        direction = (1000.0, 1000.0);
        angle = 0.0;
      }

    let resolution = (1920, 1080)

    let obj (x, y: Vec2.t) (angle: float): Picture.t =
      Picture.rect (radius, radius)
      |> (Color.rgb 0.8 0.1 0.8 |> Picture.color)
      |> Picture.scale (2.0, 2.0)
      |> Picture.rotate angle
      |> Picture.translate (x, y)

    let render state =
      let (w, h) = resolution in
      [ Picture.rect (float_of_int w, float_of_int h)
        |> (Color.rgb 0.1 0.1 0.1 |> Picture.color)
      ; obj state.position state.angle
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

    let rotate (delta_time: float) (state: t): t=
      { state with
        angle = state.angle +. delta_time
      }

    let update delta_time state =
      state |> wall_collision |> move delta_time |> rotate delta_time

    let fps = 60

    let frames =
      init
      |> Flow.iterate (update (1.0 /. float_of_int fps))
      |> Flow.map render
      |> Flow.take 200
  end

let () = HotReload.load (module Arkanoid : Animation.T)
