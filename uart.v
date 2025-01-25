
module uart_top
#(
    parameter clk_freq = 1000000,
    parameter baud_rate = 9600
)
(
    input clk, rst, 
    input rx,
    input [7:0] dintx,
    input newd,
    output tx, 
    output [7:0] doutrx,
    output donetx,
    output donerx
);

    // Instantiate uarttx (Transmitter)
    uarttx #(clk_freq, baud_rate) utx (
        .clk(clk), 
        .rst(rst), 
        .newd(newd), 
        .tx_data(dintx), 
        .tx(tx), 
        .donetx(donetx)
    );   

    // Instantiate uartrx (Receiver)
    uartrx #(clk_freq, baud_rate) rtx (
        .clk(clk), 
        .rst(rst), 
        .rx(rx), 
        .done(donerx), 
        .rxdata(doutrx)
    );

endmodule

module uarttx
#(
    parameter clk_freq = 1000000,
    parameter baud_rate = 9600
)
(
    input clk, rst,
    input newd,
    input [7:0] tx_data,
    output reg tx,
    output reg donetx
);

    // Baud rate clock generation
    localparam clkcount = (clk_freq / baud_rate);
    
    integer count = 0;
    integer counts = 0;

    reg uclk = 0;

    // State declarations
    localparam idle = 2'b00,
               start = 2'b01,
               transfer = 2'b10,
               done = 2'b11;
    
    reg [1:0] state; // State register
    reg [7:0] din;   // Data to be transmitted
    
    // UART clock generation logic
    always @(posedge clk) begin
        if (count < clkcount / 2) begin
            count <= count + 1;
        end else begin
            count <= 0;
            uclk <= ~uclk;
        end
    end
    
    // Transmit logic
    always @(posedge uclk) begin
        if (rst) begin
            state <= idle;
        end else begin
            case (state)
                idle: begin
                    counts <= 0;
                    tx <= 1'b1;  // Idle state keeps tx line high
                    donetx <= 1'b0;
                    
                    if (newd) begin
                        state <= transfer;
                        din <= tx_data; // Load data to be transmitted
                        tx <= 1'b0;     // Start bit (low)
                    end
                end
                
                transfer: begin
                    if (counts < 8) begin
                        tx <= din[counts];  // Transmit one bit at a time
                        counts <= counts + 1;
                    end else begin
                        tx <= 1'b1;         // Stop bit (high)
                        state <= done;
                        donetx <= 1'b1;     // Transmission done
                    end
                end
                
                done: begin
                    state <= idle;
                    donetx <= 1'b0;
                end
                
                default: state <= idle;
            endcase
        end
    end
endmodule


module uartrx
#(
    parameter clk_freq = 1000000, // MHz
    parameter baud_rate = 9600
)
(
    input clk,
    input rst,
    input rx,
    output reg done,
    output reg [7:0] rxdata
);

    // Baud rate clock generation
    localparam clkcount = (clk_freq / baud_rate);
    
    integer count = 0;
    integer counts = 0;

    reg uclk = 0;
    
    // State declarations
    localparam idle = 2'b00,
               start = 2'b01,
               receive = 2'b10;
    
    reg [1:0] state;  // State register
    
    // UART clock generation logic
    always @(posedge clk) begin
        if (count < clkcount / 2) begin
            count <= count + 1;
        end else begin
            count <= 0;
            uclk <= ~uclk;
        end
    end
    
    // Receive logic
    always @(posedge uclk) begin
        if (rst) begin
            rxdata <= 8'h00;
            counts <= 0;
            done <= 1'b0;
            state <= idle;
        end else begin
            case (state)
                idle: begin
                    rxdata <= 8'h00;
                    counts <= 0;
                    done <= 1'b0;
                    
                    if (rx == 1'b0) begin  // Start bit detected (low)
                        state <= start;
                    end
                end
                
                start: begin
                    if (counts < 8) begin
                        rxdata <= {rx, rxdata[7:1]};  // Shift in received bits
                        counts <= counts + 1;
                    end else begin
                        state <= idle;
                        done <= 1'b1;  // Reception done
                    end
                end
                
                default: state <= idle;
            endcase
        end
    end
endmodule
