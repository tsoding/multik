let swap (i: int) (j: int) (xs: 'a array): unit =
  let a = Array.get xs i in
  let b = Array.get xs j in
  Array.set xs i b;
  Array.set xs j a
