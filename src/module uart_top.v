module uart_top #(

    parameter CLK_FREQ  = 50_000_000,  // system clock Hz


    parameter BAUD_RATE = 9600          // 9600–115200

) (
    input  wire       clk,
    input  wire       rst,
    // TX
    input  wire       tx_start,
    input  wire [7:0] tx_data,

    input  wire       parity_en,    // 1 = enable parity


    input  wire       parity_type,  // 0 = even, 1 = odd


    input  wire       stop_bits,    // 0 = 1 stop bit, 1 = 2 stop bits

    output wire       tx,
    output wire       tx_busy,
    // RX
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_done,
    output wire       rx_error
);
    // Single baud_gen ticking at 16 × BAUD_RATE
    // TX uses every 16th tick; RX uses every tick for oversampling

    wire tick;


    baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)   // baud_gen already divides by 16 internally
    ) u_baud (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );


    uart_tx #(

        .OVERSAMPLE (16)  // TX skips 15 ticks, fires on 16th

    ) u_tx (
        .clk         (clk),
        .rst         (rst),
        .tick        (tick),
        .tx_start    (tx_start),
        .tx_data     (tx_data),

        .parity_en   (parity_en),


        .parity_type (parity_type),


        .stop_bits   (stop_bits),

        .tx          (tx),
        .tx_busy     (tx_busy)
    );

    uart_rx u_rx (
        .clk         (clk),
        .rst         (rst),
        .tick        (tick),
        .rx          (rx),

        .parity_en   (parity_en),


        .parity_type (parity_type),

        .rx_data     (rx_data),
        .rx_done     (rx_done),
        .rx_error    (rx_error)
    );

endmodule
