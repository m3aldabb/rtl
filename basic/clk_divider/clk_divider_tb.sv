`timescale 1ns /1ns
`include "clk_divider.sv"
module clk_divider_tb();
  logic clk100, clk90, rst;
  logic clk_out;
  logic test_clk50, test_clk25, test_clk30;
  
  always #5 clk100 = ~clk100;
  always #5.56 clk90 = ~clk90;
  
  initial begin
    test_clk50 = 1'b0;
    #35;
    while(1) begin
        test_clk50 = 1'b1;
        #10;
        test_clk50 = 1'b0;
        #10;
    end
  end

  initial begin
    test_clk25 = 1'b0;
    #25;
    while(1) begin
        test_clk25 = 1'b1;
        #20;
        test_clk25 = 1'b0;
        #20;
    end
  end
  
  initial begin
    test_clk30 = 1'b0;
    #30;
    while(1) begin
        test_clk30 = 1'b1;
        #16.6665;
        test_clk30 = 1'b0;
        #16.6665;
    end
  end
  
  
  clk_divider #(62500000) dut (
    .clk_in(clk100),
    .rst(rst),
    .clk_out(clk_out)
  );
  
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars();
        clk100 = 1'b0;
        clk90 = 1'b0;

        rst = 1'b0;

        @(posedge clk100);
        rst = 1'b1;
        @(posedge clk100);
        rst = 1'b0;

        #1000;
        $finish;
    end
  
endmodule