module buzzer (
  input wire clk,          // 50MHz clock input
  input wire rst_n,        // Active low reset
  input wire [3:0] note,  // Note frequency input (0-16383 Hz)
  input wire enable,       // Enable signal
  output reg buzzer_out    // Buzzer output signal
);

  localparam NOTE_B3_FREQ = 247;

  localparam CLK_FREQ = 25_000_000;
  localparam HIGHEST_NOTE_CLKS = (CLK_FREQ / (NOTE_B3_FREQ*2)) - 1;
  localparam COUNTER_BITS = $clog2(HIGHEST_NOTE_CLKS);

  // Note definitions
  localparam NOTE_C6 = 1;
  localparam NOTE_D6 = 2;
  localparam NOTE_E6 = 3;
  localparam NOTE_F6 = 4;
  localparam NOTE_G6 = 5;
  localparam NOTE_B6 = 6;
  localparam NOTE_C7 = 7;
  localparam NOTE_G5 = 8;

  localparam NOTE_F4 = 9;
  localparam NOTE_B3 = 10;

  // Frequencies for each note
  localparam NOTE_C6_FREQ = 1047;
  localparam NOTE_D6_FREQ = 1175;
  localparam NOTE_E6_FREQ = 1319;
  localparam NOTE_F6_FREQ = 1397;
  localparam NOTE_G6_FREQ = 1568;
  localparam NOTE_B6_FREQ = 1976;
  localparam NOTE_C7_FREQ = 2093;
  localparam NOTE_G5_FREQ = 784;

  localparam NOTE_F4_FREQ = 349;
  

  // CLKs per note
  localparam NOTE_C6_CLKS = (CLK_FREQ / (NOTE_C6_FREQ*2)) - 1;
  localparam NOTE_D6_CLKS = (CLK_FREQ / (NOTE_D6_FREQ*2)) - 1;
  localparam NOTE_E6_CLKS = (CLK_FREQ / (NOTE_E6_FREQ*2)) - 1;
  localparam NOTE_F6_CLKS = (CLK_FREQ / (NOTE_F6_FREQ*2)) - 1;
  localparam NOTE_G6_CLKS = (CLK_FREQ / (NOTE_G6_FREQ*2)) - 1;
  localparam NOTE_B6_CLKS = (CLK_FREQ / (NOTE_B6_FREQ*2)) - 1;
  localparam NOTE_C7_CLKS = (CLK_FREQ / (NOTE_C7_FREQ*2)) - 1;
  localparam NOTE_G5_CLKS = (CLK_FREQ / (NOTE_G5_FREQ*2)) - 1;
  localparam NOTE_F4_CLKS = (CLK_FREQ / (NOTE_F4_FREQ*2)) - 1;
  localparam NOTE_B3_CLKS = (CLK_FREQ / (NOTE_B3_FREQ*2)) - 1;

  reg [COUNTER_BITS-1:0] counter; // needs to count up to a maximum of 25MHz / (note * 2)
  wire [COUNTER_BITS-1:0] threshold;

  assign threshold = note == NOTE_C6 ? NOTE_C6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_D6 ? NOTE_D6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_E6 ? NOTE_E6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_F6 ? NOTE_F6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_G6 ? NOTE_G6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_B6 ? NOTE_B6_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_C7 ? NOTE_C7_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_G5 ? NOTE_G5_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_F4 ? NOTE_F4_CLKS[COUNTER_BITS-1:0] :
                     note == NOTE_B3 ? NOTE_B3_CLKS[COUNTER_BITS-1:0] :
                     {COUNTER_BITS{1'b0}};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= {COUNTER_BITS{1'b0}};
      buzzer_out <= 1'b0;
    end else if (enable) begin
      if (counter >= threshold) begin
        counter <= {COUNTER_BITS{1'b0}};
        buzzer_out <= ~buzzer_out;
      end else begin
        counter <= counter + 1;
      end
    end else begin
      buzzer_out <= 1'b0;
    end
  end

endmodule
