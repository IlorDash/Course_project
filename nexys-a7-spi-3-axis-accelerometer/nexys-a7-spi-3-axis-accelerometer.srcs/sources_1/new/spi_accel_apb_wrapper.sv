`timescale 1ns / 1ps

//////////////////////////////////
// SPI Accelerometer memory map //
//////////////////////////////////

// 0x00 - Data X register
// 0x04 - Data Y register
// 0x08 - Data Z register
// 0x0C - Data ready register

`define DATA_X 32'h0000
`define DATA_Y 32'h0004
`define DATA_Z 32'h0008
`define DATA_READY 32'h000C

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

  logic [15:0] data_X;
  logic [15:0] data_Y;
  logic [15:0] data_Z;
  logic [31:0] data_ready_reg;
  logic data_ready_wire;

  /////////////////////////////////////
  // SPI Accelerometer instantiation //
  /////////////////////////////////////

  accel_spi_master master (
      .iclk(pclk_i),
      .miso(ACL_MISO),
      .sclk(ACL_SCLK),
      .mosi(ACL_MOSI),
      .cs(ACL_CSN),
      .X(data_X),
      .Y(data_Y),
      .Z(data_Z),
      .acl_data_ready(data_ready_wire)
  );

  // Data Ready Reg
  always_ff @(posedge data_ready_wire, posedge read_data_ready) begin
    if (data_ready_wire) begin
      data_ready_reg <= {32{data_ready_wire}};
    end else if (read_data_ready) begin
      data_ready_reg <= 32'h0000;
    end
  end

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

    if (paddr_i > `DATA_READY) begin  // Register at the address doesn't exist
      pslverr_o <= 1;
      pslverr_status <= ADDRES;
    end

    if (paddr_i[1:0]) begin  // Misaligned address
      pslverr_o <= 1;
      pslverr_status <= MISALIGN;
    end
  end

  logic read_data_ready;

  // READ REGS
  always_ff @(posedge penable_i) begin
    if (~pwrite_i) begin
      case (paddr_i)
        `DATA_X: begin
          prdata_o <= {{16'b0}, data_X};
          read_data_ready <= 0;
        end
        `DATA_Y: begin
          prdata_o <= {{16'b0}, data_Y};
          read_data_ready <= 0;
        end
        `DATA_Z: begin
          prdata_o <= {{16'b0}, data_Z};
          read_data_ready <= 0;
        end
        `DATA_READY: begin
          prdata_o <= data_ready_reg;
          read_data_ready <= 1;
        end
        default: begin
          prdata_o <= 0;
          read_data_ready <= 0;
        end
      endcase
    end
  end

endmodule

