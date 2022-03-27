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
    REGISTER_DATA                 = 3;


  logic [8:0] xCoord;
  logic [7:0] yCoord;
  logic       memoryWriteRequestPending;

  always_comb begin
    memoryWriteRequestPending = (memoryWriteRequest && !memoryWriteComplete);
  end

  always_ff @(posedge clock) begin
    if (mpuChipSelect && !mpuWriteEnable) begin
      case (mpuRegisterSelect)
        REGISTER_X_LOW  : xCoord[7:0] <= mpuData;
        REGISTER_X_HIGH : xCoord[8] <= mpuData[0];
        REGISTER_Y      : yCoord <= mpuData;
        REGISTER_DATA   : begin
          if (!memoryWriteRequestPending) begin
            memoryXCoord <= xCoord;
            memoryYCoord <= yCoord;
            memoryWriteData <= mpuData;
            memoryWriteRequest <= 1;
          end else begin
            memoryWriteRequest <= ~memoryWriteComplete;
          end
        end
      endcase
    end
  end

  // always_ff @(posedge clock) begin
  //   if (memoryWriteRequest) begin
  //     memoryWriteRequest <= ~memoryWriteComplete;
  //   end else begin
  //     if (mpuChipSelect && !mpuWriteEnable) begin
  //       case (mpuRegisterSelect)
  //         REGISTER_X_LOW  : xCoord[7:0] <= mpuData;
  //         REGISTER_X_HIGH : xCoord[8] <= mpuData[0];
  //         REGISTER_Y      : yCoord <= mpuData;
  //         REGISTER_DATA   : begin
  //           memoryXCoord <= xCoord;
  //           memoryYCoord <= yCoord;
  //           memoryWriteData <= mpuData;
  //           memoryWriteRequest <= 1;
  //         end
  //       endcase
  //     end
  //   end
  // end

endmodule