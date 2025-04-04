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
