`timescale 1ps/1ps
`include "alarm_system.sv"

module alarm_system_tb();


    // Constants and Parameters
    localparam IN_A = 4'b0001;
    localparam IN_B = 4'b0010;
    localparam IN_C = 4'b0100;
    localparam IN_D = 4'b1000;


    // Signals
    logic           clk;
    logic           rst;
    logic   [3:0]   din;
    logic   [2:0]   status;
    logic   [3:0]   chars;


    // DUT instance
    alarm_system dut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .status(status),
        .chars(chars)
    );


    // Generating input clock
    always #5 clk = ~clk;


    // Driving stimulus
    initial begin
        $dumpfile("waves.fst");
        $dumpvars(0, alarm_system_tb);

        rst = 1'b0;
        clk = 1'b0;

        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        din = IN_A;
        @(posedge clk);
        din = IN_B;
        @(posedge clk);
        din = IN_C;
        @(posedge clk);
        din = IN_D;
        @(posedge clk);

        din = '0;
        @(posedge clk);

        @(posedge clk);

        din = IN_A;
        @(posedge clk);
        din = IN_B;
        @(posedge clk);
        din = IN_C;
        @(posedge clk);
        din = IN_D;
        @(posedge clk);

        din = '0;
        @(posedge clk);

        din = IN_A;
        @(posedge clk);
        din = IN_A;
        @(posedge clk);
        din = IN_C;
        @(posedge clk);
        din = IN_D;
        @(posedge clk);

        din = '0;
        @(posedge clk);

        $finish();
    end
endmodule