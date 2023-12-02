module fifo #(parameter DATA_WIDTH = 4, parameter DEPTH = 8) (
    input                       clk,
    input                       rst,

    input                       wr,
    input                       rd, 

    input           [DATA_WIDTH-1:0]    data_in,
    output logic    [DATA_WIDTH-1:0]    data_out,

    output                      full,
    output                      empty

    
);

localparam ADDR_WIDTH = $clog2(DEPTH);

logic   [DATA_WIDTH-1:0]    mem [DEPTH-1:0];
logic   [ADDR_WIDTH-1:0]    wr_addr;
logic   [ADDR_WIDTH-1:0]    rd_addr;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        wr_addr     <= '0;
        rd_addr     <= '0;
        data_out    <= '0;
    end else begin
        if(wr & rd) begin
            mem[wr_addr]    <= data_in;
            data_out        <= mem[rd_addr];
        end else if(wr & !full) begin
            wr_addr         <= (wr_addr < DEPTH-1) ? wr_addr + 1 : '0;
            mem[wr_addr]    <= data_in;
        end else if(rd & !empty) begin
            rd_addr     <= (rd_addr < DEPTH-1) ? rd_addr + 1 : '0;
            data_out    <= mem[rd_addr];
        end
    end
end

assign  full    = ({~wr_addr[ADDR_WIDTH-1], wr_addr[ADDR_WIDTH-2:0]} == rd_addr);
assign  empty   = (wr_addr == rd_addr);

endmodule