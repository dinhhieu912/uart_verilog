module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,       // xung x16 từ baud_gen (oversampling)
    input  wire       rx,         // đường nhận nối tiếp
    output reg  [7:0] rx_data,    // dữ liệu nhận được
    output reg        rx_done,    // pulse: nhận xong 1 byte
    output reg        rx_error    // stop bit sai → frame error
);
    // ── FIX 1: Input synchronizer (2 FF) chống metastability ────
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
            rx_done  <= 0;
            rx_error <= 0;
            case (state)
                IDLE: begin
                    tick_cnt <= 0;
                    bit_cnt  <= 0;
                    // ── FIX 2: dùng rx_sync2 thay cho rx ────────
                    if (rx_sync2 == 0)
                        state <= START;
                end
                START: begin
                    if (tick) begin
                        if (tick_cnt == 7) begin
                            tick_cnt <= 0;
                            if (rx_sync2 == 0)
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
                            tick_cnt <= 0;
                            // ── FIX 3: dịch trái, LSB vào bit0 ──
                            // UART gửi LSB trước → bit đầu nhận
                            // phải nằm ở bit[0], bit sau ở bit[1]...
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
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= IDLE;
                            if (rx_sync2 == 1) begin
                                rx_data <= shift_reg;
                                rx_done <= 1;
                            end
                            else begin
                                rx_error <= 1;
                            end
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule
