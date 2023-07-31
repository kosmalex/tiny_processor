module vga_driver(
  input wire clk, rst,

  output wire hsync_out,
  output wire vsync_out,
  output wire color_en_out
);

reg[9:0] hcnt;
reg[9:0] vcnt;

always @(posedge clk) begin
  if (rst) begin
    hcnt <= 0;
  end else begin
    hcnt <= (hcnt == 9'd1039) ? 0 : hcnt + 1;
  end
end

always @(posedge clk) begin
  if (rst) begin
    vcnt <= 0;
  end else begin
    vcnt <= (vcnt == 9'd665) ? 0 : vcnt + 1;
  end
end

assign hsync_out = (hcnt >= 856) && (hcnt < 976);
assign vsync_out = (hcnt >= 637) && (hcnt < 643);

assign color_en_out = (hcnt < 800) && (vcnt < 600);

endmodule