`timescale 1ns/1ps
module all_mod_tb;

  reg clk, rst, wr, rd;
  reg rx;
  reg [2:0] addr;
  reg [7:0] din;

  wire tx;
  wire [7:0] dout;

  // Instantiate the DUT (Device Under Test)
  all_mod dut (
    .clk(clk),
    .rst(rst),
    .wr(wr),
    .rd(rd),
    .rx(rx),
    .addr(addr),
    .din(din),
    .tx(tx),
    .dout(dout)
  );

  // Parameters for RAM
  parameter RAM_DEPTH = 1024; // Depth of the RAM
  reg [7:0] ram [0:RAM_DEPTH-1]; // RAM to store data from .mem file
   integer i;
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 ns clock period
  end

  // Reset logic
  initial begin
    rst = 1;
    wr = 0;
    rd = 0;
    addr = 0;
    din = 0;
    rx = 1;
    repeat (5) @(posedge clk);
    rst = 0;
  end

  // Task to write data from RAM to FIFO
  task write_to_fifo(input [7:0] data);
    begin
      @(negedge clk);
      wr = 1;
      addr = 3'h0; // Address for Transmit Holding Register (THR)
      din = data;
      @(negedge clk);
      wr = 0;
    end
  endtask

  // Load .mem file into RAM
  initial begin
    // Load data from .mem file into RAM
    $readmemh("output_data.mem", ram);

    // Transmit data from RAM to FIFO
 
    for (i = 0; i < RAM_DEPTH; i = i + 1) begin
   
      write_to_fifo(ram[i]); // Transmit data
    end

    // Wait for all data to be transmitted
    @(posedge dut.uart_tx_inst.sreg_empty);
    repeat (48) @(posedge dut.uart_tx_inst.baud_pulse);

    $stop; // Stop simulation
  end

endmodule
