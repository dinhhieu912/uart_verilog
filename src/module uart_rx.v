module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,       // xung x16 từ baud_gen (oversampling)
    input  wire       rx,         // đường nhận nối tiếp
    output reg  [7:0] rx_data,    // dữ liệu nhận được
    output reg        rx_done,    // pulse: nhận xong 1 byte
    output reg        rx_error    // stop bit sai → frame error
);

    // Định nghĩa trạng thái FSM
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] tick_cnt;   // đếm tick trong 1 bit (0→15)
    reg [2:0] bit_cnt;    // đếm số bit đã nhận (0→7)
    reg [7:0] shift_reg;  // thanh ghi dịch chứa data

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
            rx_done  <= 0; // mặc định = 0, chỉ lên 1 đúng 1 chu kỳ
            rx_error <= 0;

            case (state)

                IDLE: begin
                    tick_cnt <= 0;
                    bit_cnt  <= 0;
                    if (rx == 0)        // phát hiện cạnh xuống = start bit
                        state <= START;
                end

                START: begin
                    if (tick) begin
                        if (tick_cnt == 7) begin
                            // giữa start bit → xác nhận rx vẫn = 0
                            tick_cnt <= 0;
                            if (rx == 0)
                                state <= DATA;
                            else
                                state <= IDLE; // nhiễu, bỏ qua
                        end
                        else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                DATA: begin
                    if (tick) begin
                        if (tick_cnt == 15) begin
                            // giữa bit data → lấy mẫu
                            tick_cnt  <= 0;
                            shift_reg <= {rx, shift_reg[7:1]}; // MSB vào trái, dịch phải
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
                            if (rx == 1) begin
                                rx_data <= shift_reg; // lưu dữ liệu
                                rx_done <= 1;         // báo nhận xong
                            end
                            else begin
                                rx_error <= 1;        // stop bit sai
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