`timescale 1ns/1ns
`include "uart_tx/uart_tx.sv"
`include "uart_rx/uart_rx.sv"
`include "../fifo/fifo.sv"
module uart_tx_rx_tb();

    parameter CLK_PERIOD_NS         = 10; // Clk period of 10Mhz
    parameter HALF_CLK_PERIOD_NS    = CLK_PERIOD_NS/2;
    parameter NCLKS_PER_BIT         = 87; // (Freq/Baud Rate)
    parameter PERIOD_PER_BIT        = NCLKS_PER_BIT*CLK_PERIOD_NS;

    logic clk, rst;
    logic [7:0] axis_in_tdata;
    logic       axis_in_tvalid;
    logic       tx_data;
    logic       tx_busy;
    logic       tx_done;

    // Ouput AXI-Stream Interface (Output RX, should match original data)
    logic [7:0] axis_out_tdata;
    logic       axis_out_tvalid;

    // Input UART Interface
    logic       rx_data;

    logic fifo_full, fifo_empty;

    uart_tx #(
        .NCLKS_PER_BIT(NCLKS_PER_BIT)
    ) uart_tx_0 (
        .clk(clk),
        .rst(rst),
        .axis_in_tdata(axis_in_tdata),
        .axis_in_tvalid(axis_in_tvalid),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    uart_rx #(
        .NCLKS_PER_BIT(NCLKS_PER_BIT)
    ) uart_rx_0 (
        .clk(clk),
        .rst(rst),
        .axis_out_tdata(axis_out_tdata),
        .axis_out_tvalid(axis_out_tvalid),
        .rx_data(tx_data)
    );

    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        $dumpfile("waves.fst");
        $dumpvars(0, uart_tx_rx_tb);

        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        
        repeat(20) begin
            axis_in_tvalid = 1'b1;
            axis_in_tdata  = $urandom_range(0, 255); @(posedge clk); 
            axis_in_tvalid = 1'b0;

            #(10*PERIOD_PER_BIT);
        end
        
        #1000;
        $finish();
    end
endmodule