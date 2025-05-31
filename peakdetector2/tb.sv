`timescale 1ns / 1ps

module tb;

    // Parameters
    parameter SIGNAL_LENGTH = 1000;

    // Testbench Signals
    reg clk;
    reg rst_n;
    reg [7:0] FreqIn;
    reg rdy;

    wire rd;
    wire pk_done;
    wire PkClk;
    wire [11:0] addr_out;
    wire [11:0] PeakX;
    wire [13:0] PeakY;

    // Memory for test signal (8-bit signed)
    reg signed [7:0] signal_mem [0:SIGNAL_LENGTH-1];
    integer i;

    // Instantiate the DUT
    PeakFind dut (
        .clk(clk),
        .rst_n(rst_n),
        .rdy(rdy),
        .FreqIn(FreqIn),
        .rd(rd),
        .pk_done(pk_done),
        .PkClk(PkClk),
        .addr_out(addr_out),
        .PeakX(PeakX),
        .PeakY(PeakY)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    initial begin
        $display("Loading input signal...");
        $readmemh("8bit.txt", signal_mem); // Hex file with 8-bit samples

        // Initial conditions
        clk = 0;
        rst_n = 0;
        rdy = 0;
        FreqIn = 0;

        // Reset
        #20 rst_n = 1;

        // Feed signal data to DUT
        for (i = 0; i < SIGNAL_LENGTH; i = i + 1) begin
            @(posedge clk);
            if (rd) begin
                FreqIn <= signal_mem[i];
                rdy <= 1;
                $display("Time %0t ns: addr = %0d, FreqIn = %0d", $time, i, signal_mem[i]);
            end else begin
                rdy <= 0;
            end

            // Monitor peak detection
            if (PkClk) begin
                $display(">>> PEAK DETECTED at time %0t ns: PeakX = %0d, PeakY = %0d", 
                    $time, PeakX, PeakY);
            end
        end

        // Allow some time for final peaks
        repeat (20) @(posedge clk);
        $finish;
    end

endmodule

