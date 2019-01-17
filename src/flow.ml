type 'a t = Nil | Cons of 'a Lazy.t * 'a t Lazy.t

let rec of_list (xs: 'a list): 'a t =
  match xs with
  | [] -> Nil
  | x :: xs -> Cons (lazy x, lazy (of_list xs))

let rec as_list (xs: 'a t): 'a list =
  match xs with
  | Nil -> []
  | Cons (x, xs) -> Lazy.force x :: as_list (Lazy.force xs)

let rec iter (f: 'a -> unit) (xs: 'a t): unit =
  match xs with
  | Nil -> ()
  | Cons (x, xs) ->
     Lazy.force x |> f;
     Lazy.force xs |> iter f

let rec map (f: 'a -> 'b) (xs: 'a t): 'b t =
  match xs with
  | Nil -> Nil
  | Cons (x, xs) ->
     Cons (lazy (Lazy.force x |> f),
           lazy (Lazy.force xs |> map f))

let rec scanl (f: 'a -> 'b -> 'a) (init: 'a) (xs: 'b t): 'a t =
  match xs with
  | Nil -> Nil
  | Cons (x, xs) ->
     Cons (lazy init,
           lazy (Lazy.force xs
                 |> scanl f (Lazy.force x |> f init)))

let rec concat (xs1: 'a t) (xs2: 'a t): 'a t =
  match xs1 with
  | Nil -> xs2
  | Cons (x, xs) -> Cons (x, lazy (concat (Lazy.force xs) xs2))

(* TODO: Should (Flow.cycle Nil) throw an error? *)
let rec cycle (xs: 'a t): 'a t =
  concat xs (cycle xs)
