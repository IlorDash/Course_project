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
  assign data_out_regs[0] = cipher_data_out[127:96];
  assign data_out_regs[1] = cipher_data_out[95:64];
  assign data_out_regs[2] = cipher_data_out[63:32];
  assign data_out_regs[3] = cipher_data_out[31:0];

  logic cipher_busy;
  logic cipher_valid;

  // Instantiation
  kuznechik_cipher cipher (
      .clk_i    (pclk_i),
      .resetn_i (cipher_resetn),
      .request_i(control_reg[REQ_ACK][0]),
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

  logic [1:0] data_tx_cycle;  // count words transfering with data registers
  always_ff @(posedge pclk_i, posedge presetn_i) begin
    if (presetn_i || !pready_o) begin
      data_tx_cycle <= 0;
    end else if (pready_o && (paddr_i != CONTROL)) begin
      data_tx_cycle <= data_tx_cycle + 1;
    end
  end

  always_ff @(posedge pclk_i) begin
    control_reg[BUSY]  = {8{cipher_busy}};
    control_reg[VALID] = {8{cipher_valid}};
  end

  always_ff @(posedge pclk_i) begin
    pslverr_o <= 0;
    case (paddr_i)
      CONTROL: begin

        if (pstrb_i[RST]) begin
          if (pwrite_i) begin
            control_reg[RST] <= pwdata_i[RST];
          end else begin
            prdata_o[(8*(RST+1))-1:8*(RST)] <= control_reg[RST];
          end
        end

        if (pstrb_i[REQ_ACK]) begin
          if (pwrite_i) begin
            control_reg[REQ_ACK] <= pwdata_i[REQ_ACK];
          end else begin
            prdata_o[(8*(REQ_ACK+1))-1:8*(REQ_ACK)] <= control_reg[REQ_ACK];
          end
        end

        if (pstrb_i[VALID]) begin
          if (pwrite_i) begin
            pslverr_o <= 1;
          end else begin
            prdata_o[(8*(VALID+1))-1:8*(VALID)] <= control_reg[VALID];
          end
        end

        if (pstrb_i[BUSY]) begin
          if (pwrite_i) begin
            pslverr_o <= 1;
          end else begin
            prdata_o[(8*(BUSY+1))-1:8*(BUSY)] <= control_reg[BUSY];
          end
        end
      end
      DATA_IN: begin
        if (pwrite_i) begin
          data_in_regs[data_tx_cycle][7:0]   <= pwdata_i[0];
          data_in_regs[data_tx_cycle][15:8]  <= pwdata_i[1];
          data_in_regs[data_tx_cycle][23:16] <= pwdata_i[2];
          data_in_regs[data_tx_cycle][31:24] <= pwdata_i[3];
        end else begin
          prdata_o <= data_in_regs[data_tx_cycle];
        end
      end
      DATA_OUT: begin
        if (pwrite_i) begin
          pslverr_o <= 1;
        end else begin
          prdata_o <= data_out_regs[data_tx_cycle];
        end
      end
      default: begin
        pslverr_o <= 0;
        prdata_o  <= 0;
      end
    endcase
  end

endmodule
