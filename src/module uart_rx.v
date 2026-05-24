module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,       // xung x16 từ baud_gen (oversampling)
    input  wire       rx,         // đường nhận nối tiếp
    output reg  [7:0] rx_data,    // dữ liệu nhận được
    output reg        rx_done,    // pulse: nhận xong 1 byte
    output reg        rx_error    // stop bit sai → frame error
);
    // ── Input synchronizer (2 FF) chống metastability ────────────
    reg rx_sync1, rx_sync2;
    always @(posedge clk or posedge rst) begin
        if (rst) {rx_sync2, rx_sync1} <= 2'b11; // idle line = 1
        else     {rx_sync2, rx_sync1} <= {rx_sync1, rx};
    end

    // Định nghĩa trạng thái FSM
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tick_cnt  <= 0;
            bit_cnt   <= 0;
            shift_reg <= 0;
            rx_data   <= 0;
            rx_done   <= 0;
            rx_error  <= 0;
        end
        else begin
            // rx_done và rx_error chỉ cao 1 chu kỳ
            rx_done  <= 0;
            rx_error <= 0;

            case (state)
                IDLE: begin
                    tick_cnt <= 0;
                    bit_cnt  <= 0;
                    // FIX: Gate entry to START on tick boundary để tick_cnt
                    // bắt đầu đếm đồng bộ với x16 tick, tránh lệch pha
                    // sampling. Không dùng tick ở đây sẽ gây offset tối đa
                    // ±1 tick (~1/16 bit period) — chấp nhận được nhưng
                    // gating giúp chính xác hơn.
                    if (rx_sync2 == 0 && tick)
                        state <= START;
                end

                START: begin
                    if (tick) begin
                        // Đợi 8 tick = giữa start bit
                        if (tick_cnt == 7) begin
                            tick_cnt <= 0;
                            // Xác nhận vẫn là start bit (low)
                            if (rx_sync2 == 0)
                                state <= DATA;
                            else
                                state <= IDLE; // noise, quay về IDLE
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                DATA: begin
                    if (tick) begin
                        // Đợi 16 tick = giữa mỗi data bit
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            // LSB vào trước: dịch phải, bit mới vào MSB
                            shift_reg <= {rx_sync2, shift_reg[7:1]};
                            if (bit_cnt == 7)
                                state <= STOP;
                            else
                                bit_cnt <= bit_cnt + 1;
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                STOP: begin
                    if (tick) begin
                        // Đợi 16 tick = giữa stop bit
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= IDLE;
                            if (rx_sync2 == 1) begin
                                rx_data <= shift_reg;
                                rx_done <= 1;
                            end
                            else begin
                                rx_error <= 1; // stop bit không phải 1 → frame error
                            end
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
