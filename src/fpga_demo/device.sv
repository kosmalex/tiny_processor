module device (
  input logic clk, rst,

  input logic mosi,
  input logic cs,

  output logic miso
);

logic[7:0] register;

generate 
  genvar i;
  for (i = 0; i < 8; i++) begin
    if (i == 0) begin
      always_ff @(posedge clk) begin
        if (rst) begin
          register <= 8'hAD;
        end else begin
          if (~cs) begin
            register[7] <= 0;
          end
        end
      end
    end else begin
      always_ff @(posedge clk) begin
        if (rst) begin
          register <= 8'hAD;
        end else begin
          if (~cs) begin
            register[8 - i - 1] <= register[8 - i];
          end
        end
      end
    end
  end
endgenerate

logic phase_shift;
always_ff @(negedge clk) begin
  phase_shift <= register[0];
end

assign miso = phase_shift;

endmodule