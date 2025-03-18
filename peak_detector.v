`include "memory.sv"

module peak_detection #(parameter inputWidth = 8, parameter windowSize = 16)(
    input wire clk,
    input wire reset,
    input wire start,       // Signal to start the peak detection process
    output reg done,        // Signal indicating the completion of the detection
    output reg peak_detected,
    output reg [9:0] peak_addr,  // 10-bit address width for 1000 points
    output reg [inputWidth-1:0] peak_value // Value of the detected peak
);
    // Memory interface signals
    reg we;
    reg [9:0] addr;  // 10-bit address to cover 1000 points
    wire [inputWidth-1:0] rdata;  // Data read from memory

    // Sliding window buffer
    reg [inputWidth-1:0] sliding_window [0:windowSize-1]; 
    reg [inputWidth-1:0] maxS, minS;  // Max and Min in the window
    reg [inputWidth-1:0] tW, bW;  // Top and bottom heights
    reg [4:0] counter;  // Sample counter
    reg [inputWidth-1:0] vW;  // Vertical center height of window
    reg [9:0] index;  // Index for window

    integer i;

    // Memory instantiation
    memory #(.ADDR_WIDTH(10), .DATA_WIDTH(8), .DEPTH(1000)) mem_inst (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(8'b0),
        .rdata(rdata)
    );

    // Reset and clock control for sliding window and detection
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr <= 0;
            counter <= 0;
            index <= 0;
            peak_detected <= 0;
            done <= 0;
            maxS <= 0;
            minS <= 8'hFF;  // Maximum value for 8-bit data
        end else if (start) begin
            // Read data from memory
            if (addr < 1000) begin
                sliding_window[counter] <= rdata;
                addr <= addr + 1;
                counter <= counter + 1;

                // Find the maximum and minimum values in the sliding window
                if (rdata > maxS) maxS <= rdata;
                if (rdata < minS) minS <= rdata;

                // When the window is full, start processing for peak detection
                if (counter == windowSize) begin
                    counter <= 0;

                    // Calculate the vertical center height (vW)
                    vW <= (maxS + minS) >> 1;

                    // Calculate the top and bottom heights
                    tW <= vW + (maxS >> 2);
                    bW <= vW - (maxS >> 2);

                    // Reset max and min for the next window
                    maxS <= 0;
                    minS <= 8'hFF;

                    // Check for peaks within the sliding window
                    for (i = 0; i < windowSize; i = i + 1) begin
                        if (sliding_window[i] > tW && sliding_window[i] < bW) begin
                            peak_detected <= 1;  // Peak detected
                            peak_addr <= addr - windowSize + i;  
                            peak_value <= sliding_window[i];  // Detected peak value
                        end
                    end
                end
            end else begin
                done <= 1;  // Detection process completed
            end
        end
    end
endmodule
