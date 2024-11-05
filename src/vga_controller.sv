module vga_controller (
    input  logic pixel_clk,
    input  logic rst_n,
    output logic hsync,
    output logic vsync,
    output logic [9:0] x_count,
    output logic [9:0] y_count
);

    // VGA timing parameters (same as in top module)
	localparam H_ACTIVE = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC = 96;
    localparam H_BACK_PORCH = 48;
    localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;

    localparam V_ACTIVE = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC = 2;
    localparam V_BACK_PORCH = 33;
    localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;


    // Horizontal and vertical counters
    always_ff @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            x_count <= 10'd0;
            y_count <= 10'd0;
        end else begin
            if (x_count == H_TOTAL - 1) begin
                x_count <= 10'd0;
                if (y_count == V_TOTAL - 1)
                    y_count <= 10'd0;
                else
                    y_count <= y_count + 10'b1;
            end else begin
                x_count <= x_count + 10'b1;
            end
        end
    end

    // Generate hsync and vsync
    assign hsync = (x_count >= H_ACTIVE + H_FRONT_PORCH) &&
                   (x_count < H_ACTIVE + H_FRONT_PORCH + H_SYNC);
    assign vsync = (y_count >= V_ACTIVE + V_FRONT_PORCH) &&
                   (y_count < V_ACTIVE + V_FRONT_PORCH + V_SYNC);

endmodule