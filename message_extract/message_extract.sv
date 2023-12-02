module msg_extract #(
    parameter   TDATA_WIDTH = 64,
    parameter   TID_WIDTH   = 64,
    parameter   TDEST_WIDTH = 64,
    parameter   TUSER_WIDTH = 64
) (
    input logic  clk,
    input logic  sreset,
    
    // axis_in (Slave)
    input logic                         axis_in_tvalid,
    output logic                        axis_in_tready,
    input logic  [TDATA_WIDTH-1:0]      axis_in_tdata,
    input logic  [TDATA_WIDTH/8-1:0]    axis_in_tstrb,
    input logic  [TDATA_WIDTH/8-1:0]    axis_in_tkeep,
    input logic                         axis_in_tlast,
    input logic  [TID_WIDTH-1:0]        axis_in_tid,
    input logic  [TDEST_WIDTH-1:0]      axis_in_tdest,
    input logic  [TUSER_WIDTH-1:0]      axis_in_tuser,

    // axis_out (Master)
    output                              axis_out_tvalid,
    input logic                         axis_out_tready,
    output logic   [TDATA_WIDTH-1:0]    axis_out_tdata,
    output logic   [TDATA_WIDTH/8-1:0]  axis_out_tstrb,
    output logic   [TDATA_WIDTH/8-1:0]  axis_out_tkeep,
    output logic                        axis_out_tlast,
    output logic   [TID_WIDTH-1:0]      axis_out_tid,
    output logic   [TDEST_WIDTH-1:0]    axis_out_tdest,
    output logic   [TUSER_WIDTH-1:0]    axis_out_tuser
);

// Parameters and Constants
localparam  BYTELEN             = 8;    // in bits
localparam  MIN_MSGLEN          = 8;    // in bytes
localparam  MAX_MSGLEN          = 32;   // in bytes
localparam  MAX_PACKETLEN       = 1500; // in bytes

localparam  TDATA_BYTE_WIDTH    = TDATA_WIDTH/BYTELEN;

typedef enum logic[$clog2(3)-1:0] {
    WR_IDLE,
    WR_EXTRACT,
    WR_DONE
} wr_states_t;

typedef enum logic [$clog2(3)-1:0]{
    RD_IDLE,
    RD_SEND,
    RD_DONE
} rd_states_t;

// Signal and Registers

wr_states_t     wr_state;
rd_states_t     rd_state;

// FIFO Memory
logic   [BYTELEN-1:0]               mem [0:MAX_PACKETLEN-1];
logic   [$clog2(MAX_PACKETLEN)-1:0] wr_addr;
logic   [$clog2(MAX_PACKETLEN)-1:0] rd_addr;


logic   [2*BYTELEN-1:0]     msg_count;          // Holds number of messages remaining to send in current packet.
logic   [2*BYTELEN-1:0]     remaining_bytes;    // Holds number of bytes remaining to send in current message.

logic   [TDATA_WIDTH-1:0]   out_tdata;
logic   [TDATA_WIDTH/8-1:0] out_tkeep;
logic                       out_tvalid;


// FIRST FSM - Handles writing to the FIFO.
always_ff @(posedge clk) begin
    if(sreset) begin
        wr_state    <= WR_IDLE;
        wr_addr     <= '0;
    end else begin
        case(wr_state)
            WR_IDLE: begin
                if(axis_in_tvalid & axis_in_tready) begin
                    {   mem[wr_addr], 
                        mem[wr_addr+1], 
                        mem[wr_addr+2],
                        mem[wr_addr+3],
                        mem[wr_addr+4],
                        mem[wr_addr+5],
                        mem[wr_addr+6],
                        mem[wr_addr+7] } <= axis_in_tdata;
                    
                    wr_addr     <= wr_addr + TDATA_BYTE_WIDTH; 
                    wr_state    <= WR_EXTRACT;
                end else begin
                    wr_state    <= WR_IDLE;
                end
            end

            WR_EXTRACT: begin
                if(axis_in_tvalid & axis_in_tready) begin
                    {   mem[wr_addr], 
                        mem[wr_addr+1], 
                        mem[wr_addr+2],
                        mem[wr_addr+3],
                        mem[wr_addr+4],
                        mem[wr_addr+5],
                        mem[wr_addr+6],
                        mem[wr_addr+7] } <= axis_in_tdata;
                    wr_addr              <= wr_addr + TDATA_BYTE_WIDTH;

                    wr_state    <= (axis_in_tlast) ? WR_DONE : WR_EXTRACT;
                end else begin
                    wr_state    <= WR_EXTRACT;
                end
            end

            WR_DONE: begin
                if(msg_count > 0) begin
                    wr_state    <= WR_DONE;
                end else begin
                    wr_addr     <= '0;
                    wr_state    <= WR_IDLE;
                end
            end
        endcase
    end
end

// SECOND FSM - Handles reading the FIFO (Transmitting messages to AXIS_OUT)
always_ff @(posedge clk) begin
    if(sreset) begin
        rd_state        <= RD_IDLE;
        rd_addr         <= '0;
        out_tdata       <= '0;
        out_tkeep       <= '0;
        out_tvalid      <= 1'b0;
        msg_count       <= '0;
        remaining_bytes <= '0;
    end else begin
        out_tvalid      <= 1'b0;
        out_tkeep       <= '0;
        case(rd_state)
            RD_IDLE: begin
                // Start of packet, don't come back here till packet is done!
                if(wr_addr > rd_addr) begin
                    msg_count       <= {mem[0], mem[1]};   
                    remaining_bytes <= {mem[2], mem[3]};
                    rd_addr         <= rd_addr + 4;     // Since msg_count, msg_len are 4 bytes each.

                    rd_state        <= RD_SEND;
                end else begin
                    rd_state        <= RD_IDLE;
                end
            end

            RD_SEND: begin
                // If FIFO has data in it, keep buffering data to axis_out_tdata.
                if(wr_addr > rd_addr) begin
                    if(remaining_bytes > TDATA_BYTE_WIDTH) begin
                        out_tdata       <= {    mem[rd_addr], 
                                                mem[rd_addr+1], 
                                                mem[rd_addr+2],
                                                mem[rd_addr+3],
                                                mem[rd_addr+4],
                                                mem[rd_addr+5],
                                                mem[rd_addr+6],
                                                mem[rd_addr+7] };
                        out_tvalid      <= 1'b1;
                        rd_addr         <= rd_addr + TDATA_BYTE_WIDTH;
                        remaining_bytes <= remaining_bytes - TDATA_BYTE_WIDTH;
                        
                        rd_state        <= RD_SEND;
                    end else begin
                        // If we have less than TDATA_BYTE_WIDTH bytes remaining to send, that means after the next transfer we have transferred the entire message.
                        msg_count       <= msg_count - 1;

                        case(remaining_bytes)
                            // Have to add padding if we dont fill an entire line.
                            // Could have done this in a nicer way but iVerilog doesn't have good support to deal with unpacked arrays.
                            1: out_tdata <= {mem[rd_addr], 56'b0};
                            2: out_tdata <= {mem[rd_addr], mem[rd_addr+1], 48'b0};
                            3: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], 40'b0};
                            4: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], mem[rd_addr+3], 32'b0};
                            5: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], mem[rd_addr+3], mem[rd_addr+4], 24'b0};
                            6: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], mem[rd_addr+3], mem[rd_addr+4], mem[rd_addr+5], 16'b0};
                            7: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], mem[rd_addr+3], mem[rd_addr+4], mem[rd_addr+5], mem[rd_addr+6], 8'b0};
                            8: out_tdata <= {mem[rd_addr], mem[rd_addr+1], mem[rd_addr+2], mem[rd_addr+3], mem[rd_addr+4], mem[rd_addr+5], mem[rd_addr+6], mem[rd_addr+7]};
                        endcase

                        out_tvalid      <= 1'b1;
                        rd_addr         <= rd_addr + remaining_bytes;
                        remaining_bytes <= 0;

                        // In this design, tkeep tells us the AMOUNT of bytes that are valid on the last transfer.
                        // If tkeep is 0, that means all bytes are valid (following design challenge proposal)
                        out_tkeep       <= remaining_bytes % 8;

                        rd_state        <= RD_DONE;
                    end
                end else begin
                    rd_state    <= RD_SEND; // Wait for FIFO to fill up to send more data.
                end
            end

            RD_DONE: begin
                // More messages to read from the fifo
                if(msg_count > 0) begin
                    if(wr_addr > rd_addr) begin
                        remaining_bytes <= {mem[rd_addr], mem[rd_addr+1]};
                        rd_addr         <= rd_addr + 2; // Reading 2 bytes.
                        rd_state        <= RD_SEND;
                    end else begin
                        rd_state        <= RD_DONE;
                    end
                end else begin
                    // Done packet
                    rd_state        <= RD_IDLE;
                    
                    // Reset rd_addr to prepare FIFO for new packet.
                    // Clear all other registers used to prepare for new packet.
                    msg_count       <= '0;
                    remaining_bytes <= '0;
                    rd_addr         <= '0;
                end
                out_tvalid          <= 1'b0;
            end
        endcase
    end
end

assign  axis_in_tready  = (wr_state != WR_DONE);    

assign  axis_out_tvalid = out_tvalid;
assign  axis_out_tdata  = (axis_out_tready & axis_out_tvalid) ? out_tdata : 'X;
assign  axis_out_tlast  = (rd_state == RD_DONE);
assign  axis_out_tid    = '0; // Unused
assign  axis_out_tdest  = '0; // Unused
assign  axis_out_tuser  = '0; // Unused
assign  axis_out_tstrb  = '0; // Unused
assign  axis_out_tkeep  = (axis_out_tvalid) ? out_tkeep : 'X; // Value of tkeep only matters on tlast. If not tlast, we know all bytes are valid.

endmodule