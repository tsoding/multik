module Sort =
  struct
    let print_trace (trace: (int * int) list) =
      trace |> List.iter (fun (i, j) -> Printf.printf "%d %d\n" i j);
      print_endline "------------------------------"

    let bubble_trace (xs: int list): (int * int) list =
      let input = Array.of_list xs in
      let output = ref [] in
      let n = Array.length input in
      for i = n downto 2 do
        for j = 0 to i - 2 do
          let a = Array.get input j in
          let b = Array.get input (j + 1) in
          if a > b then
            begin
              Array.set input j b;
              Array.set input (j + 1) a;
              output := (j, j + 1) :: !output
            end
        done
      done;
      List.rev !output
  end

module Bubble : Animation.T =
  struct
    let row_padding = 150.0
    let resolution = (1920, 1080)
    let (width, height) = resolution |> Vec2.of_ints
    let fps = 60
    let delta_time = 1.0 /. float_of_int fps

    let background_color = (0.1, 0.1, 0.1, 1.0)

    let background: Picture.t =
      Picture.rect (width, height)
      |> Picture.color background_color

    let shadow (p: Picture.t): Picture.t =
      let offset = 3.0 in
      Picture.compose [ p
                        |> Picture.color Color.black
                        |> Picture.translate (offset, offset)
                      ; p ]

    let dot (titleText: string): Picture.t =
      let radius = 50.0 in
      let circle_color = (1.0, 0.2, 0.2, 1.0) in
      let text_color = (0.8, 0.8, 0.8, 1.0) in
      Picture.compose
        [ Picture.circle radius
          |> Picture.color circle_color
        ; let title =
            Picture.text (Font.make "Ubuntu Mono" (radius *. 1.2)) titleText
            |> shadow
            |> Picture.color text_color
          in Picture.sizeOf
               title
               (fun (_, _, w, h) ->
                 title
                 |> Picture.translate (w *. (-0.5), h *. 0.5))]

    let row_layout (padding: float) (xs: 'a list): Vec2.t list =
      xs |> List.mapi (fun i _ -> (padding *. float_of_int i, 0.0))

    (* TODO: row layouting should be available to all animations *)
    let row (padding: float) (ps: Picture.t list): Picture.t =
      List.map2 Picture.translate (row_layout padding ps) ps
      |> Picture.compose

    let screenCenter (p: Picture.t): Picture.t =
      Picture.sizeOf p
        (fun (_, _, w, h) ->
          p |> Picture.translate (width *. 0.5 -. w *. 0.5,
                                  height *. 0.5 -. h *. 0.5))

    let kkona_snek (angle: float) =
      ListExtra.range 1 30
      |> List.map string_of_int
      |> List.map (fun _ ->
             Picture.image "./kkona.png"
             |> Picture.scale (2.5, 2.5))
      |> List.mapi (fun i p ->
             p
             |> Picture.translate
                  (0.0, sin (angle +. float_of_int i *. 0.6) *. 50.0))
      |> row 50.0

    let render_array (xs: int list): Picture.t =
      xs
      |> List.map string_of_int
      |> List.map dot
      |> row row_padding

    type t = float

    let animate_move (p: Picture.t) (start: Vec2.t) (finish: Vec2.t): Picture.t Flow.t =
      let duration = 0.5 in
      let n = floor (duration /. delta_time) in
      let r = delta_time /. duration in
      let dir = let open Vec2 in finish |-| start in
      ListExtra.range 0 (int_of_float n - 1)
      |> List.map (fun i ->
             let open Vec2 in
             p
             |> Picture.translate (start |+| (dir |**| (r *. float_of_int i))))
      |> Flow.of_list


    let animate_swap (a, b: int * int) (xs: int list): Picture.t Flow.t =
      let (i, j) = if a > b then (b, a) else (a, b) in
      let dots = xs
                 |> List.map string_of_int
                 |> List.map dot
      in
      let ps = row_layout row_padding dots in
      let dot1 = List.nth dots i in
      let dot2 = List.nth dots j in
      let p1 = List.nth ps i in
      let p2 = List.nth ps j in
      let rest_dots = dots
                      |> ListExtra.excludeNth j
                      |> ListExtra.excludeNth i
      in
      let rest_ps = ps
                    |> ListExtra.excludeNth j
                    |> ListExtra.excludeNth i
      in
      [List.map2 Picture.translate rest_ps rest_dots
       |> Picture.compose]
      |> Flow.of_list
      |> Flow.cycle
      |> Flow.zip (Flow.zip
                     (animate_move dot1 p1 p2)
                     (animate_move dot2 p2 p1)
                   |> Flow.map (fun (pic1, pic2) ->
                          Picture.compose [pic1; pic2]))
      |> Flow.map (fun (pic1, pic2) ->
             Picture.compose [pic1; pic2])

    let animate_bubble (xs: int list): Picture.t Flow.t =
      let trace = Sort.bubble_trace xs in
      let n = List.length trace in
      let states =
        let arr = Array.of_list xs in
        xs :: (trace
               |> List.map (fun (i, j) ->
                      arr |> ArrayExtra.swap i j;
                      arr |> Array.to_list))
      in
      let last_state = [List.nth states n |> render_array]
                       |> Flow.of_list
                       |> Flow.cycle
                       |> Flow.take (floor (2.0 /. delta_time)
                                     |> int_of_float)
      in (List.map2 animate_swap trace (states |> ListExtra.take n)
          @ [last_state])
         |> List.fold_left Flow.concat Flow.nil

    let frames =
      Flow.zip
        (Flow.of_list [background] |> Flow.cycle)
        ([10; 9; 8; 7; 6; 5; 4; 3; 2; 1]
         |> animate_bubble
         |> Flow.map screenCenter)
      |> Flow.map (fun (p1, p2) -> Picture.compose [p1; p2])

  end

let () = Hot.load (module Bubble : Animation.T)
