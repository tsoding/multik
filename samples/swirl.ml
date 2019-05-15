module Swirl : Animation.T =
  struct
    let fps = 60
    let resolution = (1920, 1080)

    let center (p: Picture.t): Picture.t =
      let w, h = resolution in
      let half_w, half_h = (float_of_int w *. 0.5, float_of_int h *. 0.5) in
      p |> Picture.translate (half_w, half_h)

    let background : Picture.t =
      let brightness = 1.0 /. 10.0 in
      Picture.rect (resolution |> Vec2.of_ints)
      |> Picture.color (Color.rgba brightness brightness brightness 1.0)

    let dot =
      Picture.Circle 30.0
      (* |> Picture.color (Color.rgba 0.8 0.9 0.9 1.0) *)

    let swirl (p: Picture.t): Picture.t Flow.t =
      Flow.iterate (fun angle -> angle +. 0.025) 0.1
      |> Flow.map (fun angle ->
             p
             |> Picture.scale (0.2 *. angle, 0.2 *. angle)
             |> Picture.translate (angle *. 50.0, 0.0)
             |> Picture.rotate angle
             |> Picture.color (Color.rgba (angle *. 0.1) (1.0 /. (angle *. 0.1)) (angle *. 0.05) 1.0)
             |> center)
      |> Flow.take 1000
      |> Flow.cycle

    let rec shift (n: int) (s: int) (frames: Picture.t Flow.t): Picture.t Flow.t =
      if n <= 1
      then frames
      else Flow.zip frames (shift (n - 1) s (frames |> Flow.drop s))
           |> Flow.map (fun (a, b) -> Picture.Compose [a; b])

    let frames =
      Flow.zip ([background] |> Flow.of_list |> Flow.cycle) (swirl dot |> shift 100 10)
      |> Flow.map (fun (a, b) -> Picture.Compose [a; b])
      |> Flow.take 800

  end

let () = Hot.load (module Swirl : Animation.T)
