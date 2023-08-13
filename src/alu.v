module cs_add(
  input wire x, y, z,

  output wire s, c
);
wire sel;

assign sel = x ^ y;
assign s   = sel ^ z;
assign c   = sel ? z : x;

endmodule

module adder_8bit(
  input wire[7:0] A_in, B_in,
  input wire      C_in,

  output wire[7:0] S_out
);

wire[8:0] C;
assign C[0] = C_in;

generate
  genvar i;

  for (i = 0; i < 8; i = i + 1) begin : carry_propagate_adder
    cs_add cs_add_0(
      .x(A_in[i]), .y(B_in[i]), .z(C[i]),
      
      .s(S_out[i]), .c(C[i+1])
    );
  end
endgenerate

endmodule

module barrel_shift (
  input wire[7:0] value_in,
  input wire[2:0] amnt_in,
  input wire      rshift_in,

  output wire[7:0] res_out
);

wire[7:0] lvl[0:3];
generate
  genvar j;
  
  // Reverse bits
  for (j = 0; j < 8; j = j + 1) begin
    assign lvl[0][j] = rshift_in ? value_in[7 - j] : value_in[j];
  end

  // First level shift
  assign lvl[1][0] = amnt_in[0] ? 1'b0 : lvl[0][0];
  for (j = 1; j < 8; j = j + 1) begin
    assign lvl[1][j] = amnt_in[0] ? lvl[0][j-1] : lvl[0][j];
  end
  
  // Second level shift
  assign lvl[2][0] = amnt_in[1] ? 1'b0 : lvl[1][0];
  assign lvl[2][1] = amnt_in[1] ? 1'b0 : lvl[1][1];
  for (j = 2; j < 8; j = j + 1) begin
    assign lvl[2][j] = amnt_in[1] ? lvl[1][j-2] : lvl[1][j];
  end

  // Third level shift
  assign lvl[3][0] = amnt_in[2] ? 1'b0 : lvl[2][0];
  assign lvl[3][1] = amnt_in[2] ? 1'b0 : lvl[2][1];
  assign lvl[3][2] = amnt_in[2] ? 1'b0 : lvl[2][2];
  assign lvl[3][3] = amnt_in[2] ? 1'b0 : lvl[2][3];
  for (j = 4; j < 8; j = j + 1) begin
    assign lvl[3][j] = amnt_in[2] ? lvl[2][j-4] : lvl[2][j];
  end

  // Reverse bits again
  for (j = 0; j < 8; j = j + 1) begin
    assign res_out[j] = rshift_in ? lvl[3][7 - j] : lvl[3][j];
  end
endgenerate
endmodule

module alu (
  input wire[2:0] unit_sel_in,
  input wire      op_sel_in,
  input wire      mul_seg_sel,

  input wire[7:0] acc_in, src_in,
  
  output wire[7:0] alu_res_out
);

// Addition-Subtraction //
wire[7:0] add_res;
adder_8bit adder_8bit_0 (
  .A_in (acc_in),
  // .B_in (op_sel_in ? ~src_in : src_in),
  .B_in (src_in),
  .C_in (1'b0  ),
  
  .S_out (add_res)
);

// SHIFTER //
wire[7:0] shift_res;
barrel_shift barrel_shift_0 (
  .value_in  (acc_in),
  .amnt_in   (src_in[2:0]),
  .rshift_in (op_sel_in),

  .res_out   (shift_res)
);

reg[7:0] alu_res;
always @(*) begin
  case (unit_sel_in)
    3'b000: alu_res = add_res;
    3'b001: alu_res = src_in;           // SPI
    3'b010: alu_res = shift_res;
    3'b011: alu_res = src_in;
    
    3'b100: alu_res = acc_in | src_in;
    3'b101: alu_res = acc_in ^ src_in;
    3'b110: alu_res = acc_in & src_in;
    3'b111: alu_res = acc_in;           // BNEZ
    
    default: alu_res = acc_in;
  endcase
end

assign alu_res_out = alu_res;

endmodule