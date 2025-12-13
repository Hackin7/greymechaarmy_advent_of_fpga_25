module coprocessor #(
    parameter WIDTH_DIN  = 18*8,
    parameter WIDTH_DOUT = 18*8
)(
    input clk, 
    input rst, 

    input [WIDTH_DIN-1:0] din,
    input din_valid,

    output [WIDTH_DIN-1:0] dout,
    output dout_valid, 

    inout [5:0] control
);

    // Forwarding the Send signals
    reg send = 0;
    always @ (posedge clk) begin
        send <= din_valid;
    end

    assign dout = din; //{ din[7:0], "asdfghjkl"};
    assign dout_valid = send;
endmodule