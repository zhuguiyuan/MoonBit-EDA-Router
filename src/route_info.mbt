///|
pub fn RouteInfo::from_file(
  grid_file : String,
  netlist_file : String
) -> RouteInfo {
  // helper functions
  let parse_int_opt = fn(s) { @strconv.parse_int?(s).to_option() }
  let string_to_ints = fn(s) {
    s
    |> @string.split("\n")
    |> Iter::map(fn(x) {
      @string.split(x.to_string(), " ").filter_map(fn(y) {
        parse_int_opt(y.to_string())
      })
    })
    |> Iter::flatten
    |> Iter::collect
  }
  // grid_file
  let grid_input_numbers = @fs.read_file_to_string?(grid_file)
    .map(string_to_ints)
    .unwrap()
  guard grid_input_numbers
    is [col_size, row_size, bend_penalty, via_penalty, .. others] &&
    col_size * row_size * 2 == others.length()
  let cost_grid = CostGrid::make(row_size, col_size, 0)
  let mut idx = 0
  for l in 0..<2 {
    for y in 0..<row_size {
      for x in 0..<col_size {
        cost_grid[Point::new(l, x, y)] = others[idx]
        idx += 1
      }
    }
  }
  // netlist_file
  let netlist_input_numbers = @fs.read_file_to_string?(netlist_file)
    .map(string_to_ints)
    .unwrap()
  guard netlist_input_numbers is [net_nums, .. others]
  let mut others_mut = others
  let netlist = Map::new()
  for i in 0..<net_nums {
    guard others_mut is [net_id, l1, x1, y1, l2, x2, y2, .. others]
    others_mut = others
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

///|
test "RouteInfo::from_file" {
  ignore(RouteInfo::from_file("bench/bench2.grid", "bench/bench2.nl"))
}
