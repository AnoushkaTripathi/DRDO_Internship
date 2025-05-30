`timescale 1ns / 1ps

module tb;

parameter DATA_WIDTH = 16;        // Q8.8 fixed-point format (as used)
parameter LAG = 32;                // Good length based on peak separation (~20-40 samples apart)
parameter INFLUENCE = 256;          // 0.25 in Q1.8 => (0.25 * 256 = 64), more smoothing
parameter EPSILON = 8;             // Minimum variance, prevents divide-by-zero (0.03 in Q8.8)
parameter THRESHOLD = 64;         // 1.5 in Q1.8 => 1.5 * 256 = 384 (moderate sensitivity)

    reg clk;
    reg rst;
    reg signed [DATA_WIDTH-1:0] sample_in;
    reg valid_in;

    wire signed [DATA_WIDTH-1:0] filtered_out;
    wire [2*DATA_WIDTH-1:0] variance_out;
    wire valid_out;
wire peak_out;
    // Instantiate the DUT
    AdaptiveFilter #(
        .DATA_WIDTH(DATA_WIDTH),
        .LAG(LAG),
        .INFLUENCE(INFLUENCE),
        .EPSILON(EPSILON)
    ) uut (
        .clk(clk),
        .rst(rst),
        .sample_in(sample_in),
        .valid_in(valid_in),
        .filtered_out(filtered_out),
        .variance_out(variance_out),
        .valid_out(valid_out),
         .peak_out(peak_out)
         
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    // Memory to hold 1000 samples
    reg signed [7:0] signal_mem [0:999];
    integer i;

    initial begin
        $display("Loading data...");
        $readmemh("8bit.txt", signal_mem); // Make sure 8bit.txt is in the working directory

        clk = 0;
        rst = 1;
        valid_in = 0;
        sample_in = 0;

        #20 rst = 0;

        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
            sample_in <= { {8{signal_mem[i][7]}}, signal_mem[i] }; // Sign-extend 8-bit to 16-bit
            valid_in <= 1;
        end

        // Wait a few more cycles after feeding data
        valid_in <= 0;
        repeat (20) @(posedge clk);
        $finish;
    end

endmodule

