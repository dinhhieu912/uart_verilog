module baud_gen (
    input  wire clk,
    input  wire rst,
    output reg  tick    // ticks at 16 × BAUD_RATE
);
    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 9600;
    // 16x oversampling: tick at 16 × baud rate
    parameter MAX_COUNT = CLK_FREQ / (BAUD_RATE * 16) - 1; // = 324 for 9600

    reg [8:0] counter; // 9 bits enough for 324

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick    <= 0;
        end
        else if (counter == MAX_COUNT) begin
            counter <= 0;
            tick    <= 1;
        end
        else begin
            counter <= counter + 1;
            tick    <= 0;
        end
    end
endmodule
