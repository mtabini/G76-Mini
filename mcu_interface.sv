module MCUInterface(
  input                 reset,
  input                 clock,

  output logic [16:0]   memoryAddress,
  output logic          memoryWriteRequest,
  output logic [7:0]    memoryWriteData,  

  input                 memoryWriteComplete,

  input                 mpuChipSelect,
  input                 mpuWriteEnable,
  input  [2:0]          mpuRegisterSelect,
  inout  [7:0]          mpuDataBus
);


  parameter
    REGISTER_A_LOW                = 0,
    REGISTER_A_MID                = 1,
    REGISTER_A_HIGH               = 2,
    REGISTER_DATA                 = 3;

  logic        mpuRegisterWriteRequest;
  logic        mpuPixelWriteRequest;

  logic [16:0] mpuAddress;
  logic [7:0]  mpuPixelColor;

  logic [2:0] pixelWriteRequestSync;
  logic       doWrite;


  always_comb begin
    mpuRegisterWriteRequest = mpuChipSelect && !mpuWriteEnable;
    mpuPixelWriteRequest = mpuRegisterWriteRequest && (mpuRegisterSelect == REGISTER_DATA);
  end

  always_ff @(negedge mpuRegisterWriteRequest or posedge reset) begin
    if (reset) begin
      mpuAddress <= 0;
      mpuPixelColor <= 0;
    end else begin
      case (mpuRegisterSelect)
        REGISTER_A_LOW        : mpuAddress[7:0] <= mpuDataBus;
        REGISTER_A_MID        : mpuAddress[15:8] <= mpuDataBus;
        REGISTER_A_HIGH       : mpuAddress[16] <= mpuDataBus[0];
        REGISTER_DATA         : mpuPixelColor <= mpuDataBus;            
      endcase
    end
  end

  always_ff @(posedge clock) begin
    pixelWriteRequestSync <= { pixelWriteRequestSync[1:0], mpuPixelWriteRequest };
  end

  always_comb begin
    if (reset) begin
      doWrite = 0;
    end else begin
      doWrite = pixelWriteRequestSync[2:1] == 2'b10;
    end
  end

  always_ff @(posedge doWrite or posedge reset) begin
    if (reset) begin
      memoryAddress <= 0;
      memoryWriteData <= 0;
    end else begin
      memoryAddress <= mpuAddress;
      memoryWriteData <= mpuPixelColor;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      memoryWriteRequest <= 0;
    end else if (!memoryWriteRequest) begin
      if (doWrite) begin
        memoryWriteRequest <= 1;
      end
    end else begin
      memoryWriteRequest <= ~memoryWriteComplete;
    end
  end
endmodule


module MCUInterfaceTB;

  logic          reset;
  logic          clock;

  logic  [2:0]   currentState;

  logic  [8:0]   videoAddress;
	logic  [7:0]	 videoData;
	logic          videoDataReady;

  logic [16:0]   memoryAddress;

  logic          memoryReadRequest;
  logic          memoryWriteRequest;
  logic [7:0]    memoryWriteData;

  logic  [7:0]   memoryReadData;
  logic          memoryReadComplete;
  logic          memoryWriteComplete;

  logic          mpuChipSelect;
  logic          mpuWriteEnable;
  logic  [2:0]   mpuRegisterSelect;
  logic  [7:0]   mpuDataBus;

  logic  [16:0]  ramAddress;
  wire   [7:0]   ramData;
  logic          ramWriteEnable;
  logic          ramOutputEnable;


	MemoryManager memoryManager(
    .reset(reset),
		.clock(clock),
		.currentState(currentState),

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

	MCUInterface mpuInterface(
    .reset(reset),
		.clock(clock),

		.memoryAddress(memoryAddress),

		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteData(memoryWriteData),

		.memoryWriteComplete(memoryWriteComplete),

		.mpuChipSelect(mpuChipSelect),
		.mpuWriteEnable(mpuWriteEnable),
		.mpuRegisterSelect(mpuRegisterSelect),
		.mpuDataBus(mpuDataBus)
	);


  initial begin
    clock = 0;
    reset = 0;

    #1 reset = 1;
    #1 clock = 1;
    #1 clock = 0;
    #1 reset = 0;

    forever #10 clock = ~clock;
  end

  initial begin
    mpuChipSelect = 0;
    mpuWriteEnable = 1;
    mpuRegisterSelect = 0;
    mpuDataBus = 0;

    #11 begin
      mpuRegisterSelect = 0;
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end
    #17 mpuDataBus = 255;
    #12 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 0;
    end
    #21 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 1;
    end
    #10 mpuDataBus = 8'bZ;
    #10 begin
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end

    #11 begin
      mpuRegisterSelect = 1;
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end
    #17 mpuDataBus = 1;
    #12 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 0;
    end
    #21 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 1;
    end
    #10 mpuDataBus = 8'bZ;
    #10 begin
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end

    #11 begin
      mpuRegisterSelect = 2;
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end
    #17 mpuDataBus = 2;
    #12 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 0;
    end
    #21 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 1;
    end
    #10 mpuDataBus = 8'bZ;
    #10 begin
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end

    #11 begin
      mpuRegisterSelect = 3;
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end
    #17 mpuDataBus = 3;
    #12 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 0;
    end
    #21 begin
      mpuChipSelect = 1;
      mpuWriteEnable = 1;
    end
    #10 mpuDataBus = 8'bZ;
    #10 begin
      mpuChipSelect = 0;
      mpuWriteEnable = 1;
    end


  end

endmodule