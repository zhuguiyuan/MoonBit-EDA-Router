# zhuguiyuan/router

This project is an simple congestion-aware EDA router.
It is modified from a project of ShanghaiTech VLSI Design Automation course.

## File format

### Grid file

The grid file specifies the physical grid on which your maze router will search.
It has this format:
- First line: four integers: X grid size (columns), Y grid size (rows),
  the Bend penalty (for use in maze search) and the Via penalty
  (also for use in maze search)
- The next X × Y integers in the file: specify the costs associated with each
  grid cell in LAYER1 of the routing. Most cells will be specified with a 1:
  these are free to route on, and they have unit cost. If a cell has a
  non-uniform cost, it will appear as a positive number.
  If the cell is blocked (you cannot use it to route), it will appear as
  a negative number, specifically a −1
- The final X × Y integers in the file: specify the costs associated with each
  grid in the LAYER2 of the routing, using the same rules as LAYER1
- Grid cell order: We specify the grids in coordinate order: x coordinates from
  0 to X − 1; y coordinates from 0 to Y − 1.

### Netlist file

The netlist file specifies the nets you need to route.
Here are the constraints on our nets, for this project:
- All have just 2 pins. So, these are “2 point” nets.
- We specify a NetID for each net, which is just an integer.
  We specify the nets in NetID order in this input file: 1, 2, 3.. etc
- We specify an (X,Y) coordinate for each pin on each net.
- We specific a layer L=1 or 2, for each pin on each net.
- You route the nets in NetID order, i.e.,
  in the order we specify the nets in this input file.

The file format itself is simple:
- The first line: one integer NetNumber, which is how many nets in this problem.
- The next NetNumber lines: each specifies one net to route.
- To specify each net: Each net is specified with five integers:
  `NetID LayerPin1 Xpin1 Ypin1 LayerPin2 Xpin2 Ypin2`

### Output File Format

Your router will find a path for each net, using the cells in the grids and
maybe some vias. Or, you might not be able to route a net.
Your output tells us what happened with each net you tried to route,
and what path it took.

This is also a simple text file, with the following format:
- First line: One integer, NetNumber, how many nets are in this benchmark.
  This is just the same as in the input netlist file.
- For each net in order 1, 2, ... NetNumber: describe the path each net took.
  - First line: NetID (an integer)
  - Next lines: Describe each cell in the routing path,
     one cell per line of this file.
     Each line is 3 integers: LayerInfo Xcoord Ycoord.
  - LayerInfo: is 0, 1, 2 or 3. If your cell is on Layer1, this is 1;
    if your cell on Layer2, this is 2. If this is a via, put a 3.
    To signal the end of this list, put a 0 on the line with nothing else.

Note that you indicate a net that you could not route
by just have a single line after the NetID with a 0.

