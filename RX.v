module rx (
    input  clk,
    input  rst,
    input  rx_en,
    input  rx,
    output [7:0] rx_data,
    output rx_done,
    output rx_busy
);

    parameter COUNT_CYCLES = 100_000_000 / 9600;
    parameter HALF_CYCLES  = COUNT_CYCLES / 2;

    localparam IDLE     = 3'd0;
    localparam START    = 3'd1;
    localparam DATA     = 3'd2;
    localparam STOP     = 3'd3;
    localparam CLEAN_UP = 3'd4;

    reg [2:0]  CS = 0;
    reg [15:0] r_Clock_Count = 0;
    reg [2:0]  r_Bit_Index = 0;
    reg [7:0]  r_Rx_Data_Byte = 0;
    reg        r_Rx_Done = 0;
    reg        r_Rx_Busy = 0;
    reg        r_Rx_Data_R;
    reg        r_Rx_Data;

    always @(posedge clk) begin
        if (rst) begin
            r_Rx_Data_R <= 1'b1;
            r_Rx_Data   <= 1'b1;
        end else begin
            r_Rx_Data_R <= rx;
            r_Rx_Data   <= r_Rx_Data_R;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            CS <= IDLE;
            r_Clock_Count <= 0;
            r_Bit_Index <= 0;
            r_Rx_Data_Byte <= 0;
            r_Rx_Done <= 0;
            r_Rx_Busy <= 0;
        end else begin
            case (CS)
                IDLE: begin
                    r_Clock_Count <= 0;
                    r_Bit_Index <= 0;
                    r_Rx_Busy <= 1'b0;
                    r_Rx_Done <= 0;
                    if (r_Rx_Data == 1'b0 && rx_en == 1'b1) begin
                        r_Rx_Busy <= 1'b1;
                        CS <= START;
                    end
                end
                START: begin
                    if (r_Clock_Count < HALF_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= START;
                    end else begin
                        r_Clock_Count <= 0;
                        if (r_Rx_Data == 1'b0) begin
                            CS <= DATA;
                        end else begin
                            CS <= IDLE;
                            r_Rx_Busy <= 1'b0;
                        end
                    end
                end
                DATA: begin
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                    end else begin
                        r_Clock_Count <= 0;
                        r_Rx_Data_Byte[r_Bit_Index] <= r_Rx_Data;
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
                    r_Rx_Done <= 1'b1;
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= STOP;
                    end else begin
                        r_Clock_Count <= 0;
                        CS <= CLEAN_UP;
                    end
                end
                CLEAN_UP: begin
                    r_Rx_Done <= 1'b1;
                    if (r_Clock_Count < COUNT_CYCLES - 1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        CS <= CLEAN_UP;
                    end else begin
                        r_Clock_Count <= 0;
                        r_Rx_Busy <= 1'b0;
                        r_Rx_Done <= 1'b0;
                        CS <= IDLE;
                    end
                end
                default: begin
                    CS <= IDLE;
                end
            endcase
        end
    end

    assign rx_data = r_Rx_Data_Byte;
    assign rx_done = r_Rx_Done;
    assign rx_busy = r_Rx_Busy;

endmodule
