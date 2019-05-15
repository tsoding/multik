module Empty : Animation.T =
  struct
    let frames = Flow.nil
    let fps = 30
    let resolution = (800, 600)
  end

let () = HotReload.load (module Empty : Animation.T)
