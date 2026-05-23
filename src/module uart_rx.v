module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,
    input  wire       rx,

    input  wire       parity_en,   // 1 = enable parity


    input  wire       parity_type, // 0 = even, 1 = odd

    output reg  [7:0] rx_data,
    output reg        rx_done,
    output reg        rx_error     // framing error OR parity error
);
    localparam IDLE   = 3'b000;
    localparam START  = 3'b001;
    localparam DATA   = 3'b010;

    localparam PARITY = 3'b011; // new state

    localparam STOP   = 3'b100;

    reg [2:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    reg       parity_calc; // running XOR of received bits


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            tick_cnt    <= 0;
            bit_cnt     <= 0;
            shift_reg   <= 0;

            parity_calc <= 0;

            rx_data     <= 0;
            rx_done     <= 0;
            rx_error    <= 0;
        end
        else begin
            rx_done  <= 0;
            rx_error <= 0;
            case (state)
                IDLE: begin
                    tick_cnt    <= 0;
                    bit_cnt     <= 0;

                    parity_calc <= 0;

                    if (rx == 0)
                        state <= START;
                end

                START: begin
                    if (tick) begin
                        if (tick_cnt == 7) begin
                            tick_cnt <= 0;
                            bit_cnt  <= 0;
                            if (rx == 0)
                                state <= DATA;
                            else
                                state <= IDLE;
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                DATA: begin
                    if (tick) begin
                        if (tick_cnt == 15) begin
                            tick_cnt    <= 0;
                            shift_reg   <= {rx, shift_reg[7:1]};

                            parity_calc <= parity_calc ^ rx; // accumulate XOR

                            if (bit_cnt == 7)

                                state <= parity_en ? PARITY : STOP;

                            else
                                bit_cnt <= bit_cnt + 1;
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end


                PARITY: begin
                    if (tick) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= STOP;
                            // even: XOR of all bits+parity_bit == 0
                            // odd:  XOR of all bits+parity_bit == 1
                            if ((parity_calc ^ rx) != parity_type)
                                rx_error <= 1; // parity error
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end


                STOP: begin
                    if (tick) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= IDLE;
                            if (rx == 1) begin
                                rx_data <= shift_reg;
                                rx_done <= 1;
                            end
                            else
                                rx_error <= 1; // framing error
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule
