///|
/// The interface of an EDA router
pub trait Router {
  route(RouteInfo) -> RouteResult
}

///|
/// Directions to use in the router
priv enum Direction {
  X_POS
  X_NEG
  Y_POS
  Y_NEG
  L_POS
  L_NEG
  NIL
} derive(Eq, Show)

///|
/// Helper function to convert a direction to a vector
fn Direction::to_diff(self : Direction) -> (Int, Int, Int) {
  match self {
    L_POS => (1, 0, 0)
    L_NEG => (-1, 0, 0)
    X_POS => (0, 1, 0)
    X_NEG => (0, -1, 0)
    Y_POS => (0, 0, 1)
    Y_NEG => (0, 0, -1)
    NIL => (0, 0, 0)
  }
}

///|
/// Get next point in this direction
fn Point::next(self : Point, to : Direction) -> Point {
  let (dl, dx, dy) = to.to_diff()
  Point::new(self.layer + dl, self.x_idx + dx, self.y_idx + dy)
}

///|
/// Get previous point in this direction
fn Point::prev(self : Point, to : Direction) -> Point {
  let (dl, dx, dy) = to.to_diff()
  Point::new(self.layer - dl, self.x_idx - dx, self.y_idx - dy)
}

///|
/// We use this type to extract the path
typealias DirectionGrid = Grid[Direction]

///|
/// Extract the path of a routed net from given direction grid
fn extract_path(direction_grid : DirectionGrid, net : Net) -> Array[Point] {
  let rev_result = []
  let { start, target } = net
  let mut curr = target
  while curr != start {
    rev_result.push(curr)
    curr = curr.prev(direction_grid[curr])
  }
  rev_result.push(start)
  return rev_result.rev()
}

///|
test "extract_path" {
  let directions = DirectionGrid::make(2, 2, X_POS)
  let net = { start: Point::new(0, 0, 0), target: Point::new(0, 1, 0) }
  inspect!(
    extract_path(directions, net),
    content="[{layer: 0, x_idx: 0, y_idx: 0}, {layer: 0, x_idx: 1, y_idx: 0}]",
  )
}

///|
/// Whether a point is in the working_grid boundary
fn in_boundary(point : Point, working_grid : CostGrid) -> Bool {
  let x_max = working_grid.col_size
  let y_max = working_grid.row_size
  0 <= point.layer &&
  point.layer < 2 &&
  0 <= point.x_idx &&
  point.x_idx < x_max &&
  0 <= point.y_idx &&
  point.y_idx < y_max
}

///|
/// Can route on the given point (in the range of grid and not blocked)
fn can_route(point : Point, working_grid : CostGrid) -> Bool {
  in_boundary(point, working_grid) && working_grid[point] != -1
}

///|
/// Deep copy a cost grid
fn copy_cost_grid(self : CostGrid) -> CostGrid {
  let other = CostGrid::make(self.row_size, self.col_size, 0)
  for k = 0; k < 2; k = k + 1 {
    for i = 0; i < self.col_size; i = i + 1 {
      for j = 0; j < self.row_size; j = j + 1 {
        let pos = Point::new(k, i, j)
        other[pos] = self[pos]
      }
    }
  }
  other
}

///|
priv type Wavefront (Double, Point) derive(Show, Eq)

///|
impl Compare for Wavefront with compare(self, other) -> Int {
  -self._.compare(other._)
}

///|
/// Find a path with BFS + A* + direction_suggestion + via and bend penalty
fn find_path(info : RouteInfo, net : Net) -> Array[Point] {
  // Copy the origin cost_grid to avoid modifying it
  let working_grid = copy_cost_grid(info.cost_grid)
  let directions = [X_POS, X_NEG, Y_POS, Y_NEG, L_POS, L_NEG]
  let direction_grid = DirectionGrid::make(
    working_grid.row_size,
    working_grid.col_size,
    NIL,
  )
  let { start, target } = net
  working_grid[start] = -1
  working_grid[target] = 1
  let wavefronts = @priority_queue.of([Wavefront((1.0, start))])
  while not(wavefronts.is_empty()) {
    let Wavefront((curr_cost, curr_point)) = wavefronts.pop().unwrap()
    if curr_point == target {
      return extract_path(direction_grid, net)
    }
    for next_direction in directions {
      let next_point = curr_point.next(next_direction)
      if not(can_route(next_point, working_grid)) {
        continue
      }
      // cost for BFS algorithm
      let basic_cost = curr_cost + Double::from_int(working_grid[next_point])
      // cost for A* algorithm
      let a_start_cost = curr_point.l1_distance(target)
      // cost for direction suggestion
      let layer_cost = layer_cost(next_point, next_direction, info.via_penalty)
      let curr_direction = direction_grid[curr_point]
      // cost for change direction
      let bend_cost = if [X_POS, Y_POS, X_NEG, Y_NEG].contains(next_direction) &&
        curr_direction != NIL &&
        next_direction != curr_direction {
        info.bend_penalty
      } else {
        0
      }
      // cost for crossing two layers
      let via_cost = if [L_NEG, L_POS].contains(next_direction) {
        info.via_penalty
      } else {
        0
      }
      // total cost
      let next_cost = basic_cost +
        Double::from_int(a_start_cost + layer_cost + bend_cost + via_cost)
      wavefronts.push((next_cost, next_point))
      working_grid[next_point] = -1
      direction_grid[next_point] = next_direction
    }
  }
  // failed to route
  return []
}

///|
/// Penalty to suggest nets route along Y aixs in layer 0 and X axis in layer 1
fn layer_cost(point : Point, direction : Direction, penalty : Int) -> Int {
  if (point.layer == 0 && (direction == X_NEG || direction == X_POS)) ||
    (point.layer == 1 && (direction == Y_POS || direction == Y_NEG)) {
    penalty
  } else {
    0
  }
}

///|
/// Enhance the cost grid inplace based on the congestion level
fn enhance_cost_grid(grid : CostGrid, penalty : Int) -> Unit {
  for k = 0; k < 2; k = k + 1 {
    for i = 0; i < grid.col_size; i = i + 1 {
      for j = 0; j < grid.row_size; j = j + 1 {
        let curr = Point::new(k, i, j)
        if grid[curr] == -1 {
          for direction in [X_POS, X_NEG, Y_POS, Y_NEG, L_POS, L_NEG] {
            let next = curr.next(direction)
            if can_route(next, grid) {
              grid[next] += penalty
            }
          }
        }
      }
    }
  }
}

///|
pub(all) type CongestionAwareRouter

///|
pub impl Router for CongestionAwareRouter with route(info : RouteInfo) -> RouteResult {
  enhance_cost_grid(info.cost_grid, 3 * info.via_penalty)
  let result = RouteResult(Map::new())
  fn compare_length(id1 : Int, id2 : Int) -> Int {
    let net1 = info.netlist[id1].unwrap()
    let net2 = info.netlist[id2].unwrap()
    net1.start.l1_distance(net1.target) - net2.start.l1_distance(net2.target)
  }

  let ordered_net_ids = info.netlist.keys().collect()
  ordered_net_ids.sort_by(compare_length)
  for net_id in ordered_net_ids {
    let path = find_path(info, info.netlist[net_id].unwrap())
    result._[net_id] = path
    for p in path {
      info.cost_grid[p] = -1
    }
  }
  result
}
