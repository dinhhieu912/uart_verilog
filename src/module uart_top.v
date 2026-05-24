module uart_top (
    input  wire       clk,        // clock hệ thống 50MHz
    input  wire       rst,        // reset tích cực mức cao
    // TX interface
    input  wire       tx_start,   // pulse: bắt đầu gửi
    input  wire [7:0] tx_data,    // dữ liệu cần gửi
    output wire       tx,         // đường truyền nối tiếp ra ngoài
    output wire       tx_busy,    // đang bận
    // RX interface
    input  wire       rx,         // đường nhận nối tiếp từ ngoài
    output wire [7:0] rx_data,    // dữ liệu nhận được
    output wire       rx_done,    // pulse: nhận xong 1 byte
    output wire       rx_error    // frame error
);

    // Internal signals
    wire tick_tx;  // baud tick cho TX  (x1  = 9600 baud)
    wire tick_rx;  // baud tick cho RX  (x16 = 153600 tick/s)

    // ── Baud generator cho TX (9600 baud) ──────────────────────
    baud_gen #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (9600)
    ) u_baud_tx (
        .clk  (clk),
        .rst  (rst),
        .tick (tick_tx)
    );

    // ── Baud generator cho RX (9600 x 16 = 153600) ─────────────
    baud_gen #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (9600 * 16)
    ) u_baud_rx (
        .clk  (clk),
        .rst  (rst),
        .tick (tick_rx)
    );

    // ── UART Transmitter ────────────────────────────────────────
    uart_tx u_tx (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick_tx),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    // ── UART Receiver ───────────────────────────────────────────
    uart_rx u_rx (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick_rx),
        .rx       (rx),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .rx_error (rx_error)
    );

endmodule
