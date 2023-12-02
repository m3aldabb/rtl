// Parametrizable clock divider, works for even or odd values of DIV.
// Produce 'clk_out' such that it has the frequency of 'clk_in' divided by DIV.

module clk_divider #(parameter DIV) (
  input rst,
  input clk_in,
  output clk_out
);
  
  logic even;
  assign even = (DIV%2 == 0);

  logic [$clog2(DIV)-1:0] pos_count;
  logic [$clog2(DIV)-1:0] neg_count;
  
  always_ff @(posedge clk_in or posedge rst) begin
    if(rst) begin
        pos_count <= '0;
    end else begin
        pos_count <= (pos_count == (DIV-1)) ? '0 : pos_count + 1;
    end
  end
  
  always_ff @(negedge clk_in or posedge rst) begin
    if(rst) begin
        neg_count <= '0;
    end else begin
        neg_count <= (neg_count == (DIV-1)) ? '0 : neg_count + 1;
    end
  end
  
  assign clk_out = (rst) ? 1'b0 : (even) ? ((pos_count < (DIV/2)) ? 1'b1 : 1'b0) : ( (pos_count > DIV>>1) || (neg_count > DIV>>1));
 endmodule
