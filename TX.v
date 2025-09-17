module TX (
    input  clk,
    input  rst,
    input  [7:0] data_in,
    input  tx_en,
    output done,
    output busy,
    output reg tx
);

    parameter COUNT_CYCLES = 100_000_000 / 9600;

    localparam IDLE     = 3'd0;
    localparam START    = 3'd1;
    localparam DATA     = 3'd2;
    localparam STOP     = 3'd3;
    localparam CLEAN_UP = 3'd4;

    reg [2:0]  CS = 0;
    reg [15:0] r_Clock_Count = 0;
    reg [2:0]  r_Bit_Index = 0;
    reg [7:0]  r_Tx_Data = 0;
    reg        r_Tx_Done = 0;
    reg        r_Tx_busy = 0;

    always @(posedge clk) begin
        if (rst) begin
            CS <= IDLE;
            r_Clock_Count <= 0;
            r_Bit_Index <= 0;
            r_Tx_Data <= 0;
            r_Tx_Done <= 0;
            r_Tx_busy <= 0;
            tx <= 1'b1;
        end else begin
            case (CS)
                IDLE: begin
                    tx <= 1'b1;
                    r_Clock_Count <= 0;
                    r_Bit_Index <= 0;
                    r_Tx_Done <= 0;
                    if (tx_en) begin
                        r_Tx_busy <= 1'b1;
                        r_Tx_Data <= data_in;
                        CS <= START;
                    end else begin
                        CS <= IDLE;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= START;
                    end else begin
                        r_Clock_Count <= 0;
                        CS <= DATA;
                    end
                end
                DATA: begin
                    tx <= r_Tx_Data[r_Bit_Index];
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= DATA;
                    end else begin
                        r_Clock_Count <= 0;
                        if (r_Bit_Index < 7) begin
                            r_Bit_Index <= r_Bit_Index + 1;
                            CS <= DATA;
                        end else begin
                            r_Bit_Index <= 0;
                            CS <= STOP;
                        end
                    end
                end
                STOP: begin
                    tx <= 1'b1;
                    r_Tx_Done <= 1'b1;
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= STOP;
                    end else begin
                        r_Tx_busy <= 1'b0;
                        r_Clock_Count <= 0;
                        CS <= CLEAN_UP;
                    end
                end
                CLEAN_UP: begin
                    CS <= IDLE;
                    r_Tx_Done <= 0;
                    r_Tx_busy <= 0;
                end
            endcase
        end
    end

    assign busy = r_Tx_busy;
    assign done = r_Tx_Done;

endmodule
