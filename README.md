# GreyMecha/Army Advent of FPGA 2025

For code template check out `uart_coprocessor`

### Running the Solution

The solutions are meant ot run on the GreyMecha/Army FPGA board. Nevertheless, you can run them through the testbench as such

```
cd fpga_solutions/1/uart_coprocessor
make sim
make gtkwave
```

For generating bitstream, run `make` and copy the bitstream over

For running the app on greymecha follow the instructions in `greymecha_app/`
