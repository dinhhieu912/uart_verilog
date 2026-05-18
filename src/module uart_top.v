module uart_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx,
    output wire       tx_busy,
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_done,
    output wire       rx_error
);

    wire tick_tx;
    wire tick_rx;

    baud_gen #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (500_000)       // ← tăng từ 9600 lên 500_000
    ) u_baud_tx (
        .clk  (clk),
        .rst  (rst),
        .tick (tick_tx)
    );

    baud_gen #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (500_000 * 16)  // ← tăng từ 9600*16 lên 500_000*16
    ) u_baud_rx (
        .clk  (clk),
        .rst  (rst),
        .tick (tick_rx)
    );

    uart_tx u_tx (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick_tx),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

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