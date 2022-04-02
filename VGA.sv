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
	logic  [7:0]		videoData;
	logic           videoDataReady;

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

		.videoOutput(videoOutputData),

		.hSync(hSync),
		.vSync(vSync)
	);

	MCUInterface mpuInterface(
		.clock(clock),

		.memoryAddress(memoryAddress),
		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteData(memoryWriteData),
		.memoryReadData(memoryReadData),
		.memoryWriteComplete(memoryWriteComplete),

		.mpuChipSelect(mpuChipSelect),
		.mpuWriteEnable(mpuWriteEnable),
		.mpuRegisterSelect(mpuRegisterSelect),
		.mpuDataBus(mpuData)
	);

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
