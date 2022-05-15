module MPUInterface(
  input                 clock,
  input [2:0]           clockPhase,  

  input                 chipSelect,
  input                 writeEnable,
  
  input [2:0]           registerSelect,
  input [7:0]           registerData,

  input                 pendingWriteQueueReadRequest,
  output logic [24:0]   pendingWriteQueueReadBus,
  output logic          pendingWriteQueueReadEmpty
);

  parameter  REG_DATA         = 0;
  parameter  REG_X_COORD_LOW  = 1;
  parameter  REG_X_COORD_HIGH = 2;
  parameter  REG_Y_ADDR       = 3;

  logic [8:0]   xCoord;
  logic [7:0]   yCoord;

  logic [24:0]  pendingWriteQueueWriteBus;
  logic         pendingWriteQueueWriteRequest;

  logic         writePending;

  mpu_fifo pendingWriteQueue(
    .wrclk(chipSelect),
    .wrreq(pendingWriteQueueWriteRequest),
    .data(pendingWriteQueueWriteBus),

    .rdclk(clock),
    .rdreq(pendingWriteQueueReadRequest),
    .q(pendingWriteQueueReadBus),
    .rdempty(pendingWriteQueueReadEmpty)
  );

  logic[7:0] data;

  always @(posedge chipSelect) begin
    if (pendingWriteQueueWriteRequest) begin
      pendingWriteQueueWriteRequest <= 0;
    end else begin
      pendingWriteQueueWriteBus <= { yCoord, xCoord, data };
      pendingWriteQueueWriteRequest <= 1;
      
      if (xCoord == 319) begin
        xCoord <= 0;

        if (yCoord == 239) begin
          yCoord <= 0;
          data <= data + 1;
        end else begin
          yCoord <= yCoord + 1'b1;
        end
      end else begin
        xCoord <= xCoord + 1'b1;
      end
    end

    // pendingWriteQueueWriteRequest <= 0;

    // case(registerSelect)

    //   REG_DATA       : begin
    //     pendingWriteQueueWriteBus[7:0] <= registerData;
    //     pendingWriteQueueWriteRequest <= 1;
    //   end
      
    //   REG_X_COORD_LOW   : begin
    //     pendingWriteQueueWriteBus[24:17] <= registerData;
    //   end

    //   REG_X_COORD_HIGH  : begin
    //     pendingWriteQueueWriteBus[16] <= registerData[0];
    //   end

    //   REG_Y_ADDR        : begin
    //     pendingWriteQueueWriteBus[15:8] <= registerData[0];
    //     yCoord <= registerData;
    //   end
      
    // endcase
    
  end
  
endmodule

