`timescale 1ns / 1ps

module key_overlay (
    input [127:0] data_in,
    input logic [3:0] trial_num_in,
    input logic [127:0] key_mem_in[0:9],

    output logic [127:0] data_key_out
);

  // Key overlay
  logic [127:0] round_key;
  assign round_key = key_mem_in[trial_num_in];

  assign data_key_out = data_in ^ round_key;

endmodule
