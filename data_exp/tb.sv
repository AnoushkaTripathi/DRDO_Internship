`include "memory.sv"

module tb_memory;
    logic clk;
    logic we;
    logic [3:0] addr;     // Adjust according to your memory size (4-bit for 16 addresses)
    logic [7:0] wdata;
    logic [7:0] rdata;
    integer file, status;
    integer i;
    logic [7:0] file_data;  // 8-bit data from the file

    memory uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );
    
    // Clock generation
    always #5 clk = ~clk;  // 10ns clock period
    
    // Testbench initialization
    initial begin
        clk = 0;
        we = 0;
        addr = 0;
        wdata = 0;
        
        // Open the file for reading
        file = $fopen("8bit.txt", "r");
        if (file == 0) begin
            $display("Error: Failed to open file.");
            $finish;
        end
        
        // Read 1000 points from the file and write them into memory
        for (i = 0; i < 1000; i++) begin
            status = $fscanf(file, "%h\n", file_data);  // Read 8-bit data in hexadecimal
            if (status != 1) begin
                $display("Error: Failed to read data.");
                $finish;
            end
            
            we = 1;
            addr = i % 16;  // Use modulus if the address is smaller than 1000
            wdata = file_data;
            #10;  // Wait for a clock cycle for the write to complete
            
            we = 0;
            #10;  // Wait another cycle for the read
        end
        
        $fclose(file);  // Close the file after reading
        $finish;
    end
    
    // Generate waveform dump
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_memory);
    end
endmodule

