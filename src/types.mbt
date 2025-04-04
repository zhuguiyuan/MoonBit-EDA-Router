///|
/// A point in the route grids
pub(all) struct Point {
  layer : Int
  x_idx : Int
  y_idx : Int
} derive(Eq, Compare, Show)

///|
/// A net connect two pins(points). We need to route all nets.
pub(all) struct Net {
  start : Point
  target : Point
}

///|
pub(all) struct Grid[T] {
  row_size : Int
  col_size : Int
  space : Array[Array[Array[T]]]
} derive(Show)

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
}

///|
/// Route result maps each net to its path
/// The invariant holds for `netid: Int -> path: Array[Point]`:
///   tow adjacent points in a path only differs in layer or x_idx or y_idx
pub type RouteResult Map[Int, Array[Point]]

///|
/// The interface of an EDA router
pub trait Router {
  route(RouteInfo) -> RouteResult
}
