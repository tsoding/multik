module ScalingTest : Animation.T =
  struct
    let fps = 30
    let resolution = (800, 600)
    let background =
      resolution
      |> Vec2.of_ints
      |> Picture.rect
      |> Picture.color Color.black
    let circle =
      Picture.circle 10.0
      |> Picture.color Color.red
      |> Picture.scale (2.0, 2.0)
      |> Picture.translate (100.0, 100.0)
    let rect =
      Picture.rect (50.0, 50.0)
      |> Picture.color Color.blue
      |> Picture.scale (3.0, 3.0)
      |> Picture.translate (100.0, 100.0)
    let frames = Flow.of_list [Picture.compose [ background
                                               (* ; circle *)
                                               ; rect]]
  end

let () = Animation.load (module ScalingTest : Animation.T)
