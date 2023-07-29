module element(
  input wire A, B, sel, //select between and(A, B) and nand(A, B)
  input wire Sin, Cin,
  
  output wire Sout, Cout
);

wire op_AB = sel ? ~(A & B) : A & B;

assign Sout = Sin ^ op_AB ^ Cin;
assign Cout = (Sin ^ op_AB) ? Cin : Sin;

endmodule

module mul #(
  parameter N_BIT = 4,
  
  parameter RES_SIZE = N_BIT << 1 
)(
  input wire[N_BIT-1:0] A, B,
  input wire            mul_type,
  
  output wire[RES_SIZE-1:0] product
);

wire[N_BIT-1:0] Ci[0:N_BIT-1];
wire[N_BIT-1:0] Si[0:N_BIT-1];

wire S_ini[2:0], Sel_ini[2:0];
//row 0
assign S_ini[0]   = 1'b0;
assign Sel_ini[0] = mul_type ? 1'b1 : 1'b0;
  
//row 1
assign S_ini[1] = mul_type ? 1'b1 : 1'b0;
  
//row N_BIT-1
assign Sel_ini[2] = 1'b0;
assign Sel_ini[1] = ~mul_type ? 1'b0 : 1'b1;
  
//row N_BIT (the FA row)
assign S_ini[2] = ~mul_type ? 1'b0 : 1'b1;

generate
  genvar row;
  genvar col;
  for(row = 0; row < N_BIT; row = row + 1) begin
    for(col = 0; col < N_BIT; col = col + 1) begin
      element element_0(
      .A(A[row]),
      .B(B[col]),
      .Sin(
        ((row==0) && (col==N_BIT-1)) ? S_ini[0] : 
        ((row==1) && (col==N_BIT-1)) ? S_ini[1] : 
        ((row==0) || (col==N_BIT-1)) ? 1'b0 : Si[row-1][col+1]
        ),
      .Cin((row==0) ? 1'b0 : Ci[row-1][col]),
      .sel(
        ((row==N_BIT-1) && row>col) ? Sel_ini[1] : 
        ((col==N_BIT-1) && col>row) ? Sel_ini[0] : 
        ((col==N_BIT-1) && (row==N_BIT-1)) ? Sel_ini[2] : 1'b0
        ),
      
      .Sout(Si[row][col]),
      .Cout(Ci[row][col])
      );
    end //for
  end //for
endgenerate

wire[N_BIT-1:0] Cj;
generate
  genvar i;

  for(i = 0; i < N_BIT; i = i + 1) begin
    assign product[i] = Si[i];
    
    element element_1(
      .A(Ci[N_BIT-1][i]),
      .B(Ci[N_BIT-1][i]),
      .Cin((i==0) ? 1'b0 : Cj[i-1]),
      .Sin((i==N_BIT-1) ? S_ini[2] : Si[N_BIT-1][i+1]),
      .sel(1'b0),
      
      .Sout(product[i + (RES_SIZE >> 1)]),
      .Cout(Cj[i])
    );
  end
endgenerate

endmodule