module buzzer (
  input wire clk,          // 50MHz clock input
  input wire rst_n,        // Active low reset
  input wire [13:0] note,  // Note frequency input (0-16383 Hz)
  input wire enable,       // Enable signal
  output reg buzzer_out    // Buzzer output signal
);

  localparam CLK_FREQ = 50_000_000;

  reg [25:0] counter; // needs to count up to a maximum of 50MHz / (note * 2)
  wire [25:0] threshold;

  assign threshold = (CLK_FREQ / (note * 2)) - 1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 26'd0;
      buzzer_out <= 1'b0;
    end else if (enable) begin
      if (counter >= threshold) begin
        counter <= 26'd0;
        buzzer_out <= ~buzzer_out;
      end else begin
        counter <= counter + 1;
      end
    end else begin
      buzzer_out <= 1'b0;
    end
  end

endmodule
