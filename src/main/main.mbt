///|
fn main {
  let args = @sys.get_cli_args()
  if args.length() != 5 {
    println("Usage: moonrun main.wasm <grid_file> <netlist_file> <route_file>")
    @sys.exit(-1)
  }
  let info = @router.RouteInfo::from_file(args[2], args[3])
  let result = @router.CongestionAwareRouter::route(info)
  result.sata(false).to_file(args[4])
}
