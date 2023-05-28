`timescale 1ns / 1ps

`define BYTE_WIDTH 8

module spi_slave #(
    parameter CPOL = 0,
    parameter CPHA = 0
) (
    input rst_n,
    input [`BYTE_WIDTH-1:0] tx_buff,
    output logic [`BYTE_WIDTH-1:0] rx_buff,

    input tx_data_rdy,
    output logic txe,  // Transmit buffer empty
    output logic rxf,  // Receive buffer full

    input SCK,
    input CS,
    input MOSI,
    output logic MISO
);


  logic [$clog2(`BYTE_WIDTH):0] rx_cntr;
  logic [$clog2(`BYTE_WIDTH):0] tx_cntr;

  always_ff @(negedge rst_n) begin  // if reset - set default values
    if (!rst_n) begin
      MISO <= 1'bz;

      rx_cntr <= 0;
      tx_cntr <= 0;

      rx_buff <= {`BYTE_WIDTH{1'b0}};
    end
  end


  always_ff @(posedge SCK) begin : sample_posedge
    if (rst_n && !CS) begin
      if ((CPOL ^ CPHA) == 0) begin
        if (rx_cntr < (`BYTE_WIDTH - 1)) begin
          rxf <= 1'b0;  // Receive buffer NOT full
          rx_buff[rx_cntr] <= MOSI;
          rx_cntr++;
        end else begin
          rx_buff[rx_cntr] <= MOSI;
          rxf <= 1'b1;  // Receive buffer full
          rx_cntr <= 0;
        end
      end
    end
  end

//   always @(negedge SCK) begin : sample_negedge
//     if (rst_n && !CS) begin
//       if ((CPOL ^ CPHA) == 1) begin
//         if (rx_cntr < (`BYTE_WIDTH - 1)) begin
//           rxf <= 1'b0;  // Receive buffer NOT full
//           rx_buff[rx_cntr] <= MOSI;
//           rx_cntr <= rx_cntr + 1;
//         end else begin
//           rx_buff[rx_cntr] <= MOSI;
//           rxf <= 1'b1;  // Receive buffer full
//           rx_cntr <= 0;
//         end
//       end
//     end
//   end

  //assign MISO = (rst_n && !CS && tx_data_rdy) ? 1'bZ : tx_buff[tx_cntr];

  always_ff @(negedge SCK) begin : set_negedge
    if (rst_n && !CS && tx_data_rdy) begin
      if ((CPOL ^ CPHA) == 0) begin
        if (tx_cntr < (`BYTE_WIDTH - 1)) begin
          txe <= 1'b0;  // Transmit buffer NOT empty
          MISO <= tx_buff[tx_cntr];
          tx_cntr <= tx_cntr + 1;
        end else begin
          txe <= 1'b1;  // Transmit buffer empty
          MISO <= tx_buff[tx_cntr];
          tx_cntr <= 0;
        end
      end
    end
  end

//   always_ff @(posedge SCK) begin : set_posedge
//     if (rst_n && !CS && tx_data_rdy) begin
//       if ((CPOL ^ CPHA) == 1) begin
//         if (tx_cntr < (`BYTE_WIDTH - 1)) begin
//           txe <= 1'b0;  // Transmit buffer NOT empty
//           MISO <= tx_buff[tx_cntr];
//           tx_cntr <= tx_cntr + 1;
//         end else begin
//           txe <= 1'b1;  // Transmit buffer empty
//           MISO <= tx_buff[tx_cntr];
//           tx_cntr <= 0;
//         end
//       end
//     end
//   end

endmodule
