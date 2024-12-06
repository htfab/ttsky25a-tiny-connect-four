module btn_debounce #(CLKS_TO_WAIT=25000) (
  clk,
  rst_n,
  e_debug,
  btn_in,
  btn_out
);

  input clk;
  input rst_n;
  input e_debug;
  input btn_in;
  output btn_out;

  localparam WIDTH = $clog2(CLKS_TO_WAIT)+1;

  localparam ST_IDLE = 1'b0;
  localparam ST_COUNTING = 1'b1;

  reg [WIDTH-1:0] debounce_counter;  // 18-bit counter for 10 ms debounce time at 25 MHz clock
  reg button_sync_0;
  reg button_sync_1;
  reg debounced;

  reg  debounce_state;
  wire btn_pushed;

  assign btn_out = e_debug ? btn_in : debounced;
  assign btn_pushed = ~button_sync_0 & button_sync_1;

  // Synchronize the button input to the clock domain to avoid metastability
  always @(posedge clk or negedge rst_n)
  begin
    if (~rst_n)
    begin
      button_sync_0 <= 1'b1;
      button_sync_1 <= 1'b1;
    end
    else
    begin
      button_sync_0 <= btn_in;
      button_sync_1 <= button_sync_0;
    end
  end

  // Debounce logic
  always @(posedge clk or negedge rst_n)
  begin
    if (~rst_n)
    begin
      debounce_counter <= {WIDTH{1'b0}};
      debounced <= 1'b1;
    end
    else
    begin
      case (debounce_state)
        ST_IDLE:
        begin
          if (btn_pushed)
          begin
            debounce_state <= ST_COUNTING;
            debounced <= 1'b0;
          end
          else
          begin
            debounce_state <= ST_IDLE;
            debounced <= 1'b1;
          end
        end
        ST_COUNTING:
        begin
          debounced <= 1'b1;
          debounce_counter <= debounce_counter + 1;
          if (debounce_counter == CLKS_TO_WAIT)
            debounce_state <= ST_IDLE;
        end
      endcase
    end
  end

endmodule
