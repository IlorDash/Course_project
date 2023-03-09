module kuznechik_cipher_apb_wrapper (

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
    output logic        pslverr_o

);

  ///////////////
  // Registers //
  ///////////////

  logic [ 7:0] control_reg  [3:0];
  logic [31:0] data_in_regs [3:0];
  logic [31:0] data_out_regs[3:0];

  ////////////////////
  // Design package //
  ////////////////////

  import kuznechik_cipher_apb_wrapper_pkg::*;

  //////////////////////////
  // Cipher instantiation //
  //////////////////////////

  logic cipher_resetn;
  assign cipher_resetn = presetn_i && control_reg[RST];

  logic [127:0] cipher_data_in;
  assign cipher_data_in = {data_in_regs[3], data_in_regs[2], data_in_regs[1], data_in_regs[0]};

  logic [127:0] cipher_data_out;

  always_ff @(posedge cipher_valid) begin
    data_out_regs[0] <= cipher_data_out[31:0];
    data_out_regs[1] <= cipher_data_out[63:32];
    data_out_regs[2] <= cipher_data_out[95:64];
    data_out_regs[3] <= cipher_data_out[127:96];
  end

  logic cipher_busy;
  logic cipher_valid;

  // Instantiation
  kuznechik_cipher cipher (
      .clk_i    (pclk_i),
      .resetn_i (cipher_resetn),
      .request_i(control_reg[REQ_ACK][0] && ~control_reg[VALID][0]),
      .ack_i    (control_reg[REQ_ACK][0]),
      .data_i   (cipher_data_in),
      .busy_o   (cipher_busy),
      .valid_o  (cipher_valid),
      .data_o   (cipher_data_out)
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
  //always_ff @(posedge pclk_i) begin
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


    if ((paddr_i < CONTROL) || (paddr_i > DATA_OUT_3)) begin  // Register at the address doesn't exist
      pslverr_o <= 1;
      pslverr_status <= ADDRES;
    end else if (pwrite_i) begin  // Write in read-only register
      if (paddr_i == CONTROL) begin
        if (pstrb_i[VALID]) begin
          pslverr_o <= 1;
          pslverr_status <= READ_ONLY;
        end
        if (pstrb_i[BUSY]) begin
          pslverr_o <= 1;
          pslverr_status <= READ_ONLY;
        end
      end

      if ((paddr_i >= DATA_OUT_0) && (paddr_i <= DATA_OUT_3)) begin
        pslverr_o <= 1;
        pslverr_status <= READ_ONLY;
      end
    end

    if (pwrite_i && (paddr_i == CONTROL) && pstrb_i[REQ_ACK] && control_reg[BUSY]) begin  // Don't receive request while cipher busy
      pslverr_o <= 1;
      pslverr_status <= REQUEST;
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
        CONTROL: begin
          prdata_o[7:0]   <= control_reg[0];
          prdata_o[15:8]  <= control_reg[1];
          prdata_o[23:16] <= control_reg[2];
          prdata_o[31:24] <= control_reg[3];
        end
        DATA_IN_0: begin
          prdata_o <= data_in_regs[0];
        end

        DATA_IN_1: begin
          prdata_o <= data_in_regs[1];
        end

        DATA_IN_2: begin
          prdata_o <= data_in_regs[2];
        end

        DATA_IN_3: begin
          prdata_o <= data_in_regs[3];
        end

        DATA_OUT_0: begin
          prdata_o <= data_out_regs[0];
        end

        DATA_OUT_1: begin
          prdata_o <= data_out_regs[1];
        end

        DATA_OUT_2: begin
          prdata_o <= data_out_regs[2];
        end

        DATA_OUT_3: begin
          prdata_o <= data_out_regs[3];
        end
        default: begin
          prdata_o <= 0;
        end
      endcase
    end
  end

  always_ff @(posedge pclk_i) begin
    if (penable_i && pwrite_i && (paddr_i == CONTROL) && pstrb_i[REQ_ACK]) begin
      control_reg[REQ_ACK] <= pwdata_i[REQ_ACK];
    end else begin
      control_reg[REQ_ACK] <= 0;
    end
  end

  // WRITE REGS
  always_ff @(posedge penable_i) begin
    if (penable_i && pwrite_i) begin

      if ((paddr_i == CONTROL) && pstrb_i[RST]) begin
        control_reg[RST] <= pwdata_i[RST];
      end
      
      if (paddr_i == DATA_IN_0) begin
        data_in_regs[0][7:0]   <= pwdata_i[0];
        data_in_regs[0][15:8]  <= pwdata_i[1];
        data_in_regs[0][23:16] <= pwdata_i[2];
        data_in_regs[0][31:24] <= pwdata_i[3];
      end else if (paddr_i == DATA_IN_1) begin
        data_in_regs[1][7:0]   <= pwdata_i[0];
        data_in_regs[1][15:8]  <= pwdata_i[1];
        data_in_regs[1][23:16] <= pwdata_i[2];
        data_in_regs[1][31:24] <= pwdata_i[3];
      end else if (paddr_i == DATA_IN_2) begin
        data_in_regs[2][7:0]   <= pwdata_i[0];
        data_in_regs[2][15:8]  <= pwdata_i[1];
        data_in_regs[2][23:16] <= pwdata_i[2];
        data_in_regs[2][31:24] <= pwdata_i[3];
      end else if (paddr_i == DATA_IN_3) begin
        data_in_regs[3][7:0]   <= pwdata_i[0];
        data_in_regs[3][15:8]  <= pwdata_i[1];
        data_in_regs[3][23:16] <= pwdata_i[2];
        data_in_regs[3][31:24] <= pwdata_i[3];
      end
    end
  end

  always_ff @(posedge pclk_i) begin
    if (cipher_valid) begin
      control_reg[VALID] <= 1;
    end else if (control_reg[REQ_ACK]) begin
      control_reg[VALID] <= 0;
    end
  end

  assign control_reg[BUSY] = cipher_busy;

endmodule
