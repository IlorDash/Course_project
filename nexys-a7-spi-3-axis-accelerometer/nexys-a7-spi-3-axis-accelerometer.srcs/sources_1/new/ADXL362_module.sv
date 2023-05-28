`timescale 1ns / 1ps

`define SPI_MODE_0 0,0
`define BYTE_WIDTH 8
`define REG_CNT 6
`define ADDR_LEN 7

module ADXL362_module (
    input SCK,
    input CS,
    input MOSI,
    output logic MISO
);

  logic [`BYTE_WIDTH-1:0] REGS[0:`REG_CNT-1];


  // Init FLASH with random nums
  initial begin
    int data;
    parameter DATA_BITS_NUM = $bits(data);
    for (int reg_num = 0; reg_num < `REG_CNT; reg_num++) begin
      data = $urandom();  //returns 32 bit random
      REGS[reg_num] = data[`BYTE_WIDTH-1:0];
    end
  end

  logic [`BYTE_WIDTH-1:0] data_out;
  logic [`BYTE_WIDTH-1:0] data_in;

  logic rst_n;
  logic tx_data_rdy;
  logic txe;
  logic rxf;

  assign rst_n = ~CS;

  spi_slave spi (

      .rst_n(rst_n),

      .tx_buff(data_out),
      .rx_buff(data_in),

      .tx_data_rdy(tx_data_rdy),
      .txe(txe),  // Transmit buffer empty
      .rxf(rxf),  // Receive buffer full

      .SCK (SCK),
      .CS  (CS),
      .MOSI(MOSI),
      .MISO(MISO)
  );

  logic [`BYTE_WIDTH-1:0] data_in_reversed;  // Receive data in LSB, convert to MSB

  assign data_in_reversed = {
    data_in[0], data_in[1], data_in[2], data_in[3], data_in[4], data_in[5], data_in[6], data_in[7]
  };

  logic [7:0] x_LSB_addr = 8'h0E;

  logic send_data;
  logic [2:0] data_cntr;

  always_ff @(posedge CS, posedge rxf) begin  // received data handler
    if (!CS) begin
      if (rxf) begin  // received data handler
        if (data_in_reversed == x_LSB_addr) begin  // command READ
          send_data <= 1;
        end
      end
    end else begin
      send_data   <= 1'b0;
      tx_data_rdy <= 1'b0;
      data_cntr   <= 3'b0;
    end
  end

  always_ff @(posedge send_data, posedge txe) begin  // transmit data handler
    if (data_cntr < 6) begin
      if (send_data) begin
        data_out <= REGS[data_cntr];
        data_cntr <= data_cntr + 1;
        tx_data_rdy <= 1'b1;
      end
    end else begin
      data_cntr   <= 3'b0;
      tx_data_rdy <= 1'b0;
    end
  end
endmodule
