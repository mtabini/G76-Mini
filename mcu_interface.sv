module MCUInterface(
  input                 clock,

  output logic [16:0]   videoAddressOffset,
  output                videoHighResMode,

  output logic [16:0]   memoryWriteAddress,
  output logic          memoryWriteRequest,
  output logic [7:0]    memoryWriteData,

  input                 memoryWriteComplete,

  output logic [16:0]   memoryReadAddress,  
  input [7:0]           memoryReadData,

  input                 mpuChipSelect,
  input                 mpuWriteEnable,
  input  [2:0]          mpuRegisterSelect,
  inout  [7:0]          mpuDataBus
);


  parameter
    REGISTER_X_LOW        = 0,
    REGISTER_X_HIGH       = 1,
    REGISTER_Y            = 2,
    REGISTER_DATA         = 3,
    REGISTER_CONTROL      = 4,
    REGISTER_Y_OFFSET     = 5;

  parameter
    CONTROL_X_AUTOINCREMENT   = 0,
    CONTROL_HIGH_RES_MODE     = 1;


  logic        registerWriteRequest;
  logic        registerReadRequest;

  logic [7:0]   dataRegister;
  logic [1:0]   controlRegister;

  logic         pixelWriteRequest;
  logic [16:0]  pixelWriteAddress;
  logic [16:0]  pixelWriteAddressNext;

  logic         xIncrement;

  always_comb begin
    xIncrement = controlRegister[CONTROL_X_AUTOINCREMENT];
    videoHighResMode = controlRegister[CONTROL_HIGH_RES_MODE];
  end

  always_comb begin
    registerWriteRequest = mpuChipSelect && !mpuWriteEnable;
    registerReadRequest = mpuChipSelect && mpuWriteEnable;

    if (registerReadRequest) begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW    : mpuDataBus = pixelWriteAddress[7:0];
        REGISTER_X_HIGH   : mpuDataBus = pixelWriteAddress[8];
        REGISTER_Y        : mpuDataBus = pixelWriteAddress[16:9];
        REGISTER_DATA     : mpuDataBus = memoryReadData;
        REGISTER_CONTROL  : mpuDataBus = { 5'b00000 , controlRegister };
        REGISTER_Y_OFFSET : mpuDataBus = videoAddressOffset[16:9];
        default           : mpuDataBus = 8'hff;
      endcase
    end else begin
      mpuDataBus = 8'bz;
    end
  end

  always_comb begin
    memoryReadAddress = pixelWriteAddressNext;
  end

  always_ff @(posedge mpuChipSelect) begin
    if (registerWriteRequest) begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW    : begin
          pixelWriteAddressNext[7:0]  <= mpuDataBus;
        end
        REGISTER_X_HIGH   : begin
          pixelWriteAddressNext[8]    <= mpuDataBus[0];
        end
        REGISTER_Y        : begin
          pixelWriteAddressNext[16:9] <= mpuDataBus;
        end
        REGISTER_DATA     : begin
          dataRegister <= mpuDataBus;
          pixelWriteAddress <= pixelWriteAddressNext;
          pixelWriteRequest <= ~pixelWriteRequest;
        end
        REGISTER_CONTROL  : controlRegister             <= mpuDataBus[1:0];
        REGISTER_Y_OFFSET : videoAddressOffset          <= { mpuDataBus , 9'b0 };
      endcase
    end

    if (mpuRegisterSelect == REGISTER_DATA && xIncrement) begin
      pixelWriteAddressNext <= pixelWriteAddressNext + 1'b1;
    end
  end

  logic [2:0] pixelWriteRequestDelay;

  always_ff @(posedge clock) begin
    pixelWriteRequestDelay <= { pixelWriteRequestDelay[1:0] , pixelWriteRequest };

    if (memoryWriteRequest) begin
      memoryWriteRequest <= ~memoryWriteComplete;
    end else if (pixelWriteRequestDelay[2] != pixelWriteRequestDelay[1]) begin
      memoryWriteAddress <= pixelWriteAddress;
      memoryWriteData <= dataRegister;
      memoryWriteRequest <= 1;
    end
  end
endmodule
