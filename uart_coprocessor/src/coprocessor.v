module coprocessor #(
    parameter WIDTH_DIN  = 18*8,
    parameter WIDTH_DOUT = 18*8
)(
    input clk, 
    input rst, 

    input [WIDTH_DIN-1:0] din,
    input din_valid,

    output [WIDTH_DOUT-1:0] dout,
    output dout_valid, 

    inout [5:0] control
);  
    //// Computation /////////////////////////////////////

    // Forwarding the Send signals out
    reg send = 0;
    always @ (posedge clk) begin
        send <= din_valid;
    end

    reg [WIDTH_DIN-1:0] prev_din_2;
    reg [WIDTH_DIN-1:0] prev_din;
    always @ (posedge clk) begin
        if (din_valid) begin
            prev_din_2[WIDTH_DIN-1:0] <= prev_din[WIDTH_DIN-1:0];
            prev_din  [WIDTH_DIN-1:0] <= din[WIDTH_DIN-1:0];
        end
    end
    wire [WIDTH_DIN-1:0] out = (
        control[0] ? din :
        control[1] ? prev_din_2 :
                     (prev_din + din)
    );

    //// routing out /////////////////////////////////////
    assign dout = out; //{ din[7:0], "asdfghjkl"};
    assign dout_valid = send;
endmodule