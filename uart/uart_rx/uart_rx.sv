// NCLKS_PER_BIT = (Fclk)/(BR)
// Example: 25 MHz Clock, 115200 baud UART
// NCLKS_PER_BIT = (25000000)/(115200) = 217
module uart_rx #(parameter NCLKS_PER_BIT = 217) (
    input clk, 
    input rst,

    // Ouput AXI-Stream Interface
    output [7:0] axis_out_tdata,
    output       axis_out_tvalid,

    // Input UART Interface
    input      rx_data
);

typedef enum logic[2:0] {
    IDLE,
    START,
    DATA,
    STOP, 
    DONE
} states_t;


// Signals and Registers
states_t        state, next_state;

logic           r_axis_out_tvalid, next_axis_out_tvalid;

logic   [7:0]   byte_mem, next_byte_mem;  
logic   [2:0]   byte_idx, next_byte_idx;

logic   [$clog2(NCLKS_PER_BIT)-1:0] clk_count, next_clk_count;


// Output Assignments
assign axis_out_tvalid  = r_axis_out_tvalid;
assign axis_out_tdata   = (r_axis_out_tvalid) ? byte_mem : 'X;


// Sequential Logic
always @(posedge clk) begin
    if(rst) begin
        state               <= IDLE;
        byte_mem            <= '0;
        byte_idx            <= '0;
        clk_count           <= '0;
        r_axis_out_tvalid   <= 1'b0;
    end else begin
        state               <= next_state;
        byte_mem            <= next_byte_mem;
        byte_idx            <= next_byte_idx;
        clk_count           <= next_clk_count;
        r_axis_out_tvalid   <= next_axis_out_tvalid;
    end
end
// Combinational Logic
always @(*) begin
    next_state               = state;
    next_byte_mem            = byte_mem;
    next_byte_idx            = byte_idx;
    next_clk_count           = clk_count;
    next_axis_out_tvalid     = r_axis_out_tvalid;
    case(state)
        IDLE: begin
            if(~rx_data) begin // Start bit
                next_state  = START;
            end else begin
                next_state  = IDLE;
            end
        end

        START: begin
            if(clk_count == NCLKS_PER_BIT/2 - 1) begin // Found the halfway point
                next_clk_count = '0;
                if(~rx_data) begin
                    // Start bit accepted, ready to move on to data bits.
                    next_state  = DATA;
                end else begin
                    next_state  = IDLE;
                end
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = START;
            end
        end

        DATA: begin
            if(clk_count == NCLKS_PER_BIT - 1) begin
                next_clk_count          = '0;
                next_byte_mem[byte_idx] = rx_data;

                if(byte_idx < 7) begin
                    next_byte_idx   = byte_idx + 1;
                    next_state      = DATA;
                end else begin
                    next_byte_idx   = '0;
                    next_state      = STOP;
                end
            end else begin
                next_clk_count      = clk_count + 1;
                next_state          = DATA;
            end
            
        end

        STOP: begin
            if (clk_count == NCLKS_PER_BIT-1) begin
                clk_count               = '0;
                next_state              = DONE;
                next_axis_out_tvalid    = 1'b1; 
            end else begin
                next_clk_count          = clk_count + 1;
                next_state              = STOP;
            end
        end

        DONE: begin
            next_axis_out_tvalid        = 1'b0;
            next_state                  = IDLE;
        end
    endcase
end

endmodule