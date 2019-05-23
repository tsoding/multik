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
