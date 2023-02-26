`timescale 1ns / 1ps

module non_linear_overlay (
    input [127:0] data_in,
    input [7:0] S_box_mem_in[0:255],

    output logic [7:0] data_non_linear_out[15:0]
);

  // Non-Linear overlay
  logic [7:0] data_key_result_bytes[15:0];

  generate
    for (genvar i = 0; i < 16; i++) begin
      assign data_key_result_bytes[i] = data_in[((i+1)*8)-1:(i*8)];   //  convert bits to bytes for extracting nums from S box
      assign data_non_linear_out[i] = S_box_mem_in[data_key_result_bytes[i]];
    end
  endgenerate

endmodule
