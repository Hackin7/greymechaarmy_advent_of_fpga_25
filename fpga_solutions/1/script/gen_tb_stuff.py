INPUT_FILE_PATH = "../../../proto/1/input_sample.txt"
OUTPUT_FILE_PATH = "../script/tb_aoc.v"

TB_TOP = """`timescale 1ns/1ps
`define CYCLE_DELAY 1
//100
// ChatGPTed, thanks lmao

module tb;
    // Parameters
    localparam WIDTH_DIN  = 16*8;
    localparam WIDTH_DOUT = 16*8;

    // DUT signals
    reg                     clk;
    reg                     rst;
    reg  [WIDTH_DIN-1:0]    din;
    reg                     din_valid;
    wire [WIDTH_DOUT-1:0]   dout;
    wire                    dout_valid;
    wire [5:0]              control_wire;
    reg  [5:0]              control;
    assign control_wire = control;
    // Instantiate DUT
    coprocessor #(
        .WIDTH_DIN(WIDTH_DIN),
        .WIDTH_DOUT(WIDTH_DOUT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid),
        .control(control_wire)
    );

    // Clock: 100 MHz
    always #5 clk = ~clk;

    // Waveform file generation
    initial begin
        // Specify the output file name
        $dumpfile("waveform.vcd");
        // Dump all signals in the current module (and its hierarchy)
        $dumpvars;
    end

    task data_entry(input signed [144-1:0] x);
        @(posedge clk);
        #1;
        // din       = -144'd150;
        din       = x;
        din_valid = 1;
        #`CYCLE_DELAY;

        // Pipeline ////////////////////////////////////////////
        @(posedge clk);
        #1;
        din       = 144'd0;
        din_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
         // give time to finish computing
        //////////////////////////////////////////////////////

        // #10; $display("State: %d %d %d", $time, x, dout); 
    endtask

    // Stimulus
    initial begin
        // Init
        clk       = 1;
        rst       = 1;
        din       = 0;
        din_valid = 0;
        control   = 6'b000100;
        control[3] = 1'b1;

        // Release reset
        //#2100;
        #200;
        rst = 0;
"""

TB_MID = """
        data_entry(0);
        data_entry(0);
        #10; $display("Answer (a): %d", $time, dout);  // Final Answer

        
        rst       = 1;
        #100;
        rst       = 0;
"""
TB_BTM = """
        data_entry(0);
        data_entry(0);
        #10; $display("Answer (b): %d", $time, dout);  // Final Answer

        // Stop driving valid
        @(posedge clk);
        #1;
        din_valid = 0;

        // Let it run a bit
        #50;
        #300;
        $finish;
    end

    // Monitor
    initial begin
        // $display("Time | din_valid | control | din | dout_valid | dout");
        // $monitor("%4t |     %b     | %b | %h |     %b      | %h",
        //          $time, din_valid, control, din, dout_valid, dout);
    end

endmodule
"""

count = 0
position = 50
with open(OUTPUT_FILE_PATH, "w") as ff:
    with open(INPUT_FILE_PATH) as f:
        ff.write(TB_TOP)

        ### Part A
        ff.write("control[3] = 1'b0;") # Part A
        for line in f:
            str_direction = line[0]
            str_number = line[1:].strip()
            sign = 1 if str_direction == "R" else -1
            value = int(str_number) * sign
            ff.write(f"data_entry({value});\n")  
        
        ff.write(TB_MID)

    with open(INPUT_FILE_PATH) as f:
        ### Part B
        ff.write("control[3] = 1'b1;") # Part B
        for line in f:
            str_direction = line[0]
            str_number = line[1:].strip()
            sign = 1 if str_direction == "R" else -1
            value = int(str_number) * sign
            ff.write(f"data_entry({value});\n")
        
        ff.write(TB_BTM)
        