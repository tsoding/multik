type 'a cons = Nil | Cons of 'a Lazy.t * 'a t
and 'a t =
  {
    flow : 'a cons Lazy.t
  }

let nil: 'a t = { flow = lazy Nil }

let rec of_list (xs: 'a list): 'a t =
  {
    flow = lazy
             (match xs with
              | [] -> Nil
              | x :: xs -> Cons (lazy x, of_list xs))
  }

let rec as_list (xs: 'a t): 'a list =
  match Lazy.force xs.flow with
  | Nil -> []
  | Cons (x, xs) -> Lazy.force x :: as_list xs

let rec map (f: 'a -> 'b) (xs: 'a t): 'b t =
  {
    flow = lazy
      (match Lazy.force xs.flow with
       | Nil -> Nil
       | Cons (x, xs) ->
          Cons (lazy (Lazy.force x |> f),
                map f xs))
  }

let rec concat (xs1: 'a t) (xs2: 'a t): 'a t =
  {
    flow = lazy
             (match Lazy.force xs1.flow with
              | Nil -> Lazy.force xs2.flow
              | Cons (x, xs) -> Cons (x, concat xs xs2))
  }

(* TODO(#18): Should (Flow.cycle Nil) throw an error? *)
let rec cycle (xs: 'a t): 'a t =
  concat xs { flow = lazy (Lazy.force (cycle xs).flow) }

let rec iterate (f: 'a -> 'a) (init: 'a): 'a t =
  {
    flow = lazy (Cons (lazy init, iterate f (f init)))
  }

let rec take (n : int) (xs : 'a t): 'a t =
  {
    flow = lazy (if n <= 0
                 then Nil
                 else match Lazy.force xs.flow with
                      | Nil -> Nil
                      | Cons (x, xs) ->
                         Cons (x, take (n - 1) xs))
  }
