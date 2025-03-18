module memory #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8, DEPTH = 1000) (
    input logic clk,
    input logic we,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh("8bit.txt", mem); // Load memory from a text file (hex format)
    end
    
    always_ff @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        rdata <= mem[addr];
    end
endmodule
