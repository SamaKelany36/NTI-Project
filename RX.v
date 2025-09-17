module receiver (
    input wire Rx,
    input wire Rx_en,
    output reg ready,
    input wire ready_clr,
    input wire clk_50m,
    input wire clken,
    output reg [7:0] data
);

    initial begin
        ready = 1'b0;
        data = 8'b0;
    end

    parameter RX_STATE_START = 2'b00;
    parameter RX_STATE_DATA  = 2'b01;
    parameter RX_STATE_STOP  = 2'b10;

    reg [1:0] state = RX_STATE_START;
    reg [3:0] sample = 4'h0;
    reg [2:0] bit_pos = 3'h0;
    reg [7:0] scratch = 8'h00;

    always @(posedge clk_50m) begin
        if (ready_clr)
            ready <= 1'b0;

        if (clken && Rx_en) begin
            case (state)
                RX_STATE_START: begin
                    if (!Rx || sample != 0)
                        sample <= sample + 1;
                    if (sample == 15) begin
                        state <= RX_STATE_DATA;
                        bit_pos <= 3'h0;
                        sample <= 4'h0;
                        scratch <= 8'h00;
                    end
                end
                RX_STATE_DATA: begin
                    sample <= sample + 1;
                    if (sample == 8) begin
                        scratch[bit_pos] <= Rx;
                        bit_pos <= bit_pos + 1;
                    end
                    if (bit_pos == 3'h7 && sample == 15)
                        state <= RX_STATE_STOP;
                end
                RX_STATE_STOP: begin
                    if (sample == 15 || (sample >= 8 && !Rx)) begin
                        state <= RX_STATE_START;
                        data <= scratch;
                        ready <= 1'b1;
                        sample <= 4'h0;
                    end else
                        sample <= sample + 1;
                end
                default: state <= RX_STATE_START;
            endcase
        end
    end

endmodule
