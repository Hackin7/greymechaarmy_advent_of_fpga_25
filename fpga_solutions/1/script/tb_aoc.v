`timescale 1ns/1ps
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
control[3] = 1'b0;data_entry(-68);
data_entry(-30);
data_entry(48);
data_entry(-5);
data_entry(60);
data_entry(-55);
data_entry(-1);
data_entry(-99);
data_entry(14);
data_entry(-82);

        data_entry(0);
        data_entry(0);
        #10; $display("Answer (a): %d", $time, dout);  // Final Answer

        
        rst       = 1;
        #100;
        rst       = 0;
control[3] = 1'b1;data_entry(-68);
data_entry(-30);
data_entry(48);
data_entry(-5);
data_entry(60);
data_entry(-55);
data_entry(-1);
data_entry(-99);
data_entry(14);
data_entry(-82);

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
