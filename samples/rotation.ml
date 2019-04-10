module Rotation : Animation.T =
  struct
    type t =
      {
        angle: float;
      }

    let width = 1920
    let height = 1080
    let resolution = (width, height)
    let fps = 30
    let background_color = Color.rgb 0.1 0.1 0.1
    let dot_color = Color.rgb 1.0 0.5 0.5

    let background =
      Picture.Rect (float_of_int width, float_of_int height)
      |> Picture.color background_color

    let circle (n: int) (l: float): Vec2.t list =
      let pi = 3.14159265359 in
      let delta_angle = 2.0 *. pi /. float_of_int n in
      Flow.from 0
      |> Flow.take n
      |> Flow.map (fun i ->
             let angle = float_of_int i *. delta_angle in
             (l *. cos angle, l *. sin angle))
      |> Flow.as_list

    let dot =
      Picture.Circle 15.0
      |> Picture.color dot_color

    let dots ps =
      ps
      |> List.map (fun (x, y) -> dot |> Picture.translate (x, y))
      |> Picture.compose


    let init_state =
      {
        angle = 0.0
      }

    let ring (state: t) (r: float) =
      circle 100 r
      |> dots
      |> Picture.rotate state.angle
      |> Picture.translate
           (float_of_int width *. 0.5,
            float_of_int height *. 0.5)

    let render_state state =
      Picture.Compose [ background;
                        ring state 500.0;
                        ring state 300.0]

    let update_state state = {angle = state.angle +. 0.1}

    let frames =
      Flow.iterate update_state init_state
      |> Flow.map render_state
      |> Flow.take 100
  end

let () = Animation.load (module Rotation : Animation.T)
