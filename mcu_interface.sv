module MCUInterface(
  input                 reset,
  input                 clock,

  output logic [8:0]    memoryXCoord,
  output logic [7:0]    memoryYCoord,

  output logic          memoryWriteRequest,
  output logic [7:0]    memoryWriteData,  

  input                 memoryWriteComplete,

  input                 mpuChipSelect,
  input                 mpuWriteEnable,
  input  [2:0]          mpuRegisterSelect,
  inout  [7:0]          mpuDataBus
);


  parameter
    REGISTER_X_LOW                = 0,
    REGISTER_X_HIGH               = 1,
    REGISTER_Y                    = 2,
    REGISTER_DATA                 = 3,
    REGISTER_AUTOBOX_SET          = 4;

  parameter
    AUTOBOX_SETUP_IDLE            = 0,
    AUTOBOX_SETUP_X_START_LOW     = 1,
    AUTOBOX_SETUP_X_START_HIGH    = 2,
    AUTOBOX_SETUP_X_STOP_LOW      = 3,
    AUTOBOX_SETUP_X_STOP_HIGH     = 4;


  logic       mpuRegisterWriteRequest;
  logic       mpuPixelWriteRequest;

  logic [8:0] mpuXCoord;
  logic [7:0] mpuYCoord;
  logic [7:0] mpuPixelColor;

  logic [8:0] mpuAutoboxXStart;
  logic [8:0] mpuAutoboxXStop;
  logic [2:0] mpuAutoboxSetupState;
  logic [2:0] mpuAutoboxSetupStateNext;
  logic       mpuAutoboxSetup;
  logic       mpuUseAutobox;
  logic       mpuUseAutoboxRequest;

  logic [2:0] pixelWriteRequestSync;
  logic       doWrite;
  logic [1:0] initializeAutobox;


  always_comb begin
    mpuUseAutoboxRequest = mpuDataBus[0];
    mpuAutoboxSetup = mpuAutoboxSetupState != AUTOBOX_SETUP_IDLE;

    mpuRegisterWriteRequest = mpuChipSelect && !mpuWriteEnable;
    mpuPixelWriteRequest = mpuRegisterWriteRequest && !mpuAutoboxSetup && (mpuRegisterSelect == REGISTER_DATA);

    case (mpuAutoboxSetupState)
      AUTOBOX_SETUP_IDLE          : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_IDLE;
      AUTOBOX_SETUP_X_START_LOW   : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_X_START_HIGH;
      AUTOBOX_SETUP_X_START_HIGH  : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_X_STOP_LOW;
      AUTOBOX_SETUP_X_STOP_LOW    : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_X_STOP_HIGH;
      AUTOBOX_SETUP_X_STOP_HIGH   : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_IDLE;
      default                     : mpuAutoboxSetupStateNext = AUTOBOX_SETUP_IDLE;
    endcase
  end

  always_ff @(negedge mpuRegisterWriteRequest or posedge reset) begin
    if (reset) begin
      mpuXCoord <= 0;
      mpuYCoord <= 0;
      mpuPixelColor <= 0;
    end else begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW        : mpuXCoord[7:0] <= mpuDataBus;
        REGISTER_X_HIGH       : mpuXCoord[8] <= mpuDataBus[0];
        REGISTER_Y            : mpuYCoord <= mpuDataBus;
        REGISTER_DATA         : begin
          initializeAutobox <= { initializeAutobox[0] , 1'b0 };

          if (mpuAutoboxSetup) begin
            case (mpuAutoboxSetupState) 
              AUTOBOX_SETUP_X_START_LOW   : mpuAutoboxXStart[7:0] <= mpuDataBus;
              AUTOBOX_SETUP_X_START_HIGH  : mpuAutoboxXStart[8] <= mpuDataBus[0];
              AUTOBOX_SETUP_X_STOP_LOW    : mpuAutoboxXStop[7:0] <= mpuDataBus;
              AUTOBOX_SETUP_X_STOP_HIGH   : begin
                mpuAutoboxXStop[8] <= mpuDataBus[0];

                mpuXCoord <= mpuAutoboxXStart;
                initializeAutobox <= 2'b01;
              end
            endcase

            mpuAutoboxSetupState <= mpuAutoboxSetupStateNext;
          end else begin
            mpuPixelColor <= mpuDataBus;            
          end
        end
        REGISTER_AUTOBOX_SET  : begin
          mpuUseAutobox <= mpuUseAutoboxRequest;

          if (mpuUseAutoboxRequest) begin
            mpuAutoboxSetupState <= AUTOBOX_SETUP_X_START_LOW;
          end
        end
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
      if (mpuUseAutobox) begin
        if (initializeAutobox) begin
          memoryXCoord <= mpuXCoord;
          memoryYCoord <= mpuYCoord;
        end else begin
          if (memoryXCoord >= mpuAutoboxXStop) begin
            memoryXCoord <= mpuAutoboxXStart;
            memoryYCoord <= memoryYCoord + 1'b1;
          end else begin
            memoryXCoord <= memoryXCoord + 1'b1;
          end
        end
      end else begin
        memoryXCoord <= mpuXCoord;
        memoryYCoord <= mpuYCoord;
      end

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