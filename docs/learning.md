# My Learning Path

## In this file I will document my learning process of the design flow


### Flow:
- Start by forking the Verilog template, then install all of the tools required for local hardening and testing.
- As of writing, it seems it's best to stick to plain Verilog rather than SystemVerilog, as support is limited and problems which are difficult to debug may arise.
- Don't try to see if the design passes GDS by pushing to Github, run it locally before.
- Install the complete OSS CAD suite to ensure compatibility between the different tools.
- Get help from the Discord community when stuck, they are very helpful.
- Looking at projects from previous shuttles can help improve understanding of the project structure.

### RTL:
- Avoid massive combinational asynchronous logic, and prefer sequential logic operations. It makes a massive difference in the required chip area, and allows for higher density.
- Avoid complicated memory structures such as 2D arrays if possible, and prefer simpler alternatives such as 1D vectors.
- Seperate complicated logic to individual components for better reusablity and code clarity.
- Tried routing the board data across the design with a 2 bit bus and by addressing the index, and that shrunk the required chip area by alot. Then changed it to be routed as a 128 bit bus, and the wire length increased heavily. Routing big busses to multiple instances can lead to using a lot of area on the chip.

### Testing
- Write tests suitable for gate level testing from the get go.
- Utilize python and cocotb to their full potential, for example by using helper functions and classes.
- To have access to internal signals in gate level testing, creating a "debug" component is very useful. It can be connected to the top module and internal signals, and can access IOs to which it can write internal data making it accessible in cocotb testbenches.