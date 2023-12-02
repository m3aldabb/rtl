`include "../clk_divider/clk_divider.sv"
`include "../dff/dff.sv"
`include "../edge_detect/edge_detect.sv"
module debounce (
    input clk,
    input rst,
    input din,
    output dout
);

// Make this a lower value for simulation so you can actually see something in the waves.
parameter DIV = 31_250_000;

logic slow_clk; // 4MHz clock
clk_divider #(
    .DIV(DIV)
) clk_divider_0 (
    .clk_in(clk),
    .clk_out(slow_clk),
    .rst(rst)
);

logic q0, q1, q2;
dff dff_0 (slow_clk, rst, din, q0);
dff dff_1 (slow_clk, rst,  q0, q1);
dff dff_2 (slow_clk, rst,  q1, q2);

edge_detect edge_detect_0 (
    .clk(clk),
    .rst(rst),
    .din(q2),
    .o_pedge_pulse(dout)
);

endmodule