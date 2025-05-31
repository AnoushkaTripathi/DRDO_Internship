`timescale 1ns / 1ps

module tb;

parameter DATA_WIDTH = 16; // Q8.8 format

reg clk;
reg rst;
reg signed [DATA_WIDTH-1:0] sample_in;
reg valid_in;

wire signed [DATA_WIDTH-1:0] filt_out;
wire peak_out;

// Instantiate the DUT
peak_detection #(
    .MAX_LAG(64),  // Must match the design
    .Q(8)          // Q8.8 fixed-point
) dut (
    .clk(clk),
    .rst(rst),
    .new_sample(sample_in),
    .lag(6'd32),                          // DEFAULT_LAG
    .threshold(16'd256),                 // 2.0 in Q8.8 format (2 << 8)
    .influence(16'd128),                 // 0.5 in Q8.8 format (0.5 * 256)
    .en(valid_in),
    .filtered_value(filt_out),
    .peak_status(peak_out)
);

// Clock generation
always #5 clk = ~clk; // 100 MHz clock

// Signal memory for test input
reg signed [7:0] signal_mem [0:999];
integer i;

initial begin
    $display("Loading input signal...");
    $readmemh("8bit.txt", signal_mem); // 8-bit signed samples

    // Initial values
    clk = 0;
    rst = 1;
    valid_in = 0;
    sample_in = 0;

    // Reset pulse
    #20 rst = 0;

    // Feed in test samples
    for (i = 0; i < 1000; i = i + 1) begin
        @(posedge clk);
        sample_in <= { {8{signal_mem[i][7]}}, signal_mem[i] }; // Sign-extend 8-bit to 16-bit
        valid_in <= 1;

        // Debug print
        #1 $display("Time %0t ns: Sample = %0d, FiltOut = %0d, Peak = %0d", 
                    $time, sample_in, filt_out, peak_out);
    end

    valid_in <= 0;

    // Allow time for final outputs
    repeat (20) @(posedge clk);
    $finish;
end

endmodule



