module alarm_system(
    input   clk,
    input   rst,
    input   [3:0]   din,
    output  [2:0]   status,
    output  [3:0]   chars
);


// Constants and Parameters
localparam STATUS_INIT      = 3'b101;
localparam STATUS_LOCKED    = 3'b011;
localparam STATUS_ALARM     = 3'b001;
localparam STATUS_UNLOCKED  = 3'b010;
localparam STATUS_WAITING   = 3'b100;
 
typedef enum logic[$clog2(4)-1:0] {
    INIT,
    LOCKED,
    UNLOCKED,
    ALARM
} states_t;


// Registers
states_t            state;
logic               error;
logic       [2:0]   count;
logic       [3:0]   mem [0:3];
logic       [2:0]   status_r;


// Logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        count       <= '0;
        error       <= 1'b0;
        status_r    <= STATUS_INIT;
        state       <= INIT;
    end else begin
        case(state)
            INIT: begin
                if(count < 4) begin
                    if(din) begin
                        // If any of the buttons are pressed, updated the stored password.
                        mem[count]  <= din;
                        count       <= count + 1;
                    end
                    status_r    <= STATUS_INIT;
                    state       <= INIT;
                end else begin
                    // 4-character password has been chosen, now proceed to the LOCKED state.
                    count       <= '0;
                    status_r    <= STATUS_LOCKED;
                    state       <= LOCKED;
                end
            end

            LOCKED: begin
                if(count < 4) begin
                    if(din) begin
                        // If any of the buttons are pressed, check to see if we recieve expected character.
                        if(din != mem[count]) begin
                            // If input does not match as expected, flag an error
                            error   <= 1'b1;
                        end
                        count       <= count + 1;
                    end
                    status_r    <= STATUS_LOCKED;
                    state       <= LOCKED;
                end else begin
                    // 4-character password has been inputted. If correct move to UNLOCKED state, otherwise go to ALARM state.
                    if(error) begin
                        status_r    <= STATUS_ALARM;
                        state       <= ALARM;
                    end else begin
                        status_r    <= STATUS_UNLOCKED;
                        state       <= UNLOCKED;
                    end
                    count   <= '0;
                    error   <= 1'b0;
                end
            end

            ALARM: begin
                if(count < 4) begin
                    if(din) begin
                        // If any of the buttons are pressed, check to see if we recieve expected character.
                        if(din != mem[count]) begin
                            // If input does not match as expected, flag an error
                            error   <= 1'b1;
                        end
                        count       <= count + 1;
                    end
                    status_r    <= STATUS_ALARM;
                    state       <= ALARM;
                end else begin
                    // 4-character password has been inputted. If correct move to UNLOCKED state, otherwise go to ALARM state.
                    if(error) begin
                        status_r    <= STATUS_ALARM;
                        state       <= ALARM;
                    end else begin
                        status_r    <= STATUS_UNLOCKED;
                        state       <= UNLOCKED;
                    end
                    count   <= '0;
                    error   <= 1'b0;
                end
            end

            UNLOCKED: begin
                if(din) begin
                    // To relock the system, input any character.
                    count       <= '0;
                    error       <= 1'b0;
                    status_r    <= STATUS_LOCKED;
                    state       <= LOCKED;
                end else begin
                    status_r    <= STATUS_UNLOCKED;
                    state       <= UNLOCKED;
                end
            end
        endcase
    end
end

// Output assignments
assign status       = status_r;
assign chars[3]     = (count > 0) || (state == UNLOCKED);
assign chars[2]     = (count > 1) || (state == UNLOCKED);
assign chars[1]     = (count > 2) || (state == UNLOCKED);
assign chars[0]     = (count > 3) || (state == UNLOCKED);

endmodule