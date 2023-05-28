`timescale 1ns / 1ps

`define DATA_X 32'h0000
`define DATA_Y 32'h0004
`define DATA_Z 32'h0008
`define DATA_READY 32'h000C

typedef enum {VALID_R_TEST = 0} tests_names_t;

module spi_accel_apb_tb ();

  // Clock period
  parameter real CLK_PERIOD = 10;  // 100 MHz

  // Test timeout (clock periods)
  parameter TEST_TIMEOUT = 10000000;


  ////////////////////
  // Design signals //
  ////////////////////

  logic             pclk_i;
  logic             presetn_i;
  logic [31:0]      paddr_i;
  logic             psel_i;
  logic             penable_i;
  logic             pwrite_i;
  logic [ 3:0][7:0] pwdata_i;
  logic [ 3:0]      pstrb_i;
  logic             pready_o;
  logic [31:0]      prdata_o;
  logic             pslverr_o;

  logic             ACL_MISO;  // master in
  logic             ACL_MOSI;  // master out
  logic             ACL_SCLK;  // spi sclk
  logic             ACL_CSN;  // spi ~chip select

  ADXL362_module accelerometer (
      .SCK (ACL_SCLK),
      .CS  (ACL_CSN),
      .MOSI(ACL_MOSI),
      .MISO(ACL_MISO)
  );


  /////////
  // DUT //
  /////////

  spi_accel_apb_wrapper DUT (
      .pclk_i   (pclk_i),
      .presetn_i(presetn_i),
      .paddr_i  (paddr_i),
      .psel_i   (psel_i),
      .penable_i(penable_i),
      .pwrite_i (pwrite_i),
      .pwdata_i (pwdata_i),
      .pstrb_i  (pstrb_i),
      .pready_o (pready_o),
      .prdata_o (prdata_o),
      .pslverr_o(pslverr_o),
      .ACL_MISO(ACL_MISO),  // master in
      .ACL_MOSI(ACL_MOSI),  // master out
      .ACL_SCLK(ACL_SCLK),  // spi sclk
      .ACL_CSN (ACL_CSN )   // spi ~chip select
  );

  // Clock
  initial begin
    pclk_i = 1'b0;
    forever begin
      #(CLK_PERIOD / 2) pclk_i = ~pclk_i;
    end
  end

  // Checkers

  function void check_pslverr(input bit pslverr, input bit level);
    if (pslverr != level) begin
      $error("PSLVERR = %0b detected but not expected", pslverr);
      $stop();
    end
  endfunction

  task automatic exec_apb_read_trans(input bit [31:0] paddr, output bit [31:0] prdata,
                                     input bit pslverr);
    // Setup phase
    paddr_i  <= paddr;
    psel_i   <= 1'b1;
    pwrite_i <= 1'b0;
    // Access phase
    @(posedge pclk_i);
    penable_i <= 1'b1;
    do begin
      @(posedge pclk_i);
    end while (!pready_o);
    // Check error
    check_pslverr(pslverr_o, pslverr);
    // Save data
    prdata = prdata_o;
    // Unset penable
    penable_i <= 1'b0;
  endtask

  task get_cipher_data_out(output bit [31:0] data[3:0], input bit pslverr);
    for (int i = 0; i < 4; i = i + 1) begin
      exec_apb_read_trans(`DATA_X + 4 * i, data[i], pslverr);
    end

  endtask

  // Tests

  task data_reg_valid_read_test(int iterations = 10);
    bit [31:0] data_out[3:0];
    $display("\nStarting valid read (%0d iterations)", iterations);
    for (int i = 0; i < iterations; i = i + 1) begin
      $display("Iteration %0d", i);
      get_cipher_data_out(data_out, 1'b0);
      if (data_out[0] == 0) begin
        $error("DATA_X is ZERO: %h", data_out[0]);
        $stop();
      end
      if (data_out[1] == 0) begin
        $error("DATA_Y is ZERO: %h", data_out[1]);
        $stop();
      end
      if (data_out[2] == 0) begin
        $error("DATA_Z is ZERO: %h", data_out[2]);
        $stop();
      end
      if (data_out[3] == 0) begin
        $error("DATA_READY is ZERO: %h", data_out[3]);
        $stop();
      end
      #402600;  // wait to SPI transaction end
    end
  endtask

  logic curr_test;

  initial begin
    fork
      begin
        curr_test = VALID_R_TEST;
        #1843595;  // wait to init and SPI transaction end
        data_reg_valid_read_test(100);
        $display("\nAll tests done");
      end
      begin
        repeat (TEST_TIMEOUT) @(posedge pclk_i);
        $error("\nTest was failed: timeout");
      end
    join_any
    $finish();
  end

endmodule
