// -----------------------------------------------------------------------------
// fir_filter.v  --  BASELINE version (v1)
//
// 16-tap direct-form low-pass FIR, 16-bit signed input/output, Q1.15 coeffs.
//   * input samples are shifted through a 16-register delay line
//   * 16 multiplies + a 4-level adder tree are fully COMBINATIONAL
//   * only the result is registered
// This long multiply->add path is the intentional critical path that the
// improvement (pipelining) will shorten.
//
// Latency: 2 clock cycles from x_in to y_out.
// Reset  : synchronous, active high.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module fir_filter #(
    parameter N  = 16,           // taps (must match fir_coeffs.vh)
    parameter DW = 16,           // input / output width
    parameter CW = 16,           // coefficient width (Q1.15)
    parameter AW = DW + CW + 4   // accumulator width: 16+16+log2(16) = 36
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [DW-1:0] x_in,
    output reg  signed [DW-1:0] y_out
);

    `include "fir_coeffs.vh"     // defines COEFFS (packed, tap k at [k*CW +: CW])

    // ---- delay line ---------------------------------------------------------
    reg signed [DW-1:0] x_reg [0:N-1];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) x_reg[i] <= {DW{1'b0}};
        end else begin
            x_reg[0] <= x_in;
            for (i = 1; i < N; i = i + 1) x_reg[i] <= x_reg[i-1];
        end
    end

    // ---- combinational multiply + sum --------------------------------------
    reg signed [AW-1:0] acc;
    reg signed [CW-1:0] h;
    integer k;
    always @* begin
        acc = {AW{1'b0}};
        for (k = 0; k < N; k = k + 1) begin
            h   = COEFFS[k*CW +: CW];
            acc = acc + x_reg[k] * h;
        end
    end

    // ---- scale back to Q1.15 (drop 15 fractional bits) and saturate ---------
    localparam signed [AW-1:0] MAX_V =  (1 <<< (DW-1)) - 1;
    localparam signed [AW-1:0] MIN_V = -(1 <<< (DW-1));

    wire signed [AW-1:0] scaled = acc >>> (CW-1);

    always @(posedge clk) begin
        if (rst)                  y_out <= {DW{1'b0}};
        else if (scaled > MAX_V)  y_out <= MAX_V[DW-1:0];
        else if (scaled < MIN_V)  y_out <= MIN_V[DW-1:0];
        else                      y_out <= scaled[DW-1:0];
    end

endmodule
