/**
  A pseudo-device that comunicates through spi protocol
*/

module device (
  input logic clk, rst,

  input logic mosi,
  input logic cs,

  output logic miso
);

logic[7:0] mem[8];

initial $readmemh("./deviced.mem", mem);

logic[7:0] register;

logic pos_edge;
logic neg_edge;
logic cs_reg;
always @(posedge clk) begin
  if (rst) begin
    cs_reg <= 1'b1;
  end else begin
    cs_reg <= cs; 
  end
end
assign pos_edge = ~cs_reg & cs;
assign neg_edge = cs_reg & ~cs;

logic[2:0] counter;
always @(posedge clk) begin
  if (rst) begin
    counter <= 0;
  end else if (neg_edge) begin
    counter <= counter + 1; // It will wrap around anyway 
  end
end

generate 
  genvar i;
  for (i = 0; i < 8; i++) begin
    if (i == 0) begin
      always_ff @(posedge clk) begin
        if (rst) begin
          register[7] <= mem[0][7];
        end else begin
          if (pos_edge) begin
            register[7] <= mem[counter][7];
          end else if (~cs) begin
            register[7] <= 0;
          end
        end
      end
    end else begin
      always_ff @(posedge clk) begin
        if (rst) begin
          register[8 - i - 1] <= mem[0][8 - i - 1];
        end else begin
          if (pos_edge) begin
            register[8 - i - 1] <= mem[counter][8 - i - 1];
          end else if (~cs) begin
            register[8 - i - 1] <= register[8 - i];
          end
        end
      end
    end
  end
endgenerate

assign miso = register[0];

endmodule