`include "defs.vh"

module shift_reg #(
  parameter SIZE = 8,
  parameter DATA_W = 8
)(
  input wire clk, rst  ,
  input wire sdata_in  , // Serial data

  input wire en_in     , // Enable write
  input wire en_shft_in, // Enable shift
  input wire mode_in   , // Serial or parallel input

  input  wire[DATA_W-1:0] data_in, // parallel data in
  output wire[SIZE-1:0]   data_out // parallel data out
);

reg[SIZE-1:0] register;

generate
  genvar i;

  for (i = 0; i < SIZE; i = i + 1) begin
    if (i == 0) begin
      always @(posedge clk) begin
        if (rst) begin
          register[SIZE - 1] <= 0;
        end else if (en_shft_in) begin
          register[SIZE - 1] <= mode_in ? data_in[DATA_W - 1] 
                                     : ( en_in ? sdata_in : 1'b0 );
          // register[SIZE - 1] <= ( en_in ? sdata_in : 1'b0 );
        end
      end
    end else begin
      always @(posedge clk) begin
        if (rst) begin
          register[SIZE - i - 1] <= 0;
        end else if (en_shft_in) begin
          register[SIZE - i - 1] <= mode_in ? ( ( i < DATA_W ) ? data_in[DATA_W - i - 1] : 1'b0 )
                                         : register[SIZE - i];
        end
      end
    end
  end
endgenerate

assign data_out = register;
endmodule

module spi_if #(
  parameter DATA_W = `DATAPATH_W,
  parameter ADDR_W = `CLOG2(`DMEM_SZ),
  
  parameter  BUFFER_SIZE   = DATA_W + ADDR_W,
  localparam BUFFER_SIZE_W = `CLOG2(BUFFER_SIZE),

  // FSM states
  localparam IDLE = 0,
  localparam BUSY = 1
)(
  input wire clk, rst,

  // DRIVER EXT //
  input  wire             driverIO_in,
  output wire[ADDR_W-1:0] addr_out,

  // READ //
  input  wire             read_in,
  output wire             ready_out,
  output wire[DATA_W-1:0] data_out,

  // WRITE //
  input wire             send_in,
  input wire[DATA_W-1:0] data_in,

  // To device/es //
  output wire sclk_out,
  input  wire miso_in ,
  output wire mosi_out,
  output wire cs_out
);

reg[BUFFER_SIZE_W-1:0] nbytes;
wire[BUFFER_SIZE-1:0]  buffer;

wire is_idle, is_busy;
wire all_bytes_recvd;

wire sr_en, sr_mode;

reg st;

// FSM
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end else begin
    case (st)
      IDLE: begin
        st <= (send_in | read_in) ? BUSY : IDLE;
      end

      BUSY: begin
        st <= all_bytes_recvd ? IDLE : BUSY;
      end

      default: st <= IDLE;
    endcase
  end
end

// Bytes to receive/send counter
always @(posedge clk) begin
  if (rst | (is_idle & ( read_in | send_in ) ) ) begin
    nbytes <= BUFFER_SIZE;
  end else if (is_busy) begin
    nbytes <= nbytes - 1;
  end
end

shift_reg #(
  .SIZE(BUFFER_SIZE)
) shift_reg_0 (
  .clk (clk),
  .rst (rst),

  .sdata_in   (miso_in),
  .en_in      (sr_en),
  .en_shft_in (sr_en),
  .mode_in    (sr_mode),

  .data_in  (data_in),
  .data_out (buffer)
);

assign data_out = buffer[BUFFER_SIZE-1:ADDR_W];
assign addr_out = buffer[ADDR_W-1:0];

assign 
is_idle = ( st == IDLE );
assign is_busy = ( st == BUSY );

assign all_bytes_recvd = (nbytes == 1'b1); // nbytes == 0

assign ready_out = is_busy & all_bytes_recvd;

assign sclk_out = clk;
assign cs       = ~is_busy; // reversed select

assign sr_en   = (send_in & is_idle) | (read_in & is_busy);
assign sr_mode = send_in;
endmodule