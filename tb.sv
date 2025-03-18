`timescale 1ns/1ps
`include "peakdetection.sv"

module tb_peak_detection;
    // Testbench signals
    reg clk;
    reg reset;
    wire peak_detected;
    wire [9:0] peak_addr;   // Adjust to match the expected address width (10 bits)
    wire [7:0] peak_value;  // Output value of the peak detected
    reg start;
    wire done;

    // Clock generation
    always #5 clk = ~clk;

    // Instantiate the peak detection module
    peak_detection uut (
        .clk(clk),
        .reset(reset),
        .peak_detected(peak_detected),
        .peak_addr(peak_addr),
        .peak_value(peak_value),
        .start(start),
        .done(done)
    );

    // Testbench initialization
    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        #10 reset = 0;  // Deassert reset
        #10 start = 1;  // Start the peak detection process

        // Wait for peak detection
        #5000;  // Enough time to process data

        // End the simulation
       
    end

    // Monitor the peak detection output
    initial begin
        $monitor("At time %0t: peak_detected = %b, peak_addr = %d, peak_value = %h", $time, peak_detected, peak_addr, peak_value);
    end

    // Generate waveform for simulation viewing
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_peak_detection);
    end
endmodule

