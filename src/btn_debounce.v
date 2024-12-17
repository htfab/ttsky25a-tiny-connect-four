module btn_debounce #(CLKS_TO_WAIT=25000, N_BUTTONS=3) (
  clk,
  rst_n,
  e_debug,
  btns_in,
  btns_out
);

  input  clk;
  input  rst_n;
  input  e_debug;
  input  [N_BUTTONS-1:0] btns_in;
  output [N_BUTTONS-1:0] btns_out;

  localparam WIDTH = $clog2(CLKS_TO_WAIT);

  localparam ST_IDLE = 1'b0;
  localparam ST_COUNTING = 1'b1;

  reg [WIDTH-1:0] debounce_counter;  // 18-bit counter for 10 ms debounce time at 25 MHz clock
  reg [N_BUTTONS-1:0] button_sync_0;
  reg [N_BUTTONS-1:0] button_sync_1;
  reg [N_BUTTONS-1:0] button_sync_2;
  reg [N_BUTTONS-1:0] debounced;

  reg  debounce_state;
  wire btn_pushed;

  assign btns_out = debounced;
  assign btn_pushed = button_sync_2 == {N_BUTTONS{1'b1}} & button_sync_1 != {N_BUTTONS{1'b1}};

  // Synchronize the button input to the clock domain to avoid metastability
  always @(posedge clk or negedge rst_n)
  begin
    if (~rst_n)
    begin
      button_sync_0 <= {N_BUTTONS{1'b1}};
      button_sync_1 <= {N_BUTTONS{1'b1}};
      button_sync_2 <= {N_BUTTONS{1'b1}};
    end
    else
    begin
      button_sync_0 <= btns_in;
      button_sync_1 <= button_sync_0;
      button_sync_2 <= button_sync_1;
    end
  end

  // Debounce logic
  always @(posedge clk or negedge rst_n)
  begin
    if (~rst_n)
    begin
      debounce_counter <= {WIDTH{1'b0}};
      debounced <= {N_BUTTONS{1'b1}};
      debounce_state <= ST_IDLE;
    end
    else
    begin
      case (debounce_state)
        ST_IDLE:
        begin
          if (btn_pushed)
          begin
            debounce_state <= ST_COUNTING;
            debounced <= button_sync_1;
          end
          else
          begin
            debounce_state <= ST_IDLE;
            debounced <= {N_BUTTONS{1'b1}};
          end
        end
        ST_COUNTING:
        begin
          debounced <= {N_BUTTONS{1'b1}};
          if (e_debug)
            debounce_state <= ST_IDLE;
          else
          begin
            debounce_counter <= debounce_counter + 1;
            if (debounce_counter == CLKS_TO_WAIT)
              debounce_state <= ST_IDLE;
          end
        end
      endcase
    end
  end

endmodule
