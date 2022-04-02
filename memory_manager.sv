module MemoryManager (
  input               reset,
  input               clock,

  input [16:0]        videoAddress,

  output logic [7:0]  videoData,
  output logic        videoDataReady,

  input  [16:0]       memoryAddress,

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

  parameter
    STATE_IDLE                = 0,
    STATE_VIDEO_READ          = 1,
    STATE_MEM_READ            = 2,
    STATE_MEM_WRITE           = 3,
    STATE_NOP                 = 4,
    STATE_COMPLETE            = 5;

  logic [2:0]   currentState;
  logic  [2:0]  nextState;
  logic         memoryWriteStarted;

  always_comb begin
    case (currentState)
        STATE_IDLE:                                         nextState = STATE_VIDEO_READ;

        STATE_VIDEO_READ:       if (memoryWriteRequest)     nextState = STATE_MEM_WRITE;
                                else if (memoryReadRequest) nextState = STATE_MEM_READ;
                                else                        nextState = STATE_NOP;

        STATE_MEM_WRITE:                                    nextState = STATE_COMPLETE;
        STATE_MEM_READ:                                     nextState = STATE_COMPLETE;
        STATE_NOP:                                          nextState = STATE_COMPLETE;

        STATE_COMPLETE:                                     nextState = STATE_IDLE;
        
        default:                                            nextState = STATE_IDLE;
    endcase
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      memoryWriteComplete <= 0;
      memoryWriteStarted <= 0;
    end else begin
      if (memoryWriteRequest && (nextState == STATE_MEM_WRITE)) begin
        memoryWriteStarted <= 1;
      end

      if (memoryWriteStarted && (nextState == STATE_COMPLETE)) begin
        memoryWriteComplete <= 1;
        memoryWriteStarted <= 0;
      end else begin
        memoryWriteComplete <= 0;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      memoryReadComplete <= 0;
    end else begin
      memoryReadComplete <= memoryReadRequest && (nextState == STATE_COMPLETE);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      currentState <= 0;
    end else begin
      currentState <= nextState;
    end
  end

  always_ff @(negedge clock) begin
    case(nextState)
      STATE_IDLE,
      STATE_VIDEO_READ : ramAddress <= videoAddress;
      STATE_MEM_READ,   
      STATE_MEM_WRITE  : ramAddress <= memoryAddress;
    endcase
  end

  assign ramData = (memoryWriteStarted || memoryWriteComplete) ? memoryWriteData : 8'bZ;

  always_ff @(posedge clock) begin
    if (reset) begin
      ramOutputEnable <= 1;
    end else begin
      ramOutputEnable <= ~(nextState == STATE_VIDEO_READ || nextState == STATE_MEM_READ);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      ramWriteEnable <= 1;
    end else begin
      ramWriteEnable <= ~(nextState == STATE_MEM_WRITE);
    end
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      videoData <= 0;
      memoryReadData <= 0;
    end else begin
      case (currentState)
        STATE_VIDEO_READ : videoData <= ramData;
        STATE_MEM_READ   : memoryReadData <= ramData;
      endcase
    end    
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      videoDataReady <= 0;
    end else begin
      videoDataReady <= (currentState == STATE_MEM_READ ||
                        currentState == STATE_MEM_WRITE ||
                        currentState == STATE_NOP);
    end
  end

endmodule
