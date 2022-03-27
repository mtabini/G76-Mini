module MCUInterface(
  input           clock,

  output [8:0]    memoryXCoord,
  output [7:0]    memoryYCoord,

  output          memoryReadRequest,
  output          memoryWriteRequest,
  output [7:0]    memoryWriteData,  

  input  [7:0]    memoryReadData,
  input           memoryReadComplete,
  input           memoryWriteComplete,

  input           mpuChipSelect,
  input           mpuWriteEnable,
  input  [2:0]    mpuRegisterSelect,
  input  [7:0]    mpuData
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

  logic [8:0] xCoord;
  logic [7:0] yCoord;
  logic       memoryWriteRequestPending;

  logic [8:0] autoBoxXStart;
  logic [8:0] autoBoxXStop;

  logic       settingAutobox;
  logic [2:0] settingAutoboxIndex;
  logic       useAutobox;

  logic       registerRequestPending;


  always_comb begin
    memoryWriteRequestPending = (memoryWriteRequest && !memoryWriteComplete);
  end

  always_ff @(posedge clock) begin
    if (mpuChipSelect && !mpuWriteEnable) begin
      if (!registerRequestPending) begin
        registerRequestPending <= 1;
        
        case (mpuRegisterSelect)
          REGISTER_X_LOW        : xCoord[7:0] <= mpuData;
          REGISTER_X_HIGH       : xCoord[8] <= mpuData[0];
          REGISTER_Y            : yCoord <= mpuData;
          REGISTER_AUTOBOX_SET  : begin
            if (mpuData == 0) begin
              useAutobox <= 0;
            end else begin
              settingAutobox <= 1;
              settingAutoboxIndex <= 0;
              useAutobox <= 0;
            end
          end

          REGISTER_DATA   : begin
            if (settingAutobox) begin
              case (settingAutoboxIndex)
                AUTOBOX_X_START_LOW   : autoBoxXStart[7:0] <= mpuData;
                AUTOBOX_X_START_HIGH  : autoBoxXStart[8] <= mpuData[0];
                AUTOBOX_X_STOP_LOW    : autoBoxXStop[7:0] <= mpuData;
                AUTOBOX_X_STOP_HIGH   : begin
                  autoBoxXStop[8] <= mpuData[0];
                  settingAutobox <= 0;
                end
              endcase

              settingAutoboxIndex <= settingAutoboxIndex + 1'b1;
            end else begin
              if (!memoryWriteRequestPending) begin
                memoryXCoord <= xCoord;
                memoryYCoord <= yCoord;
                memoryWriteData <= mpuData;
                memoryWriteRequest <= 1;

                if (useAutobox) begin
                  if (xCoord == autoBoxXStop) begin
                    xCoord <= autoBoxXStart;
                    yCoord <= yCoord + 1'b1;
                  end else begin
                    xCoord <= xCoord + 1'b1;
                  end
                end
              end else begin
                memoryWriteRequest <= ~memoryWriteComplete;
              end
            end
          end
        endcase
      end
    end else begin
      registerRequestPending <= 0;
    end
  end

endmodule