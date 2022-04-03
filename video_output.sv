module VideoOutput (
  input                 reset,
  input                 clock,  

  output logic [16:0]   videoAddress,
  input  logic [7:0]    videoData,
  input                 videoDataReady,

  input                 highResMode,

  output logic [7:0]    videoOutput,

  output logic          hSync,
  output logic          vSync
);


  parameter H_VISIBLE_AREA        = 10'd640;
  parameter H_FRONT_PORCH         = 10'd 16;
  parameter H_SYNC_PULSE          = 10'd 96;
  parameter H_BACK_PORCH          = 10'd 48;
  
  parameter H_SYNC_PULSE_START    = H_VISIBLE_AREA + H_FRONT_PORCH;
  parameter H_SYNC_PULSE_END      = H_SYNC_PULSE_START + H_SYNC_PULSE - 1;
  
  parameter H_LAST_POSITION       = H_SYNC_PULSE_START + H_SYNC_PULSE + H_BACK_PORCH - 1;
  
  parameter V_VISIBLE_AREA        = 9'd480;
  parameter V_FRONT_PORCH         = 9'd 10;
  parameter V_SYNC_PULSE          = 9'd  2;
  parameter V_BACK_PORCH          = 9'd 33;
  
  parameter V_SYNC_PULSE_START    = V_VISIBLE_AREA + V_FRONT_PORCH;
  parameter V_SYNC_PULSE_END      = V_SYNC_PULSE_START + V_SYNC_PULSE - 1;
  
  parameter V_LAST_POSITION       = V_SYNC_PULSE_START + V_SYNC_PULSE + V_BACK_PORCH - 1;


  logic [9:0]     xAddr;
  logic [8:0]     yAddr;

  logic           pixelClock;
  logic           inVisibleArea;


  always_comb begin
    videoAddress = { yAddr[8:1] , xAddr[9:1] };
    inVisibleArea = (xAddr < H_VISIBLE_AREA && yAddr < V_VISIBLE_AREA);
    hSync = (xAddr < H_SYNC_PULSE_START || xAddr > H_SYNC_PULSE_END);
    vSync = (yAddr < V_SYNC_PULSE_START || yAddr > V_SYNC_PULSE_END);
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      pixelClock <= 0;
    end else begin
      pixelClock <= ~pixelClock;
    end
  end

  always_ff @(posedge pixelClock) begin
    if (reset) begin
      xAddr <= 0;
      yAddr <= 0;
    end else begin
      if (xAddr == H_LAST_POSITION) begin
        xAddr <= 1'b0;
        yAddr <= (yAddr == V_LAST_POSITION) ? 1'b0 : yAddr + 1'b1;
      end else begin
        xAddr <= xAddr + 1'b1;
      end

      if (inVisibleArea) begin
        if (highResMode) begin
          case (xAddr[0] ? videoData[3:0] : videoData[7:4])
            4'h00 : videoOutput <= 8'b00000000;   // Black
            4'h01 : videoOutput <= 8'b10000000;   // Blue
            4'h02 : videoOutput <= 8'b00110000;   // Green
            4'h03 : videoOutput <= 8'b10110000;   // Cyan
            4'h04 : videoOutput <= 8'b00000110;   // Red
            4'h05 : videoOutput <= 8'b10000110;   // Magenta
            4'h06 : videoOutput <= 8'b00011110;   // Brown
            4'h07 : videoOutput <= 8'b10100100;   // Grey
            4'h08 : videoOutput <= 8'b01010010;   // Dark grey
            4'h09 : videoOutput <= 8'b11011011;   // Light blue
            4'h0a : videoOutput <= 8'b01111011;   // Light green
            4'h0b : videoOutput <= 8'b11111011;   // Light cyan
            4'h0c : videoOutput <= 8'b01011111;   // Light red
            4'h0d : videoOutput <= 8'b11011111;   // Light magenta
            4'h0e : videoOutput <= 8'b01111111;   // Yellow
            4'h0f : videoOutput <= 8'b11111111;   // White
          endcase
        end else begin
          videoOutput <= videoData;
        end
      end else begin
        videoOutput <= 8'bZ;
      end
    end
  end

endmodule

