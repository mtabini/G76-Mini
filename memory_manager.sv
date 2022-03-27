module MemoryManager (
  input               reset,
  input               clock,
  output logic [2:0]  currentState,

  input  [8:0]        videoXCoord,
  input  [7:0]        videoYCoord,

  output logic [7:0]  videoData,
  output logic        videoDataReady,

  input  [8:0]        memoryXCoord,
  input  [7:0]        memoryYCoord,

  input               memoryReadRequest,
  input               memoryWriteRequest,
  input  [7:0]        memoryWriteData,  
  
  output logic [7:0]  memoryReadData,
  output logic        memoryReadComplete,
  output logic        memoryWriteComplete,

  output logic [16:0] ramAddress,
  inout [7:0]         ramData,

  output logic        ramOutputEnable,
  output logic        ramWriteEnable
);


  `include "clock_phases.sv"


  logic  [2:0]      nextState;


  assign ramData = ramWriteEnable ? 8'bZ : memoryWriteData;

  always_comb begin
    case (currentState)
        CLOCK_PHASE_IDLE:                                     nextState = CLOCK_PHASE_VIDEO_READ;

        CLOCK_PHASE_VIDEO_READ:       if (memoryWriteRequest) nextState = CLOCK_PHASE_MEM_WRITE;
                                 else if (memoryReadRequest)  nextState = CLOCK_PHASE_MEM_READ;
                                 else                         nextState = CLOCK_PHASE_NOP;

        CLOCK_PHASE_MEM_WRITE:                                nextState = CLOCK_PHASE_COMPLETE;
        CLOCK_PHASE_MEM_READ:                                 nextState = CLOCK_PHASE_COMPLETE;
        CLOCK_PHASE_NOP:                                      nextState = CLOCK_PHASE_COMPLETE;

        CLOCK_PHASE_COMPLETE:                                 nextState = CLOCK_PHASE_IDLE;
        
        default:                                              nextState = CLOCK_PHASE_IDLE;
    endcase
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      memoryWriteComplete <= 0;
    end else begin
      memoryWriteComplete <= memoryWriteRequest && (nextState == CLOCK_PHASE_COMPLETE);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      memoryReadComplete <= 0;
    end else begin
      memoryReadComplete <= memoryWriteRequest && (nextState == CLOCK_PHASE_COMPLETE);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      currentState <= 0;
    end else begin
      currentState <= nextState;
    end
  end

  always_ff @(posedge clock) begin
    case(nextState)
      CLOCK_PHASE_VIDEO_READ: ramAddress <= { videoYCoord, videoXCoord };
      CLOCK_PHASE_MEM_READ,   
      CLOCK_PHASE_MEM_WRITE:  ramAddress <= { memoryYCoord, memoryXCoord };
      default:                ramAddress <= 0;
    endcase
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      ramOutputEnable <= 1;
    end else begin
      ramOutputEnable <= ~(nextState == CLOCK_PHASE_VIDEO_READ || nextState == CLOCK_PHASE_MEM_READ);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      ramWriteEnable <= 1;
    end else begin
      ramWriteEnable <= ~(nextState == CLOCK_PHASE_MEM_WRITE);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      videoData <= 0;
      memoryReadData <= 0;
    end else begin
      case (currentState)
        CLOCK_PHASE_VIDEO_READ : videoData <= ramData;
        CLOCK_PHASE_MEM_READ   : memoryReadData <= ramData;
      endcase
    end    
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      videoDataReady <= 0;
    end else begin
      videoDataReady <= (currentState == CLOCK_PHASE_MEM_READ ||
                        currentState == CLOCK_PHASE_MEM_WRITE ||
                        currentState == CLOCK_PHASE_NOP);
    end
  end

endmodule


module MemoryManagerTB;

  logic             reset;
  logic             clock;
  logic  [2:0]      currentState;

  logic  [8:0]      videoXCoord;
  logic  [7:0]      videoYCoord;

  logic  [7:0]      videoData;
  logic             videoDataReady;

  logic  [8:0]      memoryXCoord;
  logic  [7:0]      memoryYCoord;

  logic             memoryReadRequest;
  logic             memoryWriteRequest;
  logic  [7:0]      memoryWriteData;  
  
  logic  [7:0]      memoryReadData;
  logic             memoryWriteComplete;
  logic             memoryReadComplete;

  logic  [16:0]     ramAddress;
  wire  [7:0]       ramData;

  logic             ramOutputEnable;
  logic             ramWriteEnable;

  MemoryManager memoryManagerDUT(
    .clock(clock),
    .reset(reset),
    .currentState(currentState),

    .videoXCoord(videoXCoord),
    .videoYCoord(videoYCoord),

    .videoData(videoData),
    .videoDataReady(videoDataReady),

    .memoryXCoord(memoryXCoord),
    .memoryYCoord(memoryYCoord),

    .memoryReadRequest(memoryReadRequest),
    .memoryWriteRequest(memoryWriteRequest),
    .memoryWriteData(memoryWriteData),

    .memoryReadData(memoryReadData),
    .memoryReadComplete(memoryReadComplete),
    .memoryWriteComplete(memoryWriteComplete),

    .ramAddress(ramAddress),
    .ramData(ramData),

    .ramOutputEnable(ramOutputEnable),
    .ramWriteEnable(ramWriteEnable)
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

	logic [8:0] xx;
	logic [7:0] yy;

	always_ff @(posedge clock) begin
    if (reset) begin
      memoryWriteRequest <= 0;
      memoryWriteData <= 0;
      xx <= 0;
      yy <= 0;
    end else begin
      if (memoryWriteRequest) begin
        memoryWriteRequest <= ~memoryWriteComplete;
      end else begin
        memoryWriteRequest <= 1;
        memoryXCoord <= xx;
        memoryYCoord <= yy;
        memoryWriteData <= xx[7:0];
        
        if (xx == 319) begin
          xx <= 0;
          yy <= yy == 239 ? 1'b0 : yy + 1'b1;
        end else
          xx <= xx + 1'b1;
      end
    end
	end
endmodule
