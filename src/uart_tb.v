`timescale 1ns / 1ps

module uart_tb;

    // ── Tín hiệu ────────────────────────────────────────────────
    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    wire       rx_error;

    // Loopback: nối tx → rx
    wire rx = tx;

    // ── Khởi tạo DUT ────────────────────────────────────────────
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

    // ── Clock 50MHz → chu kỳ 20ns ────────────────────────────────
    initial clk = 0;
    always #10 clk = ~clk;

    // ── Task gửi 1 byte ──────────────────────────────────────────
    task send_byte;
        input [7:0] data;
        begin
            // Chờ nếu đang bận
            wait (!tx_busy);
            @(posedge clk);

            // Phát lệnh gửi
            tx_data  = data;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;

            // Chờ nhận xong
            wait (rx_done);
            @(posedge clk);

            // Kiểm tra dữ liệu
            if (rx_data == data)
                $display("[PASS] Sent: 0x%02X | Received: 0x%02X", data, rx_data);
            else
                $display("[FAIL] Sent: 0x%02X | Received: 0x%02X", data, rx_data);
        end
    endtask

    // ── Kịch bản test ────────────────────────────────────────────
    initial begin
        // Khởi tạo
        rst      = 1;
        tx_start = 0;
        tx_data  = 0;

        // Reset 5 chu kỳ
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        $display("===== BẮT ĐẦU TEST UART =====");

        // Test 1: gửi 0x55 (0101_0101)
        $display("-- Test 1: 0x55 --");
        send_byte(8'h55);

        // Test 2: gửi 0xAA (1010_1010)
        $display("-- Test 2: 0xAA --");
        send_byte(8'hAA);

        // Test 3: gửi nhiều byte liên tiếp
        $display("-- Test 3: gửi 0x00 → 0x04 --");
        send_byte(8'h00);
        send_byte(8'h01);
        send_byte(8'h02);
        send_byte(8'h03);
        send_byte(8'h04);

        $display("===== KẾT THÚC TEST =====");

        // Chờ thêm rồi kết thúc
        repeat (100) @(posedge clk);
        $finish;
    end

    // ── Dump waveform để xem trong ModelSim ─────────────────────
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

    // ── Monitor tự động in khi rx_done ──────────────────────────
    always @(posedge clk) begin
        if (rx_done)
            $display("[RX] Nhận được: 0x%02X | Error: %b", rx_data, rx_error);
        if (rx_error)
            $display("[ERROR] Frame error phát hiện!");
    end

endmodule
