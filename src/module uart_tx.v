module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,       // xung từ baud_gen
    input  wire       tx_start,   // pulse: bắt đầu gửi
    input  wire [7:0] tx_data,    // dữ liệu cần gửi
    output reg        tx,         // đường truyền nối tiếp
    output reg        tx_busy     // đang bận, không nhận lệnh mới
);

    // Định nghĩa trạng thái FSM
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [7:0] shift_reg;  // thanh ghi dịch chứa data
    reg [2:0] bit_cnt;    // đếm số bit đã gửi (0→7)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1;   // IDLE line = 1
            tx_busy   <= 0;
            shift_reg <= 0;
            bit_cnt   <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    tx      <= 1;
                    tx_busy <= 0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1;
                        state     <= START;
                    end
                end

                START: begin
                    if (tick) begin
                        tx      <= 0; // start bit
                        bit_cnt <= 0;
                        state   <= DATA;
                    end
                end

                DATA: begin
                    if (tick) begin
                        tx        <= shift_reg[0]; // gửi LSB trước
                        shift_reg <= shift_reg >> 1;
                        if (bit_cnt == 7)
                            state <= STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                end

                STOP: begin
                    if (tick) begin
                        tx    <= 1; // stop bit
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
