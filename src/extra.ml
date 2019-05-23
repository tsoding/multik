module List =
  struct
    let rec range (low: int) (high: int): int list =
      if low > high
      then []
      else low :: range (low + 1) high

    let excludeNth (n: int) (xs: 'a list): 'a list =
      xs
      |> List.mapi (fun i x -> (i, x))
      |> List.filter (fun (i, _) -> i != n)
      |> List.map snd

    let rec take (n: int) (xs: 'a list): 'a list =
      if n <= 0
      then []
      else (match xs with
            | [] -> []
            | x :: ys -> x :: take (n - 1) ys)

    include List
  end

module Array =
  struct
    let swap (i: int) (j: int) (xs: 'a array): unit =
      let a = Array.get xs i in
      let b = Array.get xs j in
      Array.set xs i b;
      Array.set xs j a

    include Array
  end

module Fun =
  struct
    let uncurry (f: 'a -> 'b -> 'c): 'a * 'b -> 'c =
      fun (a, b) -> f a b
  end
