module AdaptiveFilterRuntime #(
    parameter DATA_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         begin_config,        // start config load
    input  wire [7:0]                   cfg_lag,             // max 255
    input  wire [15:0]                  cfg_threshold,       // Q8.8
    input  wire [7:0]                   cfg_influence,       // Q1.7
    input  wire                         valid_in,
    input  wire signed [DATA_WIDTH-1:0] sample_in,

    output reg  signed [DATA_WIDTH-1:0] filtered_out,
    output reg  [2*DATA_WIDTH-1:0]      variance_out,
    output reg                          valid_out,
    output reg                          peak_out
);

    // Default parameters
    localparam DEFAULT_LAG = 32;
    localparam DEFAULT_THRESHOLD = 256; // 1.0 in Q8.8
    localparam DEFAULT_INFLUENCE = 64;  // 0.5 in Q1.7

    // Configurable runtime parameters
    reg [7:0]   lag;
    reg [15:0]  threshold;
    reg [7:0]   influence;

    // Internal circular buffer
    reg signed [DATA_WIDTH-1:0] buffer [0:255];
    reg [7:0] index;

    // Accumulators
    reg signed [DATA_WIDTH+8:0] sum;
    reg signed [2*DATA_WIDTH+8:0] sum_sq;
    reg signed [DATA_WIDTH+8:0] mean;
    reg signed [2*DATA_WIDTH+8:0] mean_sq, ex2, raw_var;
    reg signed [DATA_WIDTH+8:0] deviation;
    reg signed [2*DATA_WIDTH+8:0] deviation_sq, threshold_scaled;
    reg signed [DATA_WIDTH-1:0] adjusted_sample;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lag <= DEFAULT_LAG;
            threshold <= DEFAULT_THRESHOLD;
            influence <= DEFAULT_INFLUENCE;
            index <= 0;
            peak_out <= 0;
            filtered_out <= 0;
            variance_out <= 0;
            valid_out <= 0;
            for (i = 0; i < 256; i = i + 1)
                buffer[i] <= 0;

        end else begin
            // Load runtime config
            if (begin_config) begin
                lag <= (cfg_lag != 0) ? cfg_lag : DEFAULT_LAG;
                threshold <= (cfg_threshold != 0) ? cfg_threshold : DEFAULT_THRESHOLD;
                influence <= (cfg_influence != 0) ? cfg_influence : DEFAULT_INFLUENCE;
            end

            peak_out <= 0;
            valid_out <= 0;

            if (valid_in) begin
                // Compute mean and variance
                sum = 0;
                sum_sq = 0;
                for (i = 0; i < lag; i = i + 1) begin
                    sum = sum + buffer[i];
                    sum_sq = sum_sq + buffer[i] * buffer[i];
                end

                mean = sum / lag;
                mean_sq = mean * mean;
                ex2 = sum_sq / lag;
                raw_var = ex2 - mean_sq;

                if (raw_var < 8)
                    variance_out <= 8;
                else
                    variance_out <= raw_var[2*DATA_WIDTH-1:0];

                filtered_out <= mean[DATA_WIDTH-1:0];
                valid_out <= 1;

                // Deviation logic
                deviation = sample_in - mean;
                deviation_sq = deviation * deviation;
                threshold_scaled = (raw_var * threshold) >> 8;

                if (deviation > 0 && deviation_sq > threshold_scaled) begin
                    peak_out <= 1;
                    adjusted_sample <= ((influence * sample_in) + ((128 - influence) * mean[DATA_WIDTH-1:0])) >> 7;
                    buffer[index] <= adjusted_sample;
                end else begin
                    buffer[index] <= sample_in;
                end

                index <= (index == lag - 1) ? 0 : index + 1;
            end
        end
    end
endmodule



