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
  input wire [4:0] value_in,
  
  output reg [7:0] out
);

always @(*) begin
  case(value_in[3:0])
    //                 7654321
    0 :  out[6:0] = 7'b0111111;
    1 :  out[6:0] = 7'b0000110;
    2 :  out[6:0] = 7'b1011011;
    3 :  out[6:0] = 7'b1001111;
    4 :  out[6:0] = 7'b1100110;
    5 :  out[6:0] = 7'b1101101;
    6 :  out[6:0] = 7'b1111100;
    7 :  out[6:0] = 7'b0000111;
    8 :  out[6:0] = 7'b1111111;
    9 :  out[6:0] = 7'b1100111;

    //                 7654321
    10:  out[6:0] = 7'b1110111;
    11:  out[6:0] = 7'b1111100;
    12:  out[6:0] = 7'b0111001;
    13:  out[6:0] = 7'b1011110;
    14:  out[6:0] = 7'b1111001;
    15:  out[6:0] = 7'b1110001;

    default:    
      out[6:0] = 7'b0000000;
  endcase

  out[7] = value_in[4];
end

endmodule
