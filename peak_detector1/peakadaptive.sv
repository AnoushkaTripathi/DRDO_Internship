module peak_detection #(
    parameter integer MAX_LAG = 64,
    parameter integer Q = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [15:0]    new_sample,   // Q8.8 fixed-point
    input  wire [5:0]            lag,          // max 64
    input  wire [15:0]           threshold,    // Q8.8
    input  wire [15:0]           influence,    // Q8.8
    input  wire                  en,
    output reg  signed [15:0]    filtered_value,
    output reg                   peak_status
);

    reg signed [15:0] data     [0:MAX_LAG-1];
    reg signed [15:0] avg      [0:MAX_LAG-1];
    reg signed [15:0] std      [0:MAX_LAG-1];

    integer i;
    reg [13:0] index;
    reg [5:0] i_mod;
    reg [5:0] j_mod;

    reg signed [15:0] deviation;
    reg signed [31:0] data_sum, data_sq_sum;
    reg signed [15:0] mean, mean_sq, variance, std_val;
    reg signed [15:0] new_data;
    reg signed [15:0] one_minus_infl;

    reg [3:0] peak_hold_counter;
    reg       peak_latched;

    initial begin
        index = 0;
        peak_status = 0;
        peak_hold_counter = 0;
        peak_latched = 0;
        for (i = 0; i < MAX_LAG; i = i + 1) begin
            data[i] = 0;
            avg[i]  = 0;
            std[i]  = 1 << Q;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            index <= 0;
            peak_status <= 0;
            peak_hold_counter <= 0;
            peak_latched <= 0;
            for (i = 0; i < MAX_LAG; i = i + 1) begin
                data[i] <= 0;
                avg[i]  <= 0;
                std[i]  <= 1 << Q;
            end
        end else if (en) begin
            i_mod = index % lag;
            j_mod = (index + 1) % lag;

            deviation = new_sample - avg[i_mod];
            one_minus_infl = (1 << Q) - influence;

            if (deviation > ((threshold * std[i_mod]) >>> Q)) begin
                new_data = (influence * new_sample + one_minus_infl * data[i_mod]) >>> Q;
                peak_latched = 0;
                peak_hold_counter = 4;
            end else begin
                if (peak_hold_counter > 0)
                    peak_hold_counter = peak_hold_counter - 1;
                else
                    peak_latched = 1;
                new_data = new_sample;
            end

            data[j_mod] <= new_data;
            peak_status <= peak_latched;

            // Mean and STD update
            data_sum = 0;
            data_sq_sum = 0;
            for (i = 0; i < lag; i = i + 1) begin
                data_sum = data_sum + data[(j_mod + i) % lag];
                data_sq_sum = data_sq_sum + data[(j_mod + i) % lag] * data[(j_mod + i) % lag];
            end

            mean = data_sum / lag;
            mean_sq = (mean * mean) >>> Q;
            variance = (data_sq_sum / lag) - mean_sq;
            std_val = (variance > 0) ? sqrt_approx(variance) : (1 << Q);

            avg[j_mod] <= mean;
            std[j_mod] <= std_val;

            filtered_value <= mean;
            index <= (index >= 16383) ? (lag + j_mod) : (index + 1);
        end
    end

    // Simple iterative sqrt
    function signed [15:0] sqrt_approx;
        input signed [15:0] x;
        integer j;
        begin
            sqrt_approx = 0;
            for (j = 15; j >= 0; j = j - 1)
                if ((sqrt_approx + (1 << j)) * (sqrt_approx + (1 << j)) <= (x <<< Q))
                    sqrt_approx = sqrt_approx + (1 << j);
        end
    endfunction

endmodule


