module game_sounds (
  clk,
  rst_n,
  start,
  type,
  buzzer
);

  input wire clk;
  input wire rst_n;
  input wire start;
  input wire [1:0] type;
  output wire buzzer;

  localparam CLK_FREQ = 50_000_000;
  localparam DURATION_SHORT = 2_000_000; // 40ms
  localparam DURATION_LONG = 5_000_000; // 100ms

  localparam ST_IDLE = 1'b0;
  localparam ST_PLAY = 1'b1;

  localparam TYPE_START = 2'b00;
  localparam TYPE_DROP = 2'b01;
  localparam TYPE_ERROR = 2'b10;
  localparam TYPE_VICTORY = 2'b11;

  localparam NOTE_C6 = 1047;
  localparam NOTE_D6 = 1175;
  localparam NOTE_E6 = 1319;
  localparam NOTE_F6 = 1397;
  localparam NOTE_G6 = 1568;
  localparam NOTE_A6 = 1760;
  localparam NOTE_B6 = 1976;
  localparam NOTE_C7 = 2093;
  localparam NOTE_G5 = 784;

  localparam NOTE_F4 = 349;
  localparam NOTE_B3 = 247;

  localparam N_START_TONES = 4;
  localparam N_DROP_TONES = 2;
  localparam N_ERROR_TONES = 2;
  localparam N_VICTORY_TONES = 13;

  wire [13:0] START_TONES [0:3];
  assign START_TONES[0] = NOTE_C6;
  assign START_TONES[1] = NOTE_E6;
  assign START_TONES[2] = NOTE_G6;
  assign START_TONES[3] = NOTE_C7;

  wire [13:0] DROP_TONES [0:1];
  assign DROP_TONES[0] = NOTE_G6;
  assign DROP_TONES[1] = NOTE_C7;

  wire [13:0] ERROR_TONES [0:1];
  assign ERROR_TONES[0] = NOTE_F4;
  assign ERROR_TONES[1] = NOTE_B3;

  wire [13:0] VICTORY_TONES [0:12];
  assign VICTORY_TONES[0] = NOTE_C6;
  assign VICTORY_TONES[1] = NOTE_G5;
  assign VICTORY_TONES[2] = NOTE_E6;
  assign VICTORY_TONES[3] = NOTE_C6;
  assign VICTORY_TONES[4] = NOTE_G6;
  assign VICTORY_TONES[5] = NOTE_E6;
  assign VICTORY_TONES[6] = NOTE_B6;
  assign VICTORY_TONES[7] = NOTE_G6;
  assign VICTORY_TONES[8] = NOTE_F6;
  assign VICTORY_TONES[9] = NOTE_D6;
  assign VICTORY_TONES[10] = NOTE_G6;
  assign VICTORY_TONES[11] = NOTE_B6;
  assign VICTORY_TONES[12] = NOTE_C7;

  reg [2:0] start_sync;
  wire start_pressed;

  reg [3:0] note_index;
  reg [31:0] duration_counter; // Needs to count up to DURATION
  reg [13:0] note;

  reg state;
  wire [3:0] n_notes;
  wire [31:0] note_duration;
  wire play_sound;

  assign start_pressed = start_sync[2] & ~start_sync[1];

  assign n_notes = (type == TYPE_START) ? N_START_TONES :
                   (type == TYPE_DROP) ? N_DROP_TONES :
                   (type == TYPE_ERROR) ? N_ERROR_TONES :
                   (type == TYPE_VICTORY) ? N_VICTORY_TONES : 0;

  assign note_duration = (type == TYPE_START) ? DURATION_LONG :
                         (type == TYPE_DROP) ? DURATION_SHORT :
                         (type == TYPE_ERROR) ? DURATION_LONG :
                         (type == TYPE_VICTORY) ? DURATION_LONG : 0;

  assign play_sound = (state == ST_PLAY);

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      start_sync <= 3'b111;
    else
      start_sync <= {start_sync[1:0], start};
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state <= ST_IDLE;
      duration_counter <= 32'd0;
      note_index <= 4'd0;
    end
    else
    begin
      case (state)
        ST_IDLE:
        begin
          if (start_pressed)
          begin
            state <= ST_PLAY;
            duration_counter <= note_duration;
            note_index <= 4'd0;
          end
        end
        ST_PLAY:
        begin
          if (type == TYPE_START)
            note <= START_TONES[note_index];
          else if (type == TYPE_DROP)
            note <= DROP_TONES[note_index];
          else if (type == TYPE_ERROR)
            note <= ERROR_TONES[note_index];
          else if (type == TYPE_VICTORY)
            note <= VICTORY_TONES[note_index];

          if (duration_counter == 0)
          begin
            if (note_index == n_notes-1)
            begin
              state <= ST_IDLE;
              note_index <= 4'd0;
            end
            else
            begin
              state <= ST_PLAY;
              duration_counter <= note_duration;
              note_index <= note_index + 1;
            end
          end
          else
            duration_counter <= duration_counter - 1;
        end
      endcase
    end
  end

  buzzer buzzer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .note(note),
    .enable(play_sound),
    .buzzer_out(buzzer)
  );

endmodule


