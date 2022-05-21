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
  inout  [7:0]    mpuData,
	output					mpuVideoInterrupt
);

	logic  [16:0]   videoAddress;
	logic  [16:0]   videoAddressOffset;
	logic  [7:0]		videoData;
	logic           videoDataReady;
	logic 					videoHighResMode;
	logic 					videoVBlank;

  logic  [16:0]   memoryWriteAddress;
	logic  [16:0]   memoryReadAddress;

  logic           memoryReadRequest;
  logic           memoryWriteRequest;
  logic           memoryReadComplete;
  logic           memoryWriteComplete;

  logic  [7:0]    memoryWriteData;    
  logic  [7:0]    memoryReadData;


	MemoryManager memoryManager(
		.clock(clock),

		.videoAddress(videoAddress),
		.videoAddressOffset(videoAddressOffset),
		.videoData(videoData),
		.videoDataReady(videoDataReady),

		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteAddress(memoryWriteAddress),
		.memoryWriteData(memoryWriteData),
		.memoryWriteComplete(memoryWriteComplete),

		.memoryReadAddress(memoryReadAddress),
		.memoryReadData(memoryReadData),

		.ramAddress(ramAddress),
		.ramData(ramData),
		.ramOutputEnable(ramOutputEnable),
		.ramWriteEnable(ramWriteEnable)
	);

	VideoOutput videoOutput(
		.clock(clock),

		.videoAddress(videoAddress),
		.videoData(videoData),
		.videoDataReady(videoDataReady),
		.highResMode(videoHighResMode),

		.videoOutput(videoOutputData),

		.hSync(hSync),
		.vSync(vSync),
		.vBlank(videoVBlank)
	);

	MCUInterface mcuInterface(
		.clock(clock),

		.videoAddressOffset(videoAddressOffset),
		.videoHighResMode(videoHighResMode),
		.videoVBlank(videoVBlank),

		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteAddress(memoryWriteAddress),
		.memoryWriteData(memoryWriteData),
		.memoryWriteComplete(memoryWriteComplete),

		.memoryReadAddress(memoryReadAddress),
		.memoryReadData(memoryReadData),

		.mpuChipSelect(mpuChipSelect),
		.mpuWriteEnable(mpuWriteEnable),
		.mpuRegisterSelect(mpuRegisterSelect),
		.mpuDataBus(mpuData),
		.mpuVideoInterrupt(mpuVideoInterrupt)
	);

endmodule

