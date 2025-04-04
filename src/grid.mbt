///|
/// Construct a `CostGrid` with given size and initial value
fn Grid::make[T](row_size : Int, col_size : Int, val : T) -> Grid[T] {
  let space = Array::make(2 * row_size * col_size, val)
    .chunks(col_size)
    .chunks(row_size)
  { row_size, col_size, space }
}

///|
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
