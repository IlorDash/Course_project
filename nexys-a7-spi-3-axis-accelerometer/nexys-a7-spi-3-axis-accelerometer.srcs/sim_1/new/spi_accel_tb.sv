`timescale 1ns / 1ps

module spi_accel_tb ();

  logic clk;
  logic sclk;
  logic mosi;
  logic cs;
  logic [15:0] data;
  logic data_ready;

  accel_spi_master master (
      .iclk(clk),
      .miso(),
      .sclk(sclk),
      .mosi(mosi),
      .cs(cs),
      .acl_data(data),
      .acl_data_ready(data_ready)
  );

  always begin
    #1;
    clk = ~clk;
  end

  initial begin
    clk = 0;
    #2000000;
    $finish;
  end

endmodule
