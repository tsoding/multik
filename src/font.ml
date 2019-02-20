type t =
  {
    name: string;
    size: float
  }

let make (name: string) (size: float): t =
  {
    name = name;
    size = size
  }
