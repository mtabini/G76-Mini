module MCUInterface(
  input                 reset,
  input                 clock,

  output logic [16:0]   videoAddressOffset,
  output                videoHighResMode,

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
    REGISTER_X_LOW        = 0,
    REGISTER_X_HIGH       = 1,
    REGISTER_Y            = 2,
    REGISTER_DATA         = 3,
    REGISTER_CONTROL      = 4,
    REGISTER_Y_OFFSET     = 5;

  parameter
    CONTROL_X_AUTOINCREMENT   = 0,
    CONTROL_HIGH_RES_MODE     = 1;


  logic        mpuRegisterWriteRequest;
  logic [1:0]  mpuRegisterWriteRequestDelay;
  logic        mpuPixelWriteRequest;
  logic        mpuXIncrement;

  logic [16:0] mpuAddress;
  logic [16:0] mpuAddressNext;
  logic [7:0]  mpuPixelColor;
  logic [7:0]  mpuControl;

  logic [2:0] pixelWriteRequestSync;
  logic       pixelWritePending;


  always_comb begin
    mpuRegisterWriteRequest = mpuChipSelect && !mpuWriteEnable;
    mpuPixelWriteRequest = mpuRegisterWriteRequestDelay[1] && (mpuRegisterSelect == REGISTER_DATA);
    mpuXIncrement = mpuControl[CONTROL_X_AUTOINCREMENT];
    videoHighResMode = mpuControl[CONTROL_HIGH_RES_MODE];
  end

  always_ff @(posedge clock) begin
    mpuRegisterWriteRequestDelay <= { mpuRegisterWriteRequestDelay[0], mpuRegisterWriteRequest };

    if (reset) begin
      mpuAddress <= 0;
      mpuPixelColor <= 0;
    end else if (mpuRegisterWriteRequestDelay == 2'b10) begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW        : mpuAddressNext[7:0] <= mpuDataBus;
        REGISTER_X_HIGH       : mpuAddressNext[8] <= mpuDataBus[0];
        REGISTER_Y            : mpuAddressNext[16:9] <= mpuDataBus;
        REGISTER_DATA         : begin
          mpuPixelColor <= mpuDataBus;
          mpuAddress <= mpuAddressNext;

          if (mpuXIncrement) begin
            mpuAddressNext <= mpuAddressNext + 1'b1;
          end
        end
        REGISTER_CONTROL      : mpuControl <= mpuDataBus;
        REGISTER_Y_OFFSET     : videoAddressOffset <= mpuDataBus * 512;
      endcase
    end
  end

  always_ff @(posedge clock) begin
    pixelWriteRequestSync <= { pixelWriteRequestSync[1:0], mpuPixelWriteRequest };
  end

  always_comb begin
    if (reset) begin
      pixelWritePending = 0;
    end else begin
      pixelWritePending = pixelWriteRequestSync[2:1] == 2'b10;
    end
  end

  always_ff @(posedge pixelWritePending or posedge reset) begin
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
      if (pixelWritePending) begin
        memoryWriteRequest <= 1;
      end
    end else begin
      memoryWriteRequest <= ~memoryWriteComplete;
    end
  end
endmodule
