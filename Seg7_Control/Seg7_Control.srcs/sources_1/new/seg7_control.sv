`timescale 1ns / 1ps

/*
 * AN - Anode
 * CATH - Cathode
 */

`define AN_BIT_LEN 4
`define AN_NUM 8
`define CATH_NUM 7

`define AN_0 8'b11111110
`define AN_1 8'b11111101
`define AN_2 8'b11111011
`define AN_3 8'b11110111
`define AN_4 8'b11101111
`define AN_5 8'b11011111
`define AN_6 8'b10111111
`define AN_7 8'b01111111


module seg7_control #(
    parameter CLK_DIV = 8000
) (
    input clk_i,
    input [(`AN_NUM * `AN_BIT_LEN)-1:0] num,
    input rst,
    output logic [`CATH_NUM-1:0] cath,
    output logic [`AN_NUM-1:0] an
);

  logic [12:0] clk_cntr = 0;

  initial begin
    an <= 8'hff;
    refresh_cntr <= 0;
  end


  logic [$clog2(`AN_NUM):0] refresh_cntr;

  always @(posedge clk_i, posedge rst) begin
    if (rst) begin
      clk_cntr <= 0;
    end else if (clk_cntr >= CLK_DIV) begin
      clk_cntr <= 0;
    end else begin
      clk_cntr <= clk_cntr + 1;
    end
  end


  always @(posedge clk_i, posedge rst) begin
    if (rst) begin
      refresh_cntr <= 0;
      an <= `AN_0;
    end else if (clk_cntr == CLK_DIV) begin
      if (refresh_cntr >= (`AN_NUM - 1)) begin
        refresh_cntr <= 0;
        an <= `AN_0;
      end else begin
        refresh_cntr <= refresh_cntr + 1;
        an <= {an[0+:`AN_NUM-1], 1'b1};
      end
    end
  end

  always_comb begin
    if (!rst) begin
      case (an)
        `AN_0: begin
          case (num[3:0])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_1: begin
          case (num[7:4])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_2: begin
          case (num[11:8])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_3: begin
          case (num[15:12])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_4: begin
          case (num[19:16])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_5: begin
          case (num[23:20])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_6: begin
          case (num[27:24])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end

        `AN_7: begin
          case (num[31:28])
            // Including cath
            // 4'b1111: cath <= 7'b0001110;
            // 4'b1110: cath <= 7'b0000110;
            // 4'b1101: cath <= 7'b0100001;
            // 4'b1100: cath <= 7'b1000110;
            // 4'b1011: cath <= 7'b0000011;
            // 4'b1010: cath <= 7'b0001000;

            // Including minus
            4'b1111: cath <= 7'b0111111;

            4'b1001: cath <= 7'b0010000;
            4'b1000: cath <= 7'b0000000;
            4'b0111: cath <= 7'b1111000;
            4'b0110: cath <= 7'b0000010;
            4'b0101: cath <= 7'b0010010;
            4'b0100: cath <= 7'b0011001;
            4'b0011: cath <= 7'b0110000;
            4'b0010: cath <= 7'b0100100;
            4'b0001: cath <= 7'b1111001;
            4'b0000: cath <= 7'b1000000;
            default: cath <= 7'b1111111;
          endcase
        end
      endcase
    end else begin
      cath <= 7'b1111111;
    end
  end
endmodule
