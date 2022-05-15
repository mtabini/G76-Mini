module VideoOutput (
  input                   clock,  
  input [2:0]             clockPhase,

  input [7:0]             pixel1,
  input [7:0]             pixel2,

  output logic [8:0]      xCoord,
  output logic [7:0]      yCoord,

  output logic [7:0]      videoData,

  output logic            hSync,
  output logic            vSync
);


  parameter H_VISIBLE_AREA        = 10'd640;
  parameter H_FRONT_PORCH         = 10'd 20;  // Originally 16, cheat a little
  parameter H_SYNC_PULSE          = 10'd100;  // Originally 96
  parameter H_BACK_PORCH          = 10'd 52;  // Originally 48
  
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

  logic           inVisibleArea;


  always_comb begin
    xCoord = xAddr[9:1];
    yCoord = yAddr[8:1];
    inVisibleArea = (xAddr < H_VISIBLE_AREA && yAddr < V_VISIBLE_AREA);
    hSync = (xAddr < H_SYNC_PULSE_START || xAddr > H_SYNC_PULSE_END);
    vSync = (yAddr < V_SYNC_PULSE_START || yAddr > V_SYNC_PULSE_END);
  end


  always_ff @(negedge clockPhase[0]) begin

    if (xAddr == H_LAST_POSITION) begin
      xAddr = '0;
      yAddr = (yAddr == V_LAST_POSITION) ? '0 : yAddr + 1'b1;
    end else begin
      xAddr = xAddr + 1'b1;
    end
  end

  always_ff @(posedge clock) begin
    case(clockPhase)
      CLOCK_PHASE_RENDER_PIXEL_1: videoData <= inVisibleArea ? pixel1 : 8'hZZ;
      CLOCK_PHASE_RENDER_PIXEL_2: videoData <= inVisibleArea ? pixel2 : 8'hZZ;
    endcase
  end
  
endmodule

