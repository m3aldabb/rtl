`timescale 1ns / 1ns
module uart_tx_tb();

parameter CLK_FREQ          = 25; // In MHz
parameter BAUD_RATE         = 115200;
parameter CLK_PERIOD        = 1000/CLK_FREQ; // In ns
parameter HALF_CLK_PERIOD   = CLK_PERIOD/2;

parameter NCLKS_PER_BIT     = (CLK_FREQ*1000000) / BAUD_RATE;

parameter NUM_ITRS          = 1;

logic   clk;
logic   rst;

logic   axis_in_tvalid;
logic   [7:0] axis_in_tdata;

logic   tx_data;
logic   tx_busy;
logic   tx_done;

uart_tx #(
    .NCLKS_PER_BIT(NCLKS_PER_BIT)
) dut (
    .clk            ( clk ),
    .rst            ( rst ),

    .axis_in_tvalid ( axis_in_tvalid ),
    .axis_in_tdata  ( axis_in_tdata  ),

    .tx_data        ( tx_data ),
    .tx_done        ( tx_done ),
    .tx_busy        ( tx_busy )
);

always #HALF_CLK_PERIOD clk = ~clk;

initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, uart_tx_tb);

    rst = 1'b0;
    clk = 1'b0;

    @(posedge clk);
    rst = 1'b1;
    @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    // fork
    //     begin
    //         repeat(NUM_ITRS) begin
    //             axis_in_tvalid  = 1'b1;
    //             axis_in_tdata   = $urandom_range(0, 255);
    //             wait(tx_busy);

    //             axis_in_tvalid  = 1'b0;
    //             axis_in_tdata   = 'X;
    //             wait(tx_done);
    //         end
    //     end

    //     begin
    //         while(~tx_done) @(posedge clk);
    //     end
    // join

    axis_in_tvalid  = 1'b1;
    axis_in_tdata   = $urandom_range(0, 255);
    @(posedge clk);

    axis_in_tvalid  = 1'b0;

    #1000000;

    repeat(NCLKS_PER_BIT) @(posedge clk);
    #100;
    $finish();
end
endmodule