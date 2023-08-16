/*
      -- 1 --
     |       |
     6       2
     |       |
      -- 7 --
     |       |
     5       3
     |       |
      -- 4 --
*/

module seven_seg (
  input wire[4:0] value_in,
  input wire[7:0] bit_array_in,
  input wire      anim_en_in,
  
  output wire[7:0] out
);

reg[7:0] result;
always @(*) begin
  if (~anim_en_in) begin
    case(value_in[3:0])
      //                    7654321
      0 :  result[6:0] = 7'b0111111;
      1 :  result[6:0] = 7'b0000110;
      2 :  result[6:0] = 7'b1011011;
      3 :  result[6:0] = 7'b1001111;
      4 :  result[6:0] = 7'b1100110;
      5 :  result[6:0] = 7'b1101101;
      6 :  result[6:0] = 7'b1111100;
      7 :  result[6:0] = 7'b0000111;
      8 :  result[6:0] = 7'b1111111;
      9 :  result[6:0] = 7'b1100111;

      //                 7654321
      10:  result[6:0] = 7'b1110111;
      11:  result[6:0] = 7'b1111100;
      12:  result[6:0] = 7'b0111001;
      13:  result[6:0] = 7'b1011110;
      14:  result[6:0] = 7'b1111001;
      15:  result[6:0] = 7'b1110001;

      default:    
        result[6:0] = 7'b0000000;
    endcase

    result[7] = value_in[4];
  end else begin
    result = bit_array_in;
  end
end

assign out = result;

endmodule
