// -----------------------------------------------------------------------------
// stim_gen.v -- on-chip test-signal generator for the PYNQ-Z2 demo
//
// Gives the FIR something worth filtering without needing external pins.
// All outputs are registered (x comes straight from flip-flops).
//   mode 0 : constant 'amp'            -> step response when amp is changed
//   mode 1 : slow square wave (period 64 samples, +/-amp)      -> low frequency, passes
//   mode 2 : fast alternating +amp,-amp every sample (fs/2)    -> high frequency, attenuated
//   mode 3 : half of slow + half of fast                       -> filter should remove the fast part
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module stim_gen #(parameter DW = 16) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire [1:0]           mode,
    input  wire signed [DW-1:0] amp,
    output reg  signed [DW-1:0] x
);
    reg [5:0] cnt;        // slow square: cnt[5] flips every 32 samples
    reg       tog;        // fast alternation

    wire signed [DW-1:0] slow = cnt[5] ? -amp : amp;
    wire signed [DW-1:0] fast = tog    ? -amp : amp;

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 6'd0;
            tog <= 1'b0;
            x   <= {DW{1'b0}};
        end else begin
            cnt <= cnt + 6'd1;
            tog <= ~tog;
            case (mode)
                2'd0:    x <= amp;
                2'd1:    x <= slow;
                2'd2:    x <= fast;
                default: x <= (slow >>> 1) + (fast >>> 1);
            endcase
        end
    end
endmodule
