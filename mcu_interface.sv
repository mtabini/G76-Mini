module MCUInterface(
  input           reset,
  input           clock,

  output logic [8:0]    memoryXCoord,
  output logic [7:0]    memoryYCoord,

  output logic         memoryReadRequest,
  output logic         memoryWriteRequest,
  output logic [7:0]    memoryWriteData,  

  input  [7:0]    memoryReadData,
  input           memoryReadComplete,
  input           memoryWriteComplete,

  input           mpuChipSelect,
  input           mpuWriteEnable,
  input  [2:0]    mpuRegisterSelect,
  input  [7:0]    mpuDataBus
);


  parameter
    REGISTER_X_LOW                = 0,
    REGISTER_X_HIGH               = 1,
    REGISTER_Y                    = 2,
    REGISTER_DATA                 = 3,
    REGISTER_AUTOBOX_SET          = 4;

  parameter
    AUTOBOX_X_START_LOW           = 0,
    AUTOBOX_X_START_HIGH          = 1,
    AUTOBOX_X_STOP_LOW            = 2,
    AUTOBOX_X_STOP_HIGH           = 3;


  logic       mpuRegisterWriteRequest;
  logic       mpuRegisterReadRequest;
  logic       mpuPixelWriteRequest;

  logic [8:0] mpuXCoord;
  logic [7:0] mpuYCoord;
  logic [7:0] mpuPixelColor;

  logic [2:0] pixelWriteRequestSync;
  logic       doWrite;


  always_comb begin
    mpuRegisterWriteRequest = mpuChipSelect && !mpuWriteEnable;
    mpuRegisterReadRequest = mpuChipSelect && mpuWriteEnable;

    mpuPixelWriteRequest = mpuRegisterWriteRequest && (mpuRegisterSelect == REGISTER_DATA);

    // if (reset) begin
    //   mpuRegisterReadRequest = 0;
    //   mpuDataBus = 8'bZ;
    // end else if (mpuRegisterReadRequest) begin
    //   case (mpuRegisterSelect)
    //     REGISTER_X_LOW  : mpuDataBus = mpuXCoord[7:0];
    //     REGISTER_X_HIGH : mpuDataBus = { 7'b0, mpuXCoord[8] };
    //     REGISTER_Y      : mpuDataBus = mpuYCoord;
    //     REGISTER_DATA   : mpuDataBus = mpuPixelColor;
    //     default         : mpuDataBus = 8'hff;
    //   endcase
    // end else begin
    //   mpuDataBus = 8'bZ;
    // end
  end

  always_ff @(negedge mpuRegisterWriteRequest or posedge reset) begin
    if (reset) begin
      mpuXCoord <= 0;
      mpuYCoord <= 0;
      mpuPixelColor <= 0;
    end else begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW  : mpuXCoord[7:0] <= mpuDataBus;
        REGISTER_X_HIGH : mpuXCoord[8] <= mpuDataBus[0];
        REGISTER_Y      : mpuYCoord <= mpuDataBus;
        REGISTER_DATA   : mpuPixelColor <= mpuDataBus;
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
      memoryXCoord <= 0;
      memoryYCoord <= 0;
      memoryWriteData <= 0;
    end else begin
      memoryXCoord <= mpuXCoord;
      memoryYCoord <= mpuYCoord;
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

  logic  [8:0]   videoXCoord;
  logic  [7:0]   videoYCoord;
	logic  [7:0]	 videoData;
	logic          videoDataReady;

  logic [8:0]    memoryXCoord;
  logic [7:0]    memoryYCoord;

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

		.memoryXCoord(memoryXCoord),
		.memoryYCoord(memoryYCoord),

		.memoryReadRequest(memoryReadRequest),
		.memoryWriteRequest(memoryWriteRequest),
		.memoryWriteData(memoryWriteData),

		.memoryReadData(memoryReadData),
		.memoryReadComplete(memoryReadComplete),
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