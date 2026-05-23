`timescale 1ns / 1ps

module uart_tb;

// ─── Clock & DUT signals ───────────────────────────────────────
reg        clk, rst;
reg        tx_start;
reg  [7:0] tx_data;
reg        parity_en, parity_type, stop_bits;
wire       tx, tx_busy;
wire [7:0] rx_data;
wire       rx_done, rx_error;

// Loopback: TX → RX (normal path)
reg        rx_force;      // override rx for framing/baud inject
reg        rx_inject;     // injected bit stream
reg        use_inject;    // 1 = use injected stream, 0 = loopback
wire       rx_in = use_inject ? rx_inject : tx;

uart_top #(
    .CLK_FREQ  (50_000_000),
    .BAUD_RATE (9600)
) u_dut (
    .clk         (clk),
    .rst         (rst),
    .tx_start    (tx_start),
    .tx_data     (tx_data),
    .parity_en   (parity_en),
    .parity_type (parity_type),
    .stop_bits   (stop_bits),
    .tx          (tx),
    .tx_busy     (tx_busy),
    .rx          (rx_in),
    .rx_data     (rx_data),
    .rx_done     (rx_done),
    .rx_error    (rx_error)
);

// 50 MHz clock
initial clk = 0;
always #10 clk = ~clk;

// ─── Timing constants ─────────────────────────────────────────
localparam CLK_PERIOD  = 20;        // ns
localparam BAUD_PERIOD = 104_167;  // ns @ 9600 baud
localparam HALF_BIT   = BAUD_PERIOD / 2;

// ─── Pass/fail counters ───────────────────────────────────────
integer pass_cnt = 0;
integer fail_cnt = 0;

// ─── Task: send via DUT TX, check RX ──────────────────────────
task send_and_check;
    input [7:0]  data;
    input        p_en;
    input        p_type;
    input        s_bits;
    input [7:0]  expect_data;
    input        expect_error;
    input [63:0] test_num;
    input [63:0] timeout_cycles;
    reg          timed_out;
    integer      i;
    begin
        wait (!tx_busy);
        parity_en   = p_en;
        parity_type = p_type;
        stop_bits   = s_bits;
        tx_data     = data;
        use_inject  = 0;
        @(posedge clk);
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        // wait for rx_done or rx_error with timeout
        timed_out = 0;
        fork
            begin
                @(posedge rx_done or posedge rx_error);
            end
            begin
                repeat (timeout_cycles) @(posedge clk);
                timed_out = 1;
            end
        join_any
        disable fork;
        @(posedge clk);
        if (timed_out)
            $display("[FAIL] Test %0d | TIMEOUT", test_num);
        else if (rx_error == expect_error &&
                 (expect_error || rx_data == expect_data))
            begin $display("[PASS] Test %0d", test_num); pass_cnt = pass_cnt + 1; end
        else
            begin
                $display("[FAIL] Test %0d | data=0x%02X err=%b | expect=0x%02X err=%b",
                         test_num, rx_data, rx_error, expect_data, expect_error);
                fail_cnt = fail_cnt + 1;
            end
    end
endtask

// ─── Task: inject raw bit stream (framing/baud mismatch tests) ─
task inject_frame;
    input [7:0]  data;
    input        bad_stop;    // force stop bit = 0
    input        bad_parity;  // flip parity bit
    input        p_en;
    input        p_type;
    input [63:0] test_num;
    input        expect_error;
    reg  [7:0]   d;
    reg          par;
    integer      i;
    integer      timed_out;
    begin
        parity_en   = p_en;
        parity_type = p_type;
        use_inject  = 1;
        d = data;
        par = p_type; // odd=1, even=0 initial
        for (i = 0; i < 8; i = i+1) par = par ^ d[i];
        if (bad_parity) par = ~par;
        // start bit
        rx_inject = 0; #(BAUD_PERIOD);
        // data bits LSB first
        for (i = 0; i < 8; i = i+1) begin
            rx_inject = d[i]; #(BAUD_PERIOD);
        end
        // parity bit
        if (p_en) begin
            rx_inject = par; #(BAUD_PERIOD);
        end
        // stop bit
        rx_inject = bad_stop ? 0 : 1; #(BAUD_PERIOD);
        rx_inject = 1; // line idle
        // check result
        timed_out = 0;
        fork
            @(posedge rx_done or posedge rx_error);
            begin repeat (20000) @(posedge clk); timed_out = 1; end
        join_any
        disable fork;
        @(posedge clk);
        if (timed_out)
            $display("[FAIL] Test %0d | TIMEOUT", test_num);
        else if (rx_error == expect_error)
            begin $display("[PASS] Test %0d", test_num); pass_cnt = pass_cnt + 1; end
        else
            begin
                $display("[FAIL] Test %0d | rx_error=%b expected=%b",
                         test_num, rx_error, expect_error);
                fail_cnt = fail_cnt + 1;
            end
        use_inject = 0;
    end
endtask

// ─── Main test sequence ───────────────────────────────────────
initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    rst = 1; tx_start = 0; tx_data = 0;
    parity_en = 0; parity_type = 0; stop_bits = 0;
    use_inject = 0; rx_inject = 1;
    repeat (5) @(posedge clk);
    rst = 0;
    repeat (2) @(posedge clk);

    $display("===== GROUP 1: Basic data, no parity =====");
    // T1–T8: boundary & alternating patterns
    send_and_check(8'h00, 0,0,0, 8'h00, 0, 1,  20000);
    send_and_check(8'hFF, 0,0,0, 8'hFF, 0, 2,  20000);
    send_and_check(8'h55, 0,0,0, 8'h55, 0, 3,  20000);
    send_and_check(8'hAA, 0,0,0, 8'hAA, 0, 4,  20000);
    send_and_check(8'h01, 0,0,0, 8'h01, 0, 5,  20000);
    send_and_check(8'h80, 0,0,0, 8'h80, 0, 6,  20000);
    send_and_check(8'hA5, 0,0,0, 8'hA5, 0, 7,  20000);
    send_and_check(8'h3C, 0,0,0, 8'h3C, 0, 8,  20000);

    $display("===== GROUP 2: Even parity, 1 stop bit =====");
    // T9–T12: valid frames, even parity
    send_and_check(8'h00, 1,0,0, 8'h00, 0, 9,  20000);
    send_and_check(8'hFF, 1,0,0, 8'hFF, 0, 10, 20000);
    send_and_check(8'h55, 1,0,0, 8'h55, 0, 11, 20000);
    send_and_check(8'hAA, 1,0,0, 8'hAA, 0, 12, 20000);

    $display("===== GROUP 3: Odd parity, 1 stop bit =====");
    // T13–T16: valid frames, odd parity
    send_and_check(8'h00, 1,1,0, 8'h00, 0, 13, 20000);
    send_and_check(8'hFF, 1,1,0, 8'hFF, 0, 14, 20000);
    send_and_check(8'h55, 1,1,0, 8'h55, 0, 15, 20000);
    send_and_check(8'hAA, 1,1,0, 8'hAA, 0, 16, 20000);

    $display("===== GROUP 4: 2 stop bits =====");
    // T17–T18: 2 stop bits, no parity and with parity
    send_and_check(8'h5A, 0,0,1, 8'h5A, 0, 17, 25000);
    send_and_check(8'hB4, 1,0,1, 8'hB4, 0, 18, 25000);

    $display("===== GROUP 5: Parity error injection =====");
    // T19–T20: flip parity bit → rx_error expected
    inject_frame(8'h55, 0, 1, 1, 0, 19, 1); // even parity, bad bit
    inject_frame(8'hAA, 0, 1, 1, 1, 20, 1); // odd parity, bad bit

    $display("===== GROUP 6: Framing error injection =====");
    // T21–T22: stop bit forced low → rx_error expected
    inject_frame(8'h55, 1, 0, 0, 0, 21, 1); // bad stop, no parity
    inject_frame(8'hFF, 1, 0, 1, 0, 22, 1); // bad stop, with parity

    $display("===== GROUP 7: Baud mismatch (fast sender) =====");
    // T23–T24: inject at ~2× baud rate → RX samples wrong centers
    begin : blk_mismatch
        integer i;
        use_inject = 1;
        rx_inject  = 1;
        // send 0x55 at half the baud period (2× too fast)
        rx_inject = 0; #(BAUD_PERIOD/2);
        for (i = 0; i < 8; i = i+1) begin
            rx_inject = 8'h55 >> i; #(BAUD_PERIOD/2);
        end
        rx_inject = 1; #(BAUD_PERIOD);
        repeat (5000) @(posedge clk);
        // Mismatch test: verify rx_done did NOT fire with correct data
        if (rx_data != 8'h55 || rx_error == 1)
            begin $display("[PASS] Test 23 | baud mismatch detected"); pass_cnt = pass_cnt + 1; end
        else
            begin $display("[FAIL] Test 23 | mismatch not caught"); fail_cnt = fail_cnt + 1; end
        use_inject = 0;
    end

    // T24: normal frame after mismatch → recovery check
    inject_frame(8'hA5, 0, 0, 0, 0, 24, 0);

    $display("===== GROUP 8: Back-to-back frames =====");
    // T25: two frames sent immediately one after another
    begin : blk_b2b
        reg first_ok, second_ok;
        first_ok  = 0;
        second_ok = 0;
        wait (!tx_busy);
        parity_en = 0; stop_bits = 0;
        tx_data = 8'hDE; tx_start = 1; @(posedge clk); tx_start = 0;
        wait (!tx_busy);
        tx_data = 8'hAD; tx_start = 1; @(posedge clk); tx_start = 0;
        @(posedge rx_done); if (rx_data == 8'hDE) first_ok  = 1;
        @(posedge rx_done); if (rx_data == 8'hAD) second_ok = 1;
        if (first_ok && second_ok)
            begin $display("[PASS] Test 25 | back-to-back OK"); pass_cnt = pass_cnt + 1; end
        else
            begin $display("[FAIL] Test 25 | back-to-back FAIL"); fail_cnt = fail_cnt + 1; end
    end

    repeat (20) @(posedge clk);
    $display("===== DONE | PASS=%0d  FAIL=%0d =====", pass_cnt, fail_cnt);
    $finish;
end

endmodule
