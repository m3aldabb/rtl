module edge_detect(
    input   clk,
    input   rst,
    input   din,
    output  o_pedge_pulse
);

typedef enum {
    RST,
    S0,
    S1,
    S01,
    S10
} states_t;

states_t    state;
states_t    next_state;


always @(posedge clk or posedge rst) begin
    if(rst) begin
        state   <= RST;
    end else begin
        state   <= next_state;
    end
end

always @(*) begin
    case(state)
        RST: begin
            if(din) begin
                next_state  = S1;
            end else begin
                next_state  = S0;
            end
        end
        S0: begin
            if(din) begin
                next_state  = S01;
            end else begin
                next_state  = S0;
            end
        end
        S1: begin
            if(din) begin
                next_state  = S1;
            end else begin
                next_state  = S10;
            end
        end
        S01: begin
            if(din) begin
                next_state  = S1;
            end else begin
                next_state  = S10;
            end
        end
        S10: begin
            if(din) begin
                next_state  = S01;
            end else begin
                next_state  = S0;
            end
        end
    endcase 
end

assign o_pedge_pulse = (state == S01);
endmodule 