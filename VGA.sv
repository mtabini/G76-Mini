module VGA(
  input           clock,
  
  output					hSync,
  output          vSync,
  output  [7:0]   videoOutputData,
  
  output  [16:0]  ramAddress,
  inout   [7:0]   ramData,
  output          ramWriteEnable,
  output          ramOutputEnable,
  
  input           mpuChipSelect,
  input           mpuWriteEnable,
  input  [2:0]    mpuRegisterSelect,
  input  [7:0]    mpuData
);

  logic  [2:0]    currentState;

  logic  [8:0]    videoXCoord;
  logic  [7:0]    videoYCoord;
	logic  [7:0]		videoData;
	logic           videoDataReady;

  logic  [8:0]    memoryXCoord;
  logic  [7:0]    memoryYCoord;

  logic           memoryReadRequest;
  logic           memoryWriteRequest;
  logic  [7:0]    memoryWriteData;  
  
  logic  [7:0]    memoryReadData;


	MemoryManager memoryManager(
		.clock(clock),
		.currentState(currentState),

		.videoXCoord(videoXCoord),
		.videoYCoord(videoYCoord),
		.videoData(videoData),
		.videoDataReady(videoDataReady),

		.memoryXCoord(memoryXCoord),
		.memoryYCoord(memoryYCoord),
		.memoryReadRequest(memoryReadRequest),
		.memoryWriteRequest(memoryWriteRequest),
		.memoryReadData(memoryReadData),
		.memoryWriteData(memoryWriteData),

		.ramAddress(ramAddress),
		.ramData(ramData),
		.ramOutputEnable(ramOutputEnable),
		.ramWriteEnable(ramWriteEnable)
	);

	VideoOutput videoOutput(
		.clock(clock),
		.currentState(currentState),

		.xCoord(videoXCoord),
		.yCoord(videoYCoord),
		.videoData(videoData),
		.videoDataReady(videoDataReady),

		.videoOutput(videoOutputData),

		.hSync(hSync),
		.vSync(vSync)
	);

	`include "clock_phases.sv"

	logic [8:0] xx;
	logic [7:0] yy;

	always_ff @(posedge clock) begin
		if (currentState == CLOCK_PHASE_PREP_MEMORY_OP) begin
			memoryWriteRequest <= 1;
			memoryXCoord <= xx;
			memoryYCoord <= yy;
			memoryWriteData <= xx % 256;
			
			if (xx == 319) begin
				xx <= 0;
				yy <= yy == 239 ? 0 : yy + 1;
			end else
				xx <= xx + 1;
		end
	end


endmodule


module VGATB;

  logic      clock;
  
  initial begin
    #1 clock = 0;
    forever #1 clock = ~clock;
  end
  
  VGA vga(
    .clock(clock)
  );
  
endmodule
