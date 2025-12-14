
module coprocessor #(
    parameter WIDTH_DIN  = 16*8,
    parameter WIDTH_DOUT = 16*8, 
    parameter WIDTH_COMPUTE = 32
)(
    input clk, 
    input rst, 

    input [WIDTH_DIN-1:0] din,
    input din_valid,

    output [WIDTH_DOUT-1:0] dout,
    output dout_valid, 

    inout [5:0] control
);  

    wire clk_slow = clk;
    wire [WIDTH_DIN-1:0] din_ext = din;
    wire                 din_valid_ext = din_valid;

    // //// Configurations ////////////////////////////////////////////////////////////////////
    // reg [31:0] clk_stepdown_counter = 0;
    // reg [31:0] clk_stepdown_count_val = 50;
    // reg clk_slow = 1;
    // always @ (posedge clk) begin
    //     clk_stepdown_counter <= clk_stepdown_counter + 1;
    //     if (clk_stepdown_counter >= clk_stepdown_count_val) begin
    //         clk_slow <= ~clk_slow;
    //         clk_stepdown_counter <= 0;
    //     end
    // end

    // //// Computation /////////////////////////////////////

   
    // //// CDC Problem LOL - Downscaling clock by 100 times //////////////////////////////////
    // // Pulse Extender
    // reg [WIDTH_DIN-1:0] din_ext = 0;
    // reg         din_valid_ext = 0;
    // reg  [31:0] din_valid_ext_counter = 0;
    // wire [31:0] din_valid_ext_count_val = 100;
    // always @(posedge clk) begin
    //     if (rst) begin
    //         din_valid_ext_counter <= 0;
    //         din_valid_ext <= 0;
    //         din_ext       <= 0;
    //     end else if (din_valid) begin
    //         din_valid_ext_counter <= 1;
    //         din_valid_ext <= 1;
    //         din_ext       <= din;
    //     end else if (din_valid_ext_counter == din_valid_ext_count_val) begin
    //         din_valid_ext_counter <= 0;
    //         din_valid_ext <= 0;
    //     end else if (din_valid_ext_counter != 0) begin
    //         din_valid_ext_counter <= din_valid_ext_counter + 1;
    //         din_valid_ext <= 1;
    //     end
    // end

    
    //// "Stage" 1: Data Input (to reduce crit path length) ///////////////////////////////
    reg [WIDTH_DIN-1:0] din_dly = 0;
    always @(posedge clk_slow) begin
        if (rst) begin
            din_dly <= 0;
        end else if (din_valid_ext) begin
            din_dly  [WIDTH_DIN-1:0] <= din_ext[WIDTH_DIN-1:0];
        end
    end
    //// "Stage" 2: Calc position ///////////////////////////////////////////////////////
    reg [WIDTH_COMPUTE-1:0] calc_position = 0;
    reg [WIDTH_COMPUTE-1:0] calc_final_position = 0;
    reg [2:0]               calc_position_state = 0; // 0 - idle, 1 - calculating
    always @(posedge clk_slow) begin
        
        if (rst) begin
            calc_position       <= 50;
            calc_final_position <= 50;
            calc_position_state <= 0;
        end else if (calc_position_state == 1) begin // restoring lmao
            if (calc_position[31]) begin
                calc_position <= calc_position + 100;
            end else if (calc_position >= 100) begin
                calc_position <= calc_position - 100;
            end else begin
                calc_position_state <= 2;
            end
        end else if (din_valid_ext) begin
            calc_position       <= (calc_position + din_dly[WIDTH_COMPUTE-1:0]); 
            calc_position_state <= 1;
        end else begin
            calc_position_state <= 0;
        end
    end

    
    
    //// "Stage" 3: Calc count ///////////////////////////////////////////////////////
    reg [WIDTH_COMPUTE-1:0] calc_count = 0;
    always @(posedge clk_slow) begin
        if (rst) begin
            calc_count          <= 0;
        end else if (calc_position_state == 2) begin
            calc_count    <= calc_count + (calc_position == 0);
        end
    end
    // Forwarding the Send signals out
    reg send = 0;
    always @(posedge clk_slow) begin
        send <= din_valid_ext;
        // send <= (calc_position_state == 2);
    end

    wire [WIDTH_DIN-1:0] out = (
        control[2:0] == 3'b000 ? din :
        control[2:0] == 3'b001 ? din_dly :
        control[2:0] == 3'b010 ? { {96{calc_position[31]}}, calc_position[31:0]} :
        //control[2:0] == 3'b011 ? { {96{calc_final_position[31]}}, calc_final_position[31:0]} :
                                calc_count // This is the answer
    );

    //// routing out /////////////////////////////////////
    assign dout = out;
    assign dout_valid = send;
endmodule