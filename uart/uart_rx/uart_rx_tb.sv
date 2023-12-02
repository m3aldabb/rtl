`timescale 1ns / 1ns
module uart_rx_tb();

parameter CLK_FREQ          = 25; // In MHz
parameter BAUD_RATE         = 115200;
parameter CLK_PERIOD        = 1000/CLK_FREQ; // In ns
parameter HALF_CLK_PERIOD   = CLK_PERIOD/2;

parameter NCLKS_PER_BIT     = (CLK_FREQ*1000000) / BAUD_RATE;

parameter NUM_ITRS          = 1;

logic   clk;
logic   rst;

logic   axis_out_tvalid;
logic   [7:0] axis_out_tdata;

logic   rx_data;
logic   tx_busy;
logic   tx_done;

logic   [7:0]   rand_byte;

uart_rx #(
    .NCLKS_PER_BIT(NCLKS_PER_BIT)
) dut (
    .clk            ( clk ),
    .rst            ( rst ),

    .axis_out_tvalid ( axis_out_tvalid ),
    .axis_out_tdata  ( axis_out_tdata  ),

    .rx_data        ( rx_data )
);

always #HALF_CLK_PERIOD clk = ~clk;

initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, uart_rx_tb);

    rst = 1'b0;
    clk = 1'b0;
    rx_data = 1'b1;

    @(posedge clk);
    rst = 1'b1;
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    repeat(NCLKS_PER_BIT) @(posedge clk);

    rx_data = 1'b0;
    repeat(NCLKS_PER_BIT) @(posedge clk);

    rand_byte = $urandom_range(0, 255);
    for(int i = 0; i<8; i++) begin
        rx_data = rand_byte[i];
        repeat(NCLKS_PER_BIT) begin
            @(posedge clk);
        end
    end
    
    #10000;
    $finish();
end
endmodule