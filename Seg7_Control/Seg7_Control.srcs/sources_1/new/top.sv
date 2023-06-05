`timescale 1ns / 1ps

module top (
    input logic clk100mhz,
    input logic cpu_resetn,

    output logic ca,
    output logic cb,
    output logic cc,
    output logic cd,
    output logic ce,
    output logic cf,
    output logic cg,
    output logic [7:0] an
);

  logic [31:0] num_reg;
  logic [31:0] reset_reg;

assign num_reg = 32'hF30230F1;

  /////////////////////////////////////
  // 7-Segment control instantiation //
  /////////////////////////////////////

  logic [`CATH_NUM-1:0] cath;
  assign cath = {cg, cf, ce, cd, cc, cb, ca};

  seg7_control my_disp (
      .clk_i(clk100mhz),
      .num(num_reg),
      .rst(~cpu_resetn),
      .cath(cath),
      .an(an)
  );
endmodule
