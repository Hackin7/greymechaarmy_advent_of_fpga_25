
module coprocessor #(
    parameter WIDTH_DIN  = 16*8,
    parameter WIDTH_DOUT = 16*8
)(
    input clk, 
    input rst, 

    input [WIDTH_DIN-1:0] din,
    input din_valid,

    output [WIDTH_DOUT-1:0] dout,
    output dout_valid, 

    inout [5:0] control
);  
    //// Configurations ////////////////////////////////////////////////////////////////////
    reg [31:0] clk_stepdown_counter = 0;
    reg [31:0] clk_stepdown_count_val = 50;
    reg clk_slow = 1;
    always @ (posedge clk) begin
        clk_stepdown_counter <= clk_stepdown_counter + 1;
        if (clk_stepdown_counter >= clk_stepdown_count_val) begin
            clk_slow <= ~clk_slow;
            clk_stepdown_counter <= 0;
        end
    end

    //// Computation /////////////////////////////////////

    // Forwarding the Send signals out
    reg send = 0;
    always @(posedge clk) begin
        send <= din_valid;
    end


    //// CDC Problem LOL - Downscaling clock by 100 times //////////////////////////////////
    // Pulse Extender
    reg [WIDTH_DIN-1:0] din_ext = 0;
    reg         din_valid_ext = 0;
    reg  [31:0] din_valid_ext_counter = 0;
    wire [31:0] din_valid_ext_count_val = 100;
    always @(posedge clk) begin
        if (rst) begin
            din_valid_ext_counter <= 0;
            din_valid_ext <= 0;
            din_ext       <= 0;
        end else if (din_valid) begin
            din_valid_ext_counter <= 1;
            din_valid_ext <= 1;
            din_ext       <= din;
        end else if (din_valid_ext_counter == din_valid_ext_count_val) begin
            din_valid_ext_counter <= 0;
            din_valid_ext <= 0;
        end else if (din_valid_ext_counter != 0) begin
            din_valid_ext_counter <= din_valid_ext_counter + 1;
            din_valid_ext <= 1;
        end
    end


    //// "Stage" 1: Data Input (to reduce crit path length) ///////////////////////////////
    reg [WIDTH_DIN-1:0] din_dly = 0;
    always @(posedge clk_slow) begin
        if (rst) begin
            din_dly <= 0;
        end else if (din_valid_ext) begin
            din_dly  [WIDTH_DIN-1:0] <= din_ext[WIDTH_DIN-1:0];
        end
    end
    //// "Stage" 2, 3: Calc position ///////////////////////////////////////////////////////
    reg [WIDTH_DIN-1:0] calc_position = 0;
    reg [WIDTH_DIN-1:0] calc_final_position = 0;
    reg [WIDTH_DIN-1:0] calc_count = 0;
    always @(posedge clk_slow) begin
        if (rst) begin
            calc_position <= 50;
            calc_final_position <= 50;
            calc_count    <= 0;
        end else if (din_valid_ext) begin
            calc_position <= (calc_final_position + din_dly); // % 100; // lmao hope % is synthesizable
            calc_final_position <= calc_position; // % 100;
            calc_count    <= calc_count + (calc_final_position == 0);
        end
    end
    

    wire [WIDTH_DIN-1:0] out = (
        control[0] ? din :
        control[1] ? calc_position :
        control[2] ? calc_final_position :
                     calc_count // This is the answer
    );

    //// routing out /////////////////////////////////////
    assign dout = out;
    assign dout_valid = send;
endmodule