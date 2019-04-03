module Rotation : Animation.T =
  struct
    type t =
      {
        angle: float;
      }

    let width = 1366
    let height = 768
    let resolution = (width, height)
    let fps = 30
    let background_color = Color.rgb 0.1 0.1 0.1
    let dot_color = Color.rgb 0.5 0.5 1.0

    let background =
      Picture.Rect (float_of_int width, float_of_int height)
      |> Picture.color background_color

    let square n = [ ((-0.5) *. n, (-0.5) *. n)
                   ; (0.5 *. n, (-0.5) *. n)
                   ; ((-0.5) *. n, 0.5 *. n)
                   ; (0.5 *. n, 0.5 *. n)
                   ]

    let dot =
      Picture.Circle 10.0
      |> Picture.color dot_color

    let dots ps =
      ps
      |> List.map (fun (x, y) -> dot |> Picture.translate (x, y))
      |> Picture.compose


    let init_state =
      {
        angle = 0.0
      }

    let rotate_ps angle ps =
      let rotate_p (x, y) =
        (x *. cos angle -. y *. sin angle,
         x *. sin angle +. y *. cos angle)
      in List.map rotate_p ps

    let render_state state =
      Picture.Compose [ background;
                        square 100.0
                        |> rotate_ps state.angle
                        |> dots
                        |> Picture.translate
                             (float_of_int width *. 0.5, float_of_int height *. 0.5)]

    let update_state state = {angle = state.angle +. 0.06}

    let frames =
      Flow.iterate update_state init_state
      |> Flow.map render_state
  end

let () = Animation.load (module Rotation : Animation.T)
