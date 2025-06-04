module peak_detection #( 
    parameter integer MAX_LAG = 64,
    parameter integer Q = 8,
    parameter [15:0] release_margin = 16'd128, // Q8.8
    parameter integer RELEASE_HYST = 9
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [15:0]    new_sample,   // Q8.8
    input  wire [5:0]            lag,
    input  wire [15:0]           threshold,
    input  wire [15:0]           influence,
    input  wire                  en,

    output reg  signed [15:0]    filtered_value,
    output reg                   valid_out,
    output reg                   peak_point,
    output reg  signed [15:0]    peakx,       // Value at peak_point
    output reg  [13:0]           peaky,       // Index at peak_point
    output reg  [7:0]            peak_count_out
);

    // Buffers
    reg signed [15:0] data [0:MAX_LAG-1];
    reg signed [15:0] avg  [0:MAX_LAG-1];
    reg signed [15:0] std  [0:MAX_LAG-1];

    // State
    reg [13:0] index;
    reg [5:0] i_mod, j_mod;
    reg signed [15:0] deviation, one_minus_infl, new_data;
    reg signed [31:0] data_sum, data_sq_sum;
    reg signed [15:0] mean, mean_sq, variance;
    reg signed [15:0] std_val;
    reg [31:0] temp_var;
    reg [15:0] res;
    integer i, k;

    // FSM
    reg in_peak_region;
    reg [3:0] release_counter;
    reg [7:0] peak_counter;

    always @(posedge clk) begin
        if (rst) begin
            index <= 0;
            valid_out <= 0;
            peak_point <= 0;
            peakx <= 0;
            peaky <= 0;
            peak_count_out <= 0;
            in_peak_region <= 0;
            release_counter <= 0;
            peak_counter <= 0;
            for (i = 0; i < MAX_LAG; i = i + 1) begin
                data[i] <= 0;
                avg[i]  <= 0;
                std[i]  <= 1 << Q;
            end
        end else if (en) begin
            peak_point <= 0;
            peak_count_out <= 0;

            i_mod = index % lag;
            j_mod = (index + 1) % lag;
            deviation = new_sample - avg[i_mod];
            one_minus_infl = (1 << Q) - influence;

            if (deviation > ((threshold * std[i_mod]) >>> Q)) begin
                // Start or continue peak region
                release_counter <= 0;
                new_data <= ((influence * new_sample) + (one_minus_infl * data[i_mod])) >>> Q;

                if (!in_peak_region) begin
                    in_peak_region <= 1;
                    peak_counter <= 1;
                end else begin
                    peak_counter <= peak_counter + 1;
                end
            end else begin
                new_data <= new_sample;

                if (in_peak_region) begin
                    if (new_sample < (avg[i_mod] + release_margin)) begin
                        release_counter <= release_counter + 1;
                        if (release_counter >= RELEASE_HYST) begin
                            // Exit: this is the moment we emit the peak
                            peak_point <= 1;
                            peakx <= new_sample;  // Use current sample
                            peaky <= index;
                            peak_count_out <= peak_counter;

                            in_peak_region <= 0;
                            release_counter <= 0;
                            peak_counter <= 0;
                        end
                    end else begin
                        release_counter <= 0;
                    end
                end
            end

            // Update data buffer
            data[j_mod] <= new_data;

            // Mean and Std Dev Calculation
            data_sum = 0;
            data_sq_sum = 0;
            for (i = 0; i < lag; i = i + 1) begin
                data_sum += data[(j_mod + i) % lag];
                data_sq_sum += data[(j_mod + i) % lag] * data[(j_mod + i) % lag];
            end
            mean = data_sum / lag;
            mean_sq = (mean * mean) >>> Q;
            variance = (data_sq_sum / lag) - mean_sq;
            temp_var = (variance > 0) ? (variance <<< Q) : (1 << (2 * Q));

            res = 0;
            for (k = 15; k >= 0; k = k - 1)
                if ((res | (1 << k)) * (res | (1 << k)) <= temp_var)
                    res = res | (1 << k);
            std_val = res;

            avg[j_mod] <= mean;
            std[j_mod] <= std_val;

            if (index >= lag) begin
                filtered_value <= mean;
                valid_out <= 1;
            end else begin
                filtered_value <= 0;
                valid_out <= 0;
            end

            index <= index + 1;
        end
    end
endmodule


