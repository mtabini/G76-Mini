module MemoryManager (
  input               clock,

  input        [16:0] videoAddress,
  input        [16:0] videoAddressOffset,

  output logic  [7:0] videoData,
  output logic        videoDataReady,

  input        [16:0] memoryAddress,

  input               memoryReadRequest,
  input               memoryWriteRequest,
  input         [7:0] memoryWriteData,  
  
  output logic  [7:0] memoryReadData,
  output logic        memoryReadComplete,
  output logic        memoryWriteComplete,

  output logic [16:0] ramAddress,
  inout         [7:0] ramData,

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
  logic [2:0]   nextState;
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

  always_ff @(posedge clock) begin
    memoryReadComplete <= memoryReadRequest && (nextState == STATE_COMPLETE);
  end

  always_ff @(posedge clock) begin
    currentState <= nextState;
  end

  always_ff @(negedge clock) begin
    case(nextState)
      STATE_IDLE,
      STATE_VIDEO_READ : ramAddress <= videoAddress + videoAddressOffset;
      STATE_MEM_READ,   
      STATE_MEM_WRITE  : ramAddress <= memoryAddress + videoAddressOffset;
    endcase
  end

  assign ramData = (memoryWriteStarted || memoryWriteComplete) ? memoryWriteData : 8'bZ;

  always_ff @(posedge clock) begin
    ramOutputEnable <= ~(nextState == STATE_VIDEO_READ || nextState == STATE_MEM_READ);
  end

  always_ff @(posedge clock) begin
    ramWriteEnable <= ~(nextState == STATE_MEM_WRITE);
  end

  always_ff @(posedge clock) begin
    case (currentState)
      STATE_VIDEO_READ : videoData <= ramData;
      STATE_MEM_READ   : memoryReadData <= ramData;
    endcase
  end

  always_ff @(posedge clock) begin
    videoDataReady <= (currentState == STATE_MEM_READ ||
                      currentState == STATE_MEM_WRITE ||
                      currentState == STATE_NOP);
  end

endmodule
