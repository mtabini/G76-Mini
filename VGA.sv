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
  inout  [7:0]    mpuData
);

	logic  [16:0]   videoAddress;
	logic  [16:0]   videoAddressOffset;
	logic  [7:0]		videoData;
	logic           videoDataReady;
	logic 					videoHighResMode;

  logic  [16:0]   memoryAddress;

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

		.memoryAddress(memoryAddress),
		.memoryReadRequest(memoryReadRequest),
		.memoryWriteRequest(memoryWriteRequest),
		.memoryReadData(memoryReadData),
		.memoryWriteData(memoryWriteData),
		.memoryWriteComplete(memoryWriteComplete),
		.memoryReadComplete(memoryReadComplete),

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
		.vSync(vSync)
	);

	MCUInterface mcuInterface(
		.clock(clock),

		.videoAddressOffset(videoAddressOffset),
		.videoHighResMode(videoHighResMode),

		.memoryAddress(memoryAddress),
		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteData(memoryWriteData),
		.memoryWriteComplete(memoryWriteComplete),

		.mpuChipSelect(mpuChipSelect),
		.mpuWriteEnable(mpuWriteEnable),
		.mpuRegisterSelect(mpuRegisterSelect),
		.mpuDataBus(mpuData)
	);

	// assign videoHighResMode = 0;

	// logic pixelClock;

	// logic [9:0] x;
	// logic [8:0] y;

  // always_ff @(posedge clock) begin
	// 	pixelClock <= ~pixelClock;
  // end

	// always_ff @(posedge pixelClock) begin
	// 	if (x == 799) begin
	// 		x <= 0;
	// 		y <= y == 524 ? 0 : y + 1'b1;
	// 	end else begin
	// 		x <= x + 1'b1;
	// 	end

	// 	videoData <= x % 256;
	// end

endmodule

