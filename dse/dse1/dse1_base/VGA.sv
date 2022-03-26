module VGA(
  input           clock,
  
  output					hSync,
  output          vSync,
  output  [7:0]   videoData,
  
  output  [16:0]  ramAddress,
  inout   [7:0]   ramData,
  output          ramWriteEnable,
  output          ramOutputEnable,
  
  input           mpuChipSelect,
  input           mpuWriteEnable,
  input  [2:0]    mpuRegisterSelect,
  input  [7:0]    mpuData
);

	logic						reset;

  logic [2:0]     clockPhase;
  
  logic  [7:0]		pixel1;
  logic  [7:0]    pixel2;
	
  logic [8:0]  	  xCoord;
  logic [7:0]    	yCoord;

  logic           pendingWriteQueueReadRequest;
  logic [24:0]   	pendingWriteQueueReadBus;
  logic          	pendingWriteQueueReadEmpty;

  ClockGenerator clockGenerator(
    .clock(clock),
    .clockPhase(clockPhase)
  );

	VideoOutput videoOutput(
		.reset(reset),
		.clock(clock),
		.clockPhase(clockPhase),

		.pixel1(pixel1),
		.pixel2(pixel2),

		.xCoord(xCoord),
		.yCoord(yCoord),

		.hSync(hSync),
		.vSync(vSync),

		.videoData(videoData)
	);

	MemoryManager memoryManager(
		.reset(reset),
		.clock(clock),
		.clockPhase(clockPhase),

		.pixel1(pixel1),
		.pixel2(pixel2),

		.readXCoord(xCoord),
		.readYCoord(yCoord),

		.pendingWriteQueueReadBus(pendingWriteQueueReadBus),
		.pendingWriteQueueReadRequest(pendingWriteQueueReadRequest),
		.pendingWriteQueueReadEmpty(pendingWriteQueueReadEmpty),

		.address(ramAddress),
		.data(ramData),
		.outputEnable(ramOutputEnable),
		.writeEnable(ramWriteEnable)
	);

	MPUInterface mpuInterface(
		.reset(reset),
		.clock(clock),
		.clockPhase(clockPhase),

		.chipSelect(mpuChipSelect),
		.writeEnable(mpuWriteEnable),

		.registerSelect(mpuRegisterSelect),
		.registerData(mpuData),

		.pendingWriteQueueReadBus(pendingWriteQueueReadBus),
		.pendingWriteQueueReadRequest(pendingWriteQueueReadRequest),
		.pendingWriteQueueReadEmpty(pendingWriteQueueReadEmpty),
	);

	initial begin
		pixel1 = 8'hff;
		pixel2 = 8'h00;
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
