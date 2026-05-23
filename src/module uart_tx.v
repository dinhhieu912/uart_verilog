module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,
    input  wire       tx_start,
    input  wire [7:0] tx_data,

    input  wire       parity_en,   // 1 = enable parity


    input  wire       parity_type, // 0 = even, 1 = odd


    input  wire       stop_bits,   // 0 = 1 stop bit, 1 = 2 stop bits

    output reg        tx,
    output reg        tx_busy
);
    localparam IDLE   = 3'b000;
    localparam START  = 3'b001;
    localparam DATA   = 3'b010;

    localparam PARITY = 3'b011;

    localparam STOP   = 3'b100;

    localparam STOP2  = 3'b101;


    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;

    reg       parity_calc; // running XOR of transmitted bits


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            tx          <= 1;
            tx_busy     <= 0;
            shift_reg   <= 0;
            bit_cnt     <= 0;

            parity_calc <= 0;

        end
        else begin
            case (state)
                IDLE: begin
                    tx      <= 1;
                    tx_busy <= 0;
                    if (tx_start) begin
                        shift_reg   <= tx_data;

                        parity_calc <= 0;

                        bit_cnt     <= 0;
                        tx_busy     <= 1;
                        state       <= START;
                    end
                end

                START: begin
                    if (tick) begin
                        tx    <= 0; // start bit
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (tick) begin
                        tx          <= shift_reg[0];

                        parity_calc <= parity_calc ^ shift_reg[0]; // accumulate XOR

                        shift_reg   <= shift_reg >> 1;
                        if (bit_cnt == 7)

                            state <= parity_en ? PARITY : STOP;

                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                end


                PARITY: begin
                    if (tick) begin
                        // even: send parity_calc (XOR=0 means even count)
                        // odd:  send ~parity_calc
                        tx    <= parity_type ? ~parity_calc : parity_calc;
                        state <= STOP;
                    end
                end


                STOP: begin
                    if (tick) begin
                        tx    <= 1; // stop bit

                        state <= stop_bits ? STOP2 : IDLE;

                    end
                end


                STOP2: begin
                    if (tick) begin
                        tx    <= 1; // second stop bit
                        state <= IDLE;
                    end
                end


                default: state <= IDLE;
            endcase
        end
    end
endmodule
