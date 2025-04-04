///|
fn main {
  let args = @sys.get_cli_args()
  if args.length() != 4 {
    println("Usage: \{args[0]} <grid_file> <netlist_file> <route_file>")
    @sys.exit(-1)
  }
  let info = @router.RouteInfo::from_file(args[1], args[2])
  let result = @router.CongestionAwareRouter::route(info)
  result.sata(false).to_file(args[3])
}
