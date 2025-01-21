///|
/// A point in the route grids
pub(all) struct Point {
  layer : Int
  x_idx : Int
  y_idx : Int
} derive(Eq, Compare, Show)

///|
/// A helper function to create point
pub fn Point::new(layer : Int, x_idx : Int, y_idx : Int) -> Point {
  { layer, x_idx, y_idx }
}

///|
pub fn Point::to_string(self : Point) -> String {
  "\{self.layer+1} \{self.x_idx} \{self.y_idx}"
}

///|
/// How far are tow points in l1 distance
pub fn Point::l1_distance(self : Point, other : Point) -> Int {
  let dl = Int::abs(self.layer - other.layer)
  let dx = Int::abs(self.x_idx - other.x_idx)
  let dy = Int::abs(self.y_idx - other.y_idx)
  dl + dx + dy
}

///|
/// A net connect two pins(points). We need to route all nets.
pub(all) struct Net {
  start : Point
  target : Point
} derive(Show)

///|
pub(all) struct Grid[T] {
  row_size : Int
  col_size : Int
  space : Array[Array[Array[T]]]
} derive(Show)

///|
/// Construct a `CostGrid` with given size and initial value
fn Grid::make[T](row_size : Int, col_size : Int, val : T) -> Grid[T] {
  let space = Array::make(2 * row_size * col_size, val)
    .chunks(col_size)
    .chunks(row_size)
  { row_size, col_size, space }
}

test "CostGrid:::make" {
  inspect!(
    Grid::make(1, 3, 4),
    content="{row_size: 1, col_size: 3, space: [[[4, 4, 4]], [[4, 4, 4]]]}",
  )
}

///|
/// Use a Point to get the cost from a `Grid`
fn Grid::op_get[T](self : Grid[T], key : Point) -> T {
  self.space[key.layer][key.y_idx][key.x_idx]
}

///|
/// Set the cost of the `Point` in a `Grid` to some value
fn Grid::op_set[T](self : Grid[T], key : Point, val : T) -> Unit {
  self.space[key.layer][key.y_idx][key.x_idx] = val
}

///|
/// The cost all points in the grid
pub(all) typealias CostGrid = Grid[Int]

///|
/// The all necessary input of a router
pub(all) struct RouteInfo {
  col_size : Int
  row_size : Int
  net_nums : Int
  netlist : Map[Int, Net]
  bend_penalty : Int
  via_penalty : Int
  cost_grid : CostGrid
} derive(Show)

///|
/// Route result maps each net to its path
/// The invariant holds for `netid: Int -> path: Array[Point]`:
///   tow adjacent points in a path only differs in layer or x_idx or y_idx
pub type RouteResult Map[Int, Array[Point]]

///|
pub fn RouteInfo::from_file(
  grid_file : String,
  netlist_file : String
) -> RouteInfo {
  let grid_file_content = @fs.read_file_to_string?(path=grid_file).unwrap()
  let grid_input = Input::from_string(grid_file_content)
  let col_size = grid_input.next_int().unwrap()
  let row_size = grid_input.next_int().unwrap()
  let bend_penalty = grid_input.next_int().unwrap()
  let via_penalty = grid_input.next_int().unwrap()
  let cost_grid = CostGrid::make(row_size, col_size, 0)
  for k = 0; k < 2; k = k + 1 {
    for i = 0; i < col_size; i = i + 1 {
      for j = 0; j < row_size; j = j + 1 {
        cost_grid[Point::new(k, i, j)] = grid_input.next_int().unwrap()
      }
    }
  }
  let netlist_file_content = @fs.read_file_to_string?(path=netlist_file).unwrap()
  let netlist_input = Input::from_string(netlist_file_content)
  let net_nums = netlist_input.next_int().unwrap()
  let netlist = Map::new()
  for i = 0; i < net_nums; i = i + 1 {
    let net_id = netlist_input.next_int().unwrap()
    let l1 = netlist_input.next_int().unwrap()
    let x1 = netlist_input.next_int().unwrap()
    let y1 = netlist_input.next_int().unwrap()
    let l2 = netlist_input.next_int().unwrap()
    let x2 = netlist_input.next_int().unwrap()
    let y2 = netlist_input.next_int().unwrap()
    let start = Point::new(l1 - 1, x1, y1)
    let target = Point::new(l2 - 1, x2, y2)
    // mark the start and end points unroutable
    netlist.set(net_id, Net::{ start, target })
    cost_grid[start] = -1
    cost_grid[target] = -1
  }
  RouteInfo::{
    col_size,
    row_size,
    net_nums,
    netlist,
    bend_penalty,
    via_penalty,
    cost_grid,
  }
}

test "RouteInfo::from_file" {
  ignore(RouteInfo::from_file("bench/bench2.grid", "bench/bench2.nl"))
}

///|
pub fn RouteResult::to_string(self : RouteResult) -> String {
  let sb = StringBuilder::new()
  sb.write_string("\{self._.size()}\n")
  for id, path in @sorted_map.from_iter(self._.iter()) {
    sb.write_string("\{id}\n")
    for i in (0).until(path.length()) {
      if i != 0 && path[i - 1].layer != path[i].layer {
        sb.write_string("3 \{path[i-1].x_idx} \{path[i-1].y_idx}\n")
      }
      sb.write_string("\{path[i]}\n")
    }
    sb.write_string("0\n")
  }
  sb.to_string()
}

test "grid_to_string" {
  let result : RouteResult = Map::from_array([
    (1, [Point::new(0, 4, 2), Point::new(0, 4, 3), Point::new(1, 4, 3)]),
    (2, [Point::new(1, 7, 2), Point::new(0, 7, 2), Point::new(1, 7, 10)]),
  ])
  inspect!(
    result.to_string(),
    content=
      #|2
      #|1
      #|1 4 2
      #|1 4 3
      #|3 4 3
      #|2 4 3
      #|2
      #|2 7 2
      #|3 7 2
      #|1 7 2
      #|3 7 2
      #|2 7 10
      #|0
      #|
    ,
  )
}

///|
pub fn RouteResult::to_file(self : RouteResult, route_file : String) -> Unit {
  @fs.write_string_to_file(path=route_file, content=self.to_string())
}

///|
pub fn RouteResult::sata(self : RouteResult, verbose : Bool) -> RouteResult {
  let mut success = 0
  for id, path in self._ {
    if not(path.is_empty()) {
      success += 1
    }
    if verbose {
      let substr = if path.is_empty() { "SUCCESS" } else { "Failed" }
      println("[\{id}] : \{substr}")
    }
  }
  println("SUCCESS \{success}/\{self._.size()}")
  self
}
