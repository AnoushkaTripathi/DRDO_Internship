`timescale 1ns/1ns
module uart_tb;
    // Declare registers and wires
    reg clk = 0, rst = 0;
    reg rx = 1;
    reg [7:0] dintx;
    reg newd;
    wire tx; 
    wire [7:0] doutrx;
    wire donetx;
    wire donerx;
    
    // Instantiate the UART module
    uart_top #(1000000, 9600) dut (
        .clk(clk), 
        .rst(rst), 
        .rx(rx), 
        .dintx(dintx), 
        .newd(newd), 
        .tx(tx), 
        .doutrx(doutrx), 
        .donetx(donetx), 
        .donerx(donerx)
    );
  
   initial
     begin
       clk = 0; 
       rst = 0;
       rx = 1;
       dintx=8'b0;
       newd=0;
     end

    // Clock generation
    always #10 clk = ~clk;  
    
    // Testbench variables
    reg [7:0] rx_data = 0;
    reg [7:0] tx_data = 0;
    integer i, j;

    initial begin
        // Initial reset
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;

        // Transmission loop
        for(i = 0; i < 10; i = i + 1) begin
            rst = 0;
            newd = 1;
            dintx = $random(); // Assign random data to transmit
            
            wait(tx == 0);
            @(posedge dut.utx.uclk);
            
            for(j = 0; j < 8; j = j + 1) begin
                @(posedge dut.utx.uclk);
                tx_data = {tx, tx_data[7:1]}; // Shift in tx bits
            end
            
            @(posedge donetx); // Wait until transmission is done
        end

        // Reception loop
        for(i = 0; i < 10; i = i + 1) begin
            rst = 0;
            newd = 0;
            
            rx = 1'b0; // Start bit
            @(posedge dut.utx.uclk);
            
            for(j = 0; j < 8; j = j + 1) begin
                @(posedge dut.utx.uclk);
                rx = $random(); // Simulate incoming random data
                rx_data = {rx, rx_data[7:1]}; // Shift in rx bits
            end
            
            @(posedge donerx); // Wait until reception is done
        end
    end
  

endmodule