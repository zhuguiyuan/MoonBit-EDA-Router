///|
pub fn RouteResult::to_string(self : RouteResult) -> String {
  let sb = StringBuilder::new()
  sb.write_string("\{self._.size()}\n")
  for id, path in @sorted_map.from_iter(self._.iter()) {
    sb.write_string("\{id}\n")
    for i in 0..<path.length() {
      if i != 0 && path[i - 1].layer != path[i].layer {
        sb.write_string("3 \{path[i-1].x_idx} \{path[i-1].y_idx}\n")
      }
      sb.write_string("\{path[i].to_string()}\n")
    }
    sb.write_string("0\n")
  }
  sb.to_string()
}

///|
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
      #|0
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
  match @fs.write_string_to_file?(route_file, self.to_string()) {
    Err(_) => panic()
    Ok(_) => ()
  }
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
