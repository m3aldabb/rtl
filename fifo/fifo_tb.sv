`include "fifo.sv"
`timescale 1ps/1ps

module fifo_tb();

    parameter                   DEPTH = 4;
    parameter                   DATA_WIDTH = 4;

    logic                       clk;
    logic                       rst;

    logic                       wr;
    logic                       rd; 

    logic           [DATA_WIDTH-1:0]    data_in;
    logic           [DATA_WIDTH-1:0]    data_out;

    logic                      full;
    logic                      empty;


    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr(wr),
        .rd(rd),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    logic   [DATA_WIDTH-1:0]    dut_output [$];
    logic   [DATA_WIDTH-1:0]    golden_output[$];    
    logic   [DATA_WIDTH-1:0]    rand_data;               

    task init();
        rst     = 1'b0;
        clk     = 1'b0;
        wr      = 1'b0;
        rd      = 1'b0;
        data_in = '0;

        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;
    endtask

    task fifo_write(input logic [DATA_WIDTH-1:0] rand_data);
        wr = 1'b1;

        @(posedge clk);
        data_in = rand_data;
        if(!full) golden_output.push_back(rand_data);
        @(posedge clk);
        wr = 1'b0;
    endtask

    task fifo_read();
        rd = 1'b1;
        @(posedge clk)
        dut_output.push_back(data_out);
        rd = 1'b0;
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, fifo_tb);

        init();
        
        repeat(3) begin
            rand_data = $urandom();
            fifo_write(rand_data);
            fifo_read();
        end

        repeat(3) begin
            rand_data = $urandom();
            repeat(2) fifo_write(rand_data);
            fifo_read();
        end

        if(golden_output.size() != dut_output.size()) begin
            $display("TEST FAILED: Reference data size does not match DUT output.");
            $finish();
        end
        for(int i = 0; i < golden_output.size(); i++) begin
            if(golden_output[i] != dut_output[i]) begin
                $display("TEST FAILED: Reference data does not match DUT output.");
                $finish();
            end
        end

        $display("TEST PASSED!");
        
        $finish();
    end
endmodule