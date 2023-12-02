`timescale 1ns/1ns
`include "debounce.sv"
module debounce_tb();
    logic clk, rst;
    logic din, dout;

    debounce dut (clk, rst, din, dout);

    always #5 clk = ~clk;
    initial begin
        $dumpfile("waves.fst");
        $dumpvars();

        rst = 1'b0;
        clk = 1'b0;

        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        din = 1'b1; #1; din = 1'b0; #2 din = 1'b1; #1 din = 1'b0;
        @(posedge clk);

        din = 1'b1;
        repeat(10) @(posedge clk);
        din = 1'b0;
        @(posedge clk);

        din = 1'b1;
        repeat(5) @(posedge clk);
        din = 1'b0;

        @(posedge clk);
        #1000000;
        $finish();
    end
endmodule