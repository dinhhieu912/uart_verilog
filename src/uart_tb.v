`timescale 1ns / 1ps

module uart_tb;

    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    wire       rx_error;

    wire rx = tx;

    uart_top u_uart (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx),
        .tx_busy  (tx_busy),
        .rx       (rx),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .rx_error (rx_error)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        rst      = 1;
        tx_start = 0;
        tx_data  = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        // ── Test 1: 0x55 ──────────────────────────────────────
        tx_data  = 8'h55;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        @(posedge rx_done);
        @(posedge clk);
        if (rx_data == 8'h55 && rx_error == 0)
            $display("[PASS] Test 1 | 0x55 OK");
        else
            $display("[FAIL] Test 1 | Expected 0x55, Got 0x%02X", rx_data);

        // ── Test 2: 0xAA ──────────────────────────────────────
        wait (!tx_busy);
        tx_data  = 8'hAA;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        @(posedge rx_done);
        @(posedge clk);
        if (rx_data == 8'hAA && rx_error == 0)
            $display("[PASS] Test 2 | 0xAA OK");
        else
            $display("[FAIL] Test 2 | Expected 0xAA, Got 0x%02X", rx_data);

        // ── Test 3: 0xFF ──────────────────────────────────────
        wait (!tx_busy);
        tx_data  = 8'hFF;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        @(posedge rx_done);
        @(posedge clk);
        if (rx_data == 8'hFF && rx_error == 0)
            $display("[PASS] Test 3 | 0xFF OK");
        else
            $display("[FAIL] Test 3 | Expected 0xFF, Got 0x%02X", rx_data);

        repeat (10) @(posedge clk);
        $display("===== DONE =====");
        $finish;
    end

endmodule