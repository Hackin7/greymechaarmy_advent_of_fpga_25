PROJ=coprocessor

all: ${PROJ}.bit

%.json: src/*.v src/*/*.v
	cat src/*.v src/*/*.v > tmp.v
	yosys -p "synth_ecp5 -top top -json $@" tmp.v

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ --25k --package CABGA256 --lpf pinout.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

sim: 
	iverilog -s tb -o test.vvp src/coprocessor.v test/tb.v
	vvp test.vvp

gtkwave: 
	gtkwave waveform.vcd &


clean:
	rm -f *.svf *.bit *.config *.json tmp.v *.vvp *.vcd

.PHONY: all prog clean
