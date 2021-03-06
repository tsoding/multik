open Extra

type 'a cons = Nil | Cons of 'a Lazy.t * 'a t
and 'a t =
  {
    flow : 'a cons Lazy.t
  }

let nil: 'a t = { flow = lazy Nil }

let cons (x: 'a Lazy.t) (xs: 'a t): 'a t =
  {
    flow = lazy (Cons (x, xs))
  }

let uncons (xs: 'a t): ('a Lazy.t * 'a t) option =
  match Lazy.force xs.flow with
  | Nil -> None
  | Cons (x, xs) -> Some (x, xs)

let is_nil (xs : 'a t): bool =
  match Lazy.force xs.flow with
  | Nil -> true
  | _   -> false

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

let rec cycle (xs: 'a t): 'a t =
  if is_nil xs
  then failwith "Empty flow"
  else concat xs { flow = lazy (Lazy.force (cycle xs).flow) }

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

let rec drop (n : int) (xs : 'a t): 'a t =
  {
    flow = lazy (if n <= 0
                 then Lazy.force xs.flow
                 else match Lazy.force xs.flow with
                      | Nil -> Nil
                      | Cons (x, xs) -> Lazy.force (drop (n - 1) xs).flow)
  }

let rec zip (xs : 'a t) (ys : 'b t): ('a * 'b) t =
  match (Lazy.force xs.flow, Lazy.force ys.flow) with
  | (Nil, _) -> nil
  | (_, Nil) -> nil
  | (Cons (x, xs), Cons (y, ys)) -> {
      flow = lazy (Cons
                     (lazy (Lazy.force x, Lazy.force y),
                      zip xs ys))
    }

let rec zipWith (f: 'a -> 'b -> 'c) (xs: 'a t) (ys: 'b t): 'c t =
  zip xs ys |> map (Fun.uncurry f)

let rec from (n: int): int t =
  {
    flow = lazy (Cons (lazy n, from (n + 1)))
  }

let rec for_ (f: 'a -> unit) (xs: 'a t): unit =
  match Lazy.force xs.flow with
  | Nil -> ()
  | Cons (x, xs) -> Lazy.force x |> f;
                    for_ f xs

let rec length (xs: 'a t): int =
  match Lazy.force xs.flow with
  | Nil -> 0
  | Cons (_, xs) -> 1 + length xs

let rec replicate (n: int) (x: 'a): 'a t =
  [x] |> of_list |> cycle |> take n

let rec range (low: int) (high: int): int t =
  {
    flow = lazy (if low > high
                 then Nil
                 else Cons (lazy low, range (low + 1) high))
  }
