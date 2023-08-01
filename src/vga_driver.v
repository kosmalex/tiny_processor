module vga_driver(
  input wire clk, rst,

  output wire hsync_out,
  output wire vsync_out,
  
  output wire color_en_out
);

reg[10:0] hcnt;
reg[9:0] vcnt;

wire done_w_line;
assign done_w_line = (hcnt == 11'd1039);

always @(posedge clk) begin
  if (rst) begin
    hcnt <= 0;
  end else begin
    hcnt <= done_w_line ? 0 : hcnt + 1;
  end
end

always @(posedge clk) begin
  if (rst) begin
    vcnt <= 0;
  end else if(done_w_line) begin
    vcnt <= (vcnt == 10'd665) ? 0 : vcnt + 1;
  end
end

assign hsync_out = ~( (hcnt >= 856) && (hcnt < 976) );
assign vsync_out = ~( (vcnt >= 637) && (vcnt < 643) );

assign color_en_out = (hcnt < 800) && (vcnt < 600);

endmodule