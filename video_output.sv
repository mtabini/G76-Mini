module VideoOutput (
  input                 reset,
  input                 clock,  

  output logic [16:0]   videoAddress,
  input  logic [7:0]    videoData,
  input                 videoDataReady,

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

  always_ff @(negedge pixelClock) begin
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

      videoOutput <= inVisibleArea ? videoData : 8'bZ;
    end
  end

endmodule

