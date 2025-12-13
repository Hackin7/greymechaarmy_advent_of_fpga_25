/*
Top module structure

Interconnect Pins
- Pins[0, 1] -> UART TX RX
- Pins[2] -> Valid Data Input (Pulse in the data) (in to FPGA)
- Pins[3] -> Valid Received Data (out from FPGA)
*/


module top(input clk_ext, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    /// Internal Configuration ///////////////////////////////////////////
    wire clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk = clk_int;
    localparam CLK_FREQ = 103_340_000; // EXT CLK

    reg [31:0] clk_stepdown_counter = 0;
    reg [31:0] clk_stepdown_count_val = 10;
    reg clk_slow = 0;
    always @ (posedge clk) begin
        clk_stepdown_counter <= clk_stepdown_counter + 1;
        if (clk_stepdown_counter >= clk_stepdown_count_val) begin
            clk_slow <= ~clk_slow;
            clk_stepdown_counter <= 0;
        end
    end

    // Coprocessor /////////////////////////////////////////////////
    
    /// UART ////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 18;

    wire reset = ~btn[2];
    wire rx;
    wire tx    = interconnect[1];
    wire [UART_FRAME_SIZE*DBITS-1:0] uart_rx_out;
    reg  [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out = "asdfghjkl";
    reg                              uart_tx_controller_send = 0;
    wire rx_full, rx_empty;
    // Complete UART Core
    uart_top 
        #(
            .FIFO_IN_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE_EXP(32)
        ) 
        UART_UNIT
        (
            .clk_100MHz  (clk),
            .reset       (reset),
            
            .rx          (interconnect[0]),
            .tx          (tx),
            
            .rx_full     (rx_full),
            .rx_empty    (rx_empty),
            .rx_out      (uart_rx_out),
            
            .tx_trigger  (uart_tx_controller_send | ~btn[1]),
            .tx_in       (uart_tx_out) 
        );

    /// Control Logic ///////////////////////////////////////////////
    // task uart_decoder_reset();
    // endtask
    // task uart_decoder();
    // endtask

    always @ (posedge clk_slow) begin
        // uart_decoder_reset();
        // uart_decoder();
    end 

    // https://gchq.github.io/CyberChef/#recipe=To_Hex('Space',0)Find_/_Replace(%7B'option':'Regex','string':'%20'%7D,',%208%5C'h',true,false,true,false)&input=e2hpX2knbV95b3VyX2FybXl9
    
    assign led = (
        ~btn[4] ? uart_rx_out[8*(1)-1:8*(0)] :
        ~btn[3] ? uart_rx_out[8*(2)-1:8*(1)] :
        ~btn[2] ? interconnect : 
        uart_rx_out[8*(1)-1:8*(0)] 
    );

endmodule
