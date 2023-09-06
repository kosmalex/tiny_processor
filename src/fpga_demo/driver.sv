/**
  This is the driver module; It loads the instruction and register file (dmem)
  of the tiny processor module and enables it to begin execution.
*/
module driver (
  input logic clk, rst,

  input logic drive,

  input  logic done_in,

  output logic mosi_out,

  output logic done_out,

  output logic[1:0] mode_out
);

logic[7:0] imem[32];
logic[7:0] dmem[16];

int offset;

initial $readmemh("./test.mem ", imem);
initial $readmemh("./testd.mem", dmem);
// initial $readmemh("./anim0.mem ", imem);
// initial $readmemh("./anim0d.mem", dmem);
// initial $readmemh("./add.mem ", imem);
// initial $readmemh("./addd.mem", dmem);
// initial $readmemh("./shift.mem ", imem);
// initial $readmemh("./shiftd.mem", dmem);
// initial $readmemh("./popc.mem ", imem);
// initial $readmemh("./popcd.mem", dmem);
// initial $readmemh("./spi.mem ", imem);
// initial $readmemh("./spid.mem", dmem);

////////////////////////////////////////////////////////////
// Modification beyond this point should not be necessary //
////////////////////////////////////////////////////////////
logic[12:0] data;
logic[7:0]  src;

logic      bits_sent_en;
logic[3:0] bits_sent;
always_ff @(negedge clk) begin
  if (rst | (bits_sent == 4'd12)) begin
    bits_sent <= 0;
  end else if (bits_sent_en) begin
    bits_sent <= bits_sent + 1;
  end
end

logic      bytes_sent_en;
logic      bytes_sent_rst;
logic[3:0] bytes_sent;
always_ff @(posedge clk) begin
  if ( rst | bytes_sent_rst ) begin
    bytes_sent <= 0;
  end else if (bytes_sent_en) begin
    bytes_sent <= bytes_sent + 1;
  end
end

logic inc_off;
always @(posedge clk) begin
  if (rst) begin
    offset <= 0;
  end else if (inc_off) begin
    offset <= offset + 16;
  end 
end

// FSMD //
typedef enum logic[3:0] { IDLE, SENDi[3], DONEi, SENDd[3], DONEd, STALL, FIN } state_t;
state_t st;
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end else begin
    case (st)
      IDLE: begin
        st <= drive ? SENDi0 : IDLE;
      end

      SENDi0: st <= SENDi1;
      SENDi1: st <= SENDi2;

      SENDi2: begin
        st <= (bits_sent == 4'd12) ? DONEi : SENDi2;
      end

      DONEi: begin
        st <= (bytes_sent == 4'd15) ? SENDd0 : SENDi0;
      end
    
      SENDd0: begin 
        st <= (offset >= 32) ? FIN : SENDd1;
      end

      SENDd1: st <= SENDd2;

      SENDd2: begin
        st <= (bits_sent == 4'd12) ? DONEd : SENDd2;
      end

      DONEd: begin
        st <= (bytes_sent == 4'd15) ? STALL : SENDd0;
      end

      STALL: begin
        st <= FIN;
      end

      FIN: begin
        if (done_in) begin
          if (offset < 32) begin
            st <= SENDi0;
          end else begin
            st <= ~drive ? IDLE : FIN;
          end
        end
      end

      default: st <= IDLE;
    endcase
  end
end

assign inc_off = (st == DONEi) && (bytes_sent == 4'd15);

assign bits_sent_en  = ( st == SENDi2 ) || ( st == SENDd2);
assign bytes_sent_en = ( st == DONEi  ) || ( st == DONEd);

assign bytes_sent_rst = ( &bytes_sent & (st == FIN) );

assign src = ( st == SENDi2 ) ? imem[offset + bytes_sent] : dmem[bytes_sent];

assign data = {1'b0, src, bytes_sent};
assign mosi_out = data[bits_sent];

always_comb begin
  case (st)
    IDLE : mode_out = 2'b00;
    SENDi0: mode_out = 2'b01;
    SENDi1: mode_out = 2'b01;
    SENDi2: mode_out = (bits_sent == 4'd12) ? 2'b00 : 2'b01;
    DONEi: mode_out = 2'b00;
    SENDd0: mode_out = 2'b10;
    SENDd1: mode_out = 2'b10;
    SENDd2: mode_out = (bits_sent == 4'd12) ? 2'b00 : 2'b10;
    DONEd: mode_out = 2'b00;
    STALL: mode_out = 2'b11;
    FIN  : mode_out = done_in ? 2'b00 : 2'b11;
    
    default: mode_out = 2'b00; 
  endcase
end

assign done_out = (st == FIN) && (offset >= 32);

endmodule