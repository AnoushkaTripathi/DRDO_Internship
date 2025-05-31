module PeakFind (
    input wire clk,
    input wire rst_n,        // active low reset
    input wire rdy,          // ready signal
    input wire [7:0] FreqIn, // 8-bit input frequency
    output reg rd,
    output reg pk_done,
    output reg PkClk,
    output reg [11:0] addr_out,
    output reg [11:0] PeakX,
    output reg [13:0] PeakY
);

    // State
    reg [3:0] step_pk;
    reg [3:0] pk_no;

    // Internal registers
    reg [11:0] MxId, MxPos;
    reg [11:0] ctr_time, tim_span, span_cnt, span_Min;
    reg [13:0] FreqNow, Mn, Mx, MxPosY, MnPosY, MxAbs, MnAbs;

    reg LukFrMax, IsPeak;

    // Constants (tuned for 8-bit data)
    localparam DELTA  = 8'd5;
    localparam SPREAD = 12'd60;
    localparam MINTOL = 8'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all signals
            step_pk   <= 4'd0;
            pk_no     <= 4'd0;
            MxId      <= 0;
            MxPos     <= 0;
            ctr_time  <= 0;
            tim_span  <= 0;
            span_cnt  <= 0;
            span_Min  <= 0;
            FreqNow   <= 0;
            Mn        <= 14'h3FFF; // max 14-bit
            Mx        <= 0;
            MxPosY    <= 0;
            MnPosY    <= 14'h3FFF;
            MxAbs     <= 0;
            MnAbs     <= 14'h3FFF;
            LukFrMax  <= 0;
            IsPeak    <= 0;
            rd        <= 0;
            pk_done   <= 1;
            PkClk     <= 0;
            PeakX     <= 0;
            PeakY     <= 0;
            addr_out  <= 0;
        end else begin
            case (step_pk)
                4'd0: begin
                    ctr_time <= 12'd50;
                    tim_span <= 12'd30;
                    step_pk  <= 4'd1;
                end
                4'd1: begin
                    if (rdy) begin
                        step_pk <= 4'd2;
                        pk_done <= 1;
                    end
                end
                4'd2: begin
                    addr_out <= ctr_time + span_cnt;
                    rd <= 1;
                    step_pk <= 4'd3;
                end
                4'd3: step_pk <= 4'd4;
                4'd4: step_pk <= 4'd5;
                4'd5: begin
                    FreqNow <= FreqIn;
                    step_pk <= 4'd6;
                end
                4'd6: begin
                    if (FreqNow > MxAbs)
                        MxAbs <= FreqNow;
                    if (FreqNow < MnAbs)
                        MnAbs <= FreqNow;
                    if (FreqNow > Mx) begin
                        Mx    <= FreqNow;
                        MxPos <= ctr_time + span_cnt;
                        MxPosY <= FreqIn;
                        MxId  <= ctr_time + span_cnt;
                    end
                    if (FreqNow < Mn) begin
                        Mn <= FreqNow;
                        MnPosY <= FreqIn;
                    end
                    step_pk <= 4'd7;
                end
                4'd7: begin
                    if (LukFrMax) begin
                        if (FreqNow < (Mx - DELTA)) begin
                            if ((ctr_time + span_cnt - MxId < SPREAD) &&
                                (span_cnt - span_Min > MINTOL)) begin
                                PeakX <= MxPos;
                                PkClk <= 1;
                                IsPeak <= 1;
                            end
                            Mn <= FreqNow;
                            Mx <= FreqNow;
                            LukFrMax <= 0;
                        end
                    end else begin
                        PkClk <= 0;
                        if (FreqNow > (Mn + DELTA)) begin
                            Mx <= FreqNow;
                            MxPos <= ctr_time + span_cnt;
                            MxPosY <= FreqIn;
                            LukFrMax <= 1;
                            span_Min <= span_cnt;
                        end
                    end
                    span_cnt <= span_cnt + 1;
                    step_pk <= 4'd8;
                end
                4'd8: begin
                    if (span_cnt <= tim_span - 1)
                        step_pk <= 4'd2;
                    else begin
                        span_cnt <= 0;
                        step_pk <= 4'd9;
                    end
                end
                4'd9: begin
                    if (IsPeak)
                        PeakY <= MxAbs - MnAbs;
                    step_pk <= 4'd10;
                end
                4'd10: step_pk <= 4'd11;
                4'd11: step_pk <= 4'd12;
                4'd12: step_pk <= 4'd13;
                4'd13: begin
                    pk_done <= 0;
                    step_pk <= 4'd14;
                end
                4'd14: begin
                    pk_no <= pk_no + 1;
                    PkClk <= 0;
                    PeakX <= 0;
                    PeakY <= 0;
                    LukFrMax <= 0;
                    Mn <= 14'h3FFF;
                    Mx <= 0;
                    MxId <= 0;
                    FreqNow <= 0;
                    MxPos <= 0;
                    MxPosY <= 0;
                    MnAbs <= 14'h3FFF;
                    MxAbs <= 0;
                    addr_out <= 0;
                    span_cnt <= 0;
                    span_Min <= 0;
                    rd <= 0;
                    IsPeak <= 0;
                    step_pk <= 4'd15;
                end
                4'd15: begin
                    case (pk_no)
                        4'd1: begin
                            ctr_time <= 12'd100;
                            tim_span <= 12'd80;
                        end
                        4'd2: begin
                            ctr_time <= 12'd180;
                            tim_span <= 12'd240;
                        end
                    endcase
                    step_pk <= 4'd1;
                    pk_done <= 1;
                end
            endcase
        end
    end
endmodule


