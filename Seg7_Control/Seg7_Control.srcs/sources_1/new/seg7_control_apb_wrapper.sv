`timescale 1ns / 1ps

//***********************************
// Address space
//  Using 2 WORDS
//  0x0000 - nums to disp on LEDs
//  0x0004 - controller reset: 0x00-0x07 -> 0x00, 0x08 -> 0xFF, 0x09 -> 0xFF

// Bytes addressing in words
//  _ _ _ _ | _ _ _ _ |
//  0 1 2 3   4 5 6 7  

// Four bits are specifies one digit num, so we need 32 bits for 8 digits 

`define NUM_TO_DISP 32'h0000
`define RESET 32'h0004

/*
 * AN - Anode
 * CATH - Cathode
 */

`define CATH_NUM 7
`define AN_NUM 8

module seg7_apb_wrapper (

    // Clock
    input logic pclk_i,

    // Reset
    input logic presetn_i,

    // Address
    input logic [31:0] paddr_i,

    // Control-status
    input logic psel_i,
    input logic penable_i,
    input logic pwrite_i,

    // Write
    input logic [3:0][7:0] pwdata_i,
    input logic [3:0]      pstrb_i,

    // Slave
    output logic        pready_o,
    output logic [31:0] prdata_o,
    output logic        pslverr_o,

    output logic ca,
    output logic cb,
    output logic cc,
    output logic cd,
    output logic ce,
    output logic cf,
    output logic cg,

    output logic [`AN_NUM-1:0] an
);

  ///////////////
  // Registers //
  ///////////////

  logic [31:0] num_reg;
  logic [31:0] reset_reg;

  /////////////////////////////////////
  // 7-Segment control instantiation //
  /////////////////////////////////////

  logic seg7_resetn;
  assign seg7_resetn = presetn_i && reset_reg[0];

  logic [`CATH_NUM-1:0] cath;
  assign cath = {cg, cf, ce, cd, cc, cb, ca};

  seg7_control my_disp (
      .clk_i(pclk_i),
      .num(num_reg),
      .rst(seg7_resetn),
      .cath(cath),
      .an(an)
  );

  // Control

  always_ff @(posedge pclk_i) begin
    pready_o <= psel_i;
  end

  logic psel_prev;

  typedef enum {
    NONE = 0,
    PENABLE = 1,
    PWRITE = 2,
    PSEL_PREV = 3,
    ADDRES = 4,
    READ_ONLY = 5,
    WRITE_ONLY = 6,
    REQUEST = 7,
    MISALIGN = 8
  } pslverr_causes_t;

  logic [2:0] pslverr_status;

  always_comb begin
    pslverr_o <= 0;
    psel_prev <= psel_i;

    pslverr_status <= NONE;

    // Wrong transaction phase

    if (penable_i && ~psel_i) begin
      pslverr_o <= 1;
      pslverr_status <= PENABLE;
    end
    if (pwrite_i && ~psel_i) begin
      pslverr_o <= 1;
      pslverr_status <= PWRITE;
    end
    if (~psel_prev && penable_i) begin
      pslverr_o <= 1;
      pslverr_status <= PSEL_PREV;
    end

    if (paddr_i > `RESET) begin  // Register at the address doesn't exist
      pslverr_o <= 1;
      pslverr_status <= ADDRES;
    end

    if ((paddr_i <= `RESET) && ~pwrite_i && psel_i) begin  // Read from write-only register
      pslverr_o <= 1;
      pslverr_status <= WRITE_ONLY;
    end

    if (paddr_i[1:0]) begin  // Misaligned address
      pslverr_o <= 1;
      pslverr_status <= MISALIGN;
    end
  end

  // WRITE REGS
  always_ff @(posedge penable_i) begin
    if (penable_i && pwrite_i) begin
      case (paddr_i)
        `NUM_TO_DISP: begin
          num_reg[7:0]   <= pwdata_i[0];
          num_reg[15:8]  <= pwdata_i[1];
          num_reg[23:16] <= pwdata_i[2];
          num_reg[31:24] <= pwdata_i[3];
        end
        `RESET: begin
          reset_reg[7:0]   <= pwdata_i[0];
          reset_reg[15:8]  <= pwdata_i[1];
          reset_reg[23:16] <= pwdata_i[2];
          reset_reg[31:24] <= pwdata_i[3];
        end
        default: begin
          num_reg <= 32'b0;
          reset_reg   <= 32'b0;
        end
      endcase
    end
  end

endmodule
