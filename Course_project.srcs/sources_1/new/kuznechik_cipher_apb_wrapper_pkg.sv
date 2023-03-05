package kuznechik_cipher_apb_wrapper_pkg;

  ///////////////////////
  // Cipher memory map //
  ///////////////////////

  // 0x00 – 0x04 - Control register
  //    0x00 - RST
  //    0x01 - {REQ, ACK}
  //    0x02 - VALID
  //    0x03 - BUSY

  // 0x04 - 0x13 - data_in
  // 0x04 - 0x13 - data_out

  typedef enum {
    CONTROL  = 32'h0000,
    DATA_IN  = 32'h0004,
    DATA_OUT = 32'h0014
  } cipher_apb_addr_t;

  typedef enum {
    RST     = 0,
    REQ_ACK = 1,
    VALID   = 2,
    BUSY    = 3
  } cipher_control_t;

endpackage