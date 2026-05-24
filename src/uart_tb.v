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

    // FIX 1: Loopback — chỉ khai báo rx một lần duy nhất
    // (bản gốc khai báo rx hai lần: một trong danh sách wire, một ở đây)
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

    // Clock 50MHz → chu kỳ 20ns
    initial clk = 0;
    always #10 clk = ~clk;

    // Timeout = 2ms (đủ cho 1 byte ở 9600 baud)
    localparam TIMEOUT = 2_000_000;

    // FIX 2: pass_cnt và fail_cnt được cập nhật bên trong task
    integer pass_cnt, fail_cnt;

    // Task gửi 1 byte, có timeout watchdog và cập nhật counter
    task send_byte;
        input [7:0] data;
        integer t;
        begin
            wait (!tx_busy);
            @(posedge clk);
            tx_data  = data;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;

            // Chờ rx_done với timeout
            t = 0;
            while (!rx_done && t < TIMEOUT) begin
                @(posedge clk);
                t = t + 1;
            end

            if (t >= TIMEOUT) begin
                $display("[TIMEOUT] Byte 0x%02X không nhận được!", data);
                // FIX 2: tính timeout là fail
                fail_cnt = fail_cnt + 1;
            end
            else if (rx_data == data) begin
                $display("[PASS] Sent: 0x%02X | Received: 0x%02X", data, rx_data);
                // FIX 2: tăng pass_cnt
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("[FAIL] Sent: 0x%02X | Received: 0x%02X (expected 0x%02X)",
                          data, rx_data, data);
                // FIX 2: tăng fail_cnt
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
        rst      = 1;
        tx_start = 0;
        tx_data  = 0;
        // FIX 2: khởi tạo counter
        pass_cnt = 0;
        fail_cnt = 0;

        repeat (5) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        $display("===== BẮT ĐẦU TEST UART =====");

        // Test 1: alternating bits
        $display("-- Test 1: 0x55 (0101_0101) --");
        send_byte(8'h55);
        $display("-- Test 2: 0xAA (1010_1010) --");
        send_byte(8'hAA);

        // Test 2: giá trị biên
        $display("-- Test 3: 0x00 và 0xFF (biên) --");
        send_byte(8'h00);
        send_byte(8'hFF);

        // Test 3: giá trị không đối xứng (lộ lỗi nghịch bit)
        $display("-- Test 4: 0x31, 0x12, 0xC3 (không đối xứng) --");
        send_byte(8'h31);
        send_byte(8'h12);
        send_byte(8'hC3);

        // Test 4: chuỗi liên tiếp
        $display("-- Test 5: chuỗi 0x00 → 0x04 --");
        send_byte(8'h00);
        send_byte(8'h01);
        send_byte(8'h02);
        send_byte(8'h03);
        send_byte(8'h04);

        // FIX 2: in tổng kết PASS/FAIL
        $display("===== KẾT THÚC TEST =====");
        $display("Tổng: PASS = %0d | FAIL = %0d | TOTAL = %0d",
                  pass_cnt, fail_cnt, pass_cnt + fail_cnt);

        if (fail_cnt == 0)
            $display(">>> TẤT CẢ TEST ĐỀU PASS ✓");
        else
            $display(">>> CÓ %0d TEST THẤT BẠI ✗", fail_cnt);

        repeat (100) @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

    // Monitor realtime
    always @(posedge clk) begin
        if (rx_done)
            $display("[RX] Nhận: 0x%02X | Error: %b", rx_data, rx_error);
        if (rx_error)
            $display("[ERROR] Frame error phát hiện!");
    end

endmodule
