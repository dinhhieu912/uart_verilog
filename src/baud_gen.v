module baud_gen (
    input  wire clk,    // clock hệ thống 50MHz
    input  wire rst,    // reset tích cực mức cao
    output reg  tick    // xung baud rate, cao 1 chu kỳ clock
);

    // Tham số: số chu kỳ clock cho 1 baud
    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter MAX_COUNT = CLK_FREQ / BAUD_RATE - 1; // = 5207

    reg [12:0] counter; // 13 bit đủ chứa 5207

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick    <= 0;
        end
        else if (counter == MAX_COUNT) begin
            counter <= 0;
            tick    <= 1; // phát xung 1 chu kỳ
        end
        else begin
            counter <= counter + 1;
            tick    <= 0;
        end
    end

endmodule
