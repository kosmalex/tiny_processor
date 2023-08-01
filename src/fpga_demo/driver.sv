module driver (
  input logic clk, rst,

  input logic drive,

  input  logic done_in,

  output logic sclk_out,
  output logic rst_n_out,
  output logic mosi_out,

  output logic[1:0] mode_out
);


logic[7:0] mem[16];
initial $readmemh("../../compiler/fact.mem", mem);

logic[12:0] data;

logic eff_clk;
always @(posedge clk) begin
  if (rst) begin
    eff_clk <= 0;
  end else if (clk) begin
    eff_clk <= ~eff_clk;
  end
end

assign sclk_out  = eff_clk;
assign rst_n_out = ~rst;

logic      bits_sent_en;
logic[3:0] bits_sent;
always_ff @(posedge clk) begin
  if (rst | (bits_sent == 4'd12)) begin
    bits_sent <= 0;
  end else if (bits_sent_en & eff_clk) begin
    bits_sent <= bits_sent + 1;
  end
end

logic      bytes_sent_en;
logic      bytes_sent_rst;
logic[3:0] bytes_sent;
always_ff @(posedge clk) begin
  if (rst | bytes_sent_rst ) begin
    bytes_sent <= 0;
  end else if (bytes_sent_en & eff_clk) begin
    bytes_sent <= bytes_sent + 1;
  end
end

// FSMD //
typedef enum logic[2:0] { IDLE, SEND, DONE, STALL, FIN } state_t;
state_t st;
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end else begin
    case (st)
      IDLE: begin
        st <= drive ? SEND : IDLE;
      end

      SEND: begin
        st <= (bits_sent == 4'd12) ? DONE : SEND;
      end

      DONE: begin
        st <= ( (bytes_sent == 4'd15) & done_in ) ? STALL : SEND;
      end

      STALL: begin
        st <= FIN;
      end

      FIN: begin
        st <= ~drive ? IDLE : FIN;
      end

      default: st <= IDLE;
    endcase
  end
end

assign bits_sent_en  = (st == SEND);
assign bytes_sent_en = (st == DONE);

assign bytes_sent_rst = (&bytes_sent & (st == FIN));

assign data = {1'b0, mem[bytes_sent], bytes_sent};
assign mosi_out = data[bits_sent];

always_comb begin
  case (st)
    IDLE : mode_out = 2'b00;
    SEND : mode_out = (bits_sent == 4'd12) ? 2'b00 : 2'b01;
    DONE : mode_out = 2'b00;
    STALL: mode_out = 2'b11;
    FIN  : mode_out = done_in ? 2'b00 : 2'b11;
    
    default: mode_out = 2'b00; 
  endcase
end

endmodule