open Extra

type action_t = Swap of int * int
              | Assign of int * int

module Bubble =
  struct
    let trace (xs: int list): action_t list =
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
              output := Swap (j, j + 1) :: !output
              (* output := Assign (j, b) :: Assign (j + 1, a) :: !output *)
            end
        done
      done;
      List.rev !output
  end

module Merge =
  struct
    let merge_array (xs: int array) (l: int) (m: int) (h: int): action_t list =
      let n = h - l in
      let ys = Array.make n 0 in
      let rec merge_array_impl (i: int) (j: int) (k: int): unit =
        match () with
        | _ when (i >= m) && (j >= h) -> ()
        | _ when i >= m ->      (* ran out of left, pick right *)
           Array.set ys k (Array.get xs j);
           merge_array_impl i (j + 1) (k + 1)
        | _ when j >= h ->      (* ran out of right, pick left *)
           Array.set ys k (Array.get xs i);
           merge_array_impl (i + 1) j (k + 1)
        | _ when Array.get xs i < Array.get xs j -> (* pick left *)
           Array.set ys k (Array.get xs i);
           merge_array_impl (i + 1) j (k + 1)
        | _ when Array.get xs i >= Array.get xs j -> (* pick right *)
           Array.set ys k (Array.get xs j);
           merge_array_impl i (j + 1) (k + 1)
        | _ -> failwith "Should never happen"
      in
      merge_array_impl l m 0;
      Array.blit ys 0 xs l (h - l);
      ys
      |> Array.to_list
      |> List.mapi (fun i y -> Assign (l + i, y))

    let trace (xs: int list): action_t list =
      let rec merge_trace_impl (xs: int array) (l: int) (h: int): action_t list =
        if h - l <= 1
        then []
        else let m = l + (h - l) / 2 in
             let t1 = merge_trace_impl xs l m in
             let t2 = merge_trace_impl xs m h in
             let t3 = merge_array xs l m h in
             t1 @ t2 @ t3
      in
      let arr = Array.of_list xs in
      let t = merge_trace_impl arr 0 (List.length xs) in
      arr |> Array.iter (Printf.printf "%d ");
      print_endline "";
      t
  end

module Quick =
  struct
    let trace (xs: int list): action_t list =
      let n = List.length xs in
      let ys = Array.of_list xs in
      let trace = ref [] in
      let pivot_first (l: int) (h: int): int =
        let rec pivot_impl (p: int) (i: int): int =
          if i < h then
            (if (Array.get ys p) > (Array.get ys i) then
               begin
                 Array.swap (p + 1) i ys;
                 trace := ((p + 1), i) :: !trace;

                 Array.swap p (p + 1) ys;
                 trace := (p, (p + 1)) :: !trace;

                 pivot_impl (p + 1) (i + 1)
               end
             else
               pivot_impl p (i + 1))
          else p
        in
        pivot_impl l (l + 1)
      in

      let pivot_middle (l: int) (h: int): int =
        let rec pivot_left (p: int) (i: int): int =
          if i < p then
            (if (Array.get ys p) <= (Array.get ys i)
             then
               begin
                 Array.swap i (p - 1) ys;
                 trace := (i, (p - 1)) :: !trace;

                 Array.swap (p - 1) p ys;
                 trace := ((p - 1), p) :: !trace;

                 pivot_left (p - 1) i
               end
             else pivot_left p (i + 1))
          else p
        in
        let rec pivot_right (p: int) (i: int): int =
          if i < h then
            (if (Array.get ys p) > (Array.get ys i) then
               begin
                 Array.swap (p + 1) i ys;
                 trace := ((p + 1), i) :: !trace;

                 Array.swap p (p + 1) ys;
                 trace := (p, (p + 1)) :: !trace;

                 pivot_right (p + 1) (i + 1)
               end
             else
               pivot_right p (i + 1))
          else p
        in
        let p0 = l + (h - l) / 2 in
        let p1 = pivot_left p0 l in
        pivot_right p1 (p1 + 1)
      in
      let rec quick_trace_impl (l: int) (h: int) (pivot: int -> int -> int): unit =
        if h - l >= 2 then
          let p = pivot l h in
          quick_trace_impl l p pivot;
          quick_trace_impl (p + 1) h pivot
      in
      quick_trace_impl 0 n pivot_middle;
      print_endline "";
      !trace
      |> List.rev
      |> List.filter (fun (a, b) -> a != b)
      |> List.map (fun (a, b) -> Swap (a, b))
  end

module Sort : Animation.T =
  struct
    let row_padding = 50.0
    let resolution = (1920, 1080)
    let (width, height) = resolution |> Vec2.of_ints
    let fps = 60
    let delta_time = 1.0 /. float_of_int fps

    let background_color = (0.1, 0.1, 0.1, 1.0)
    let foreground_color = (1.0, 0.2, 0.2, 1.0)
    let highlight_color = (0.2, 1.0, 0.2, 1.0)

    let background: Picture.t =
      Picture.rect (width, height)
      |> Picture.color background_color

    let shadow (p: Picture.t): Picture.t =
      let offset = 3.0 in
      Picture.compose [ p
                        |> Picture.color Color.black
                        |> Picture.translate (offset, offset)
                      ; p ]

    let dot (circle_color: Color.t) (titleText: string): Picture.t =
      let radius = 25.0 in
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

    (* TODO(#122): row layouting should be available to all animations *)
    let row (padding: float) (ps: Picture.t list): Picture.t list =
      List.map2 Picture.translate (row_layout padding ps) ps

    let screenCenter (p: Picture.t): Picture.t =
      Picture.sizeOf p
        (fun (_, _, w, h) ->
          p |> Picture.translate (width *. 0.5 -. w *. 0.5,
                                  height *. 0.5))

    let kkona_snek (angle: float) =
      List.range 1 30
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
      |> List.map (dot foreground_color)
      |> row row_padding
      |> Picture.compose

    type t = float

    (* TODO(#123): animate_move is not available to all of the animations *)
    let animate_move (duration: float) (p: Picture.t) (start: Vec2.t) (finish: Vec2.t): Picture.t Flow.t =
      let n = floor (duration /. delta_time) in
      let r = delta_time /. duration in
      let dir = let open Vec2 in finish |-| start in
      Flow.range 0 (int_of_float n - 1)
      |> Flow.map (fun i ->
             let open Vec2 in
             p
             |> Picture.translate (start |+| (dir |**| (r *. float_of_int i))))

    let animate_hop (duration: float) (height: float) (p: Picture.t): Picture.t Flow.t =
      let up = animate_move
                 (duration *. 0.5) p (0.0, 0.0) (0.0, -. height)
      in
      let down = animate_move
                   (duration *. 0.5) p (0.0, -. height) (0.0, 0.0)
      in
      Flow.concat up down

    let animate_swap (a, b: int * int) (xs: int list): Picture.t Flow.t =
      let (i, j) = if a > b then (b, a) else (a, b) in
      let dots = xs
                 |> List.map string_of_int
                 |> List.map (dot foreground_color)
      in
      let ps = row_layout row_padding dots in
      let dot1 = List.nth dots i in
      let dot2 = List.nth dots j in
      let p1 = List.nth ps i in
      let p2 = List.nth ps j in
      let rest_dots = dots
                      |> List.excludeNth j
                      |> List.excludeNth i
      in
      let rest_ps = ps
                    |> List.excludeNth j
                    |> List.excludeNth i
      in
      let duration = 0.07 in
      [List.map2 Picture.translate rest_ps rest_dots
       |> Picture.compose]
      |> Flow.of_list
      |> Flow.cycle
      |> Flow.zipWith
           Picture.compose2
           (Flow.zipWith
              Picture.compose2
              (animate_move duration dot1 p1 p2)
              (animate_move duration dot2 p2 p1))

    (* TODO(#124): animate_wait is not available to all of the animations *)
    let animate_wait (seconds: float) (fps: int) (p: Picture.t): Picture.t Flow.t =
      Flow.replicate (floor (seconds *. float_of_int fps) |> int_of_float) p

    let animate_assign (i, x: int * int) (xs: int list): Picture.t Flow.t =
      let dots = xs
                 |> List.map string_of_int
                 |> List.map (dot foreground_color) in
      let ps = row_layout row_padding dots in
      let plox = string_of_int x
                 |> dot highlight_color
                 |> Picture.translate (List.nth ps i)
      in
      let background = List.map2
                         Picture.translate
                         (ps |> List.excludeNth i)
                         (dots |> List.excludeNth i)
                       |> Picture.compose
      in
      Flow.zipWith
        Picture.compose2
        (Flow.iterate (fun a -> a) background)
        (animate_hop 0.07 15.0 plox)

    let animate_trace (xs: int list) (trace: action_t list): Picture.t Flow.t =
      let n = List.length trace in
      let states =
        let arr = Array.of_list xs in
        xs :: (trace
               |> List.map (function
                        Swap (i, j) ->
                         arr |> Array.swap i j;
                         arr |> Array.to_list
                      | Assign (i, x) ->
                         Array.set arr i x;
                         arr |> Array.to_list))
      in
      let last_state = List.nth states n
                       |> render_array
                       |> animate_wait 2.0 fps
      in (List.map2 (fun action state ->
              match action with
                Swap (i, j) ->
                 animate_swap (i, j) state
              | Assign (i, x) ->
                 animate_assign (i, x) state)
            trace
            (states |> List.take n)
          @ [last_state])
         |> List.fold_left Flow.concat Flow.nil

    let frames =
      let xs = Random.int_list 50 35 in
      let trace = Quick.trace xs in
      trace |> List.length |> Printf.printf "Number of swaps: %d\n";
      Flow.zipWith
        Picture.compose2
        (Flow.of_list [background] |> Flow.cycle)
        (animate_trace xs trace
         |> Flow.map screenCenter)

  end

let () = Hot.load (module Sort : Animation.T)
