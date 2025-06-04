`timescale 1ns / 1ps
module tb;

    parameter DATA_WIDTH = 16; // Q8.8 format

    reg clk;
    reg rst;
    reg signed [DATA_WIDTH-1:0] sample_in;
    reg valid_in;

    wire signed [DATA_WIDTH-1:0] filt_out;
    wire peak_out;
    wire signed [DATA_WIDTH-1:0] peakX;
    wire signed [13:0] peakY;
    wire [7:0] peak_count_out;

    // Instantiate the DUT
    peak_detection #(
        .MAX_LAG(64),
        .Q(8)
    ) dut (
        .clk(clk),
        .rst(rst),
        .new_sample(sample_in),
        .lag(6'd32),
        .threshold(16'd512),   // Q8.8: 2.0
        .influence(16'd256),   // Q8.8: 1.0
        .en(valid_in),
        .filtered_value(filt_out),
        .peak_point(peak_out),
        .peakx(peakX),
        .peaky(peakY),
        .peak_count_out(peak_count_out)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock

    // Signal memory for test input
    reg signed [7:0] signal_mem [0:999];
    integer i;

    // Track old region status to detect region end

    initial begin
        $display("Loading input signal...");
        $readmemh("8bit.txt", signal_mem); // 8-bit signed samples in hex

        // Initialize
        clk = 0;
        rst = 1;
        valid_in = 0;
        sample_in = 0;

        // Reset DUT
        #20 rst = 0;

        // Apply samples
        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
            sample_in <= { {8{signal_mem[i][7]}}, signal_mem[i] }; // Sign-extend
            valid_in <= 1;

            // Detect and report each peak pulse
            if (peak_out) begin
                #1 $display(">> PEAK DETECTED @ %0t ns: Value = %0d, Index = %0d", 
                           $time, peakX, peakY);
            end

      

        end

        valid_in <= 0;

        // Let output settle
        repeat (20) @(posedge clk);
        $finish;
    end

endmodule


