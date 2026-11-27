`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2026 05:05:39 PM
// Design Name: fir_filter version 2 
// Module Name: fir_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: baseline versiuon 1 had negative TNS which impacted setup time.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_filter #(
    parameter N  = 16,
    parameter DW = 16,
    parameter CW = 16,
    parameter AW = DW + CW + 4   // 36-bit partial sums
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [DW-1:0] x_in,
    output reg  signed [DW-1:0] y_out
);

    `include "fir_coeffs.vh"     // COEFFS (packed, tap k at [k*CW +: CW])

    // ---- transposed-form partial-sum registers
    reg signed [AW-1:0] s [0:N-1];
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < N; k = k + 1) s[k] <= {AW{1'b0}};
        end else begin
            s[N-1] <= x_in * $signed(COEFFS[(N-1)*CW +: CW]);
            for (k = 0; k < N-1; k = k + 1)
                s[k] <= x_in * $signed(COEFFS[k*CW +: CW]) + s[k+1];
        end
    end

    // ---- scale back to Q1.15 and saturate, then register
    localparam signed [AW-1:0] MAX_V =  (1 <<< (DW-1)) - 1;
    localparam signed [AW-1:0] MIN_V = -(1 <<< (DW-1));

    wire signed [AW-1:0] scaled = s[0] >>> (CW-1);

    always @(posedge clk) begin
        if (rst)                  y_out <= {DW{1'b0}};
        else if (scaled > MAX_V)  y_out <= MAX_V[DW-1:0];
        else if (scaled < MIN_V)  y_out <= MIN_V[DW-1:0];
        else                      y_out <= scaled[DW-1:0];
    end

endmodule
