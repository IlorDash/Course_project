`timescale 1ns / 1ps

//////////////////////////////////
// SPI Accelerometer memory map //
//////////////////////////////////

// 0x00 - Data out register

`define DATA_OUT 32'h0000

module spi_accel_apb_wrapper (

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

    input  logic ACL_MISO,  // master in
    output logic ACL_MOSI,  // master out
    output logic ACL_SCLK,  // spi sclk
    output logic ACL_CSN    // spi ~chip select

);

  ///////////////
  // Registers //
  ///////////////

  logic [31:0] data_out_reg;

  /////////////////////////////////////
  // SPI Accelerometer instantiation //
  /////////////////////////////////////

  accel_spi_master master (
      .iclk(pclk_i),
      .miso(ACL_MISO),
      .sclk(ACL_SCLK),
      .mosi(ACL_MOSI),
      .cs(ACL_CSN),
      .acl_data(data_out_reg)
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
    REQUEST = 6,
    MISALIGN = 7
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

    if (paddr_i > `DATA_OUT) begin  // Register at the address doesn't exist
      pslverr_o <= 1;
      pslverr_status <= ADDRES;
    end

    if (paddr_i[1:0]) begin  // Misaligned address
      pslverr_o <= 1;
      pslverr_status <= MISALIGN;
    end
  end

  // READ REGS
  always_ff @(posedge penable_i) begin
    if (~pwrite_i) begin
      case (paddr_i)
        32'h0000: begin
          prdata_o <= data_out_reg;
        end
        default: begin
          prdata_o <= 0;
        end
      endcase
    end
  end

endmodule

