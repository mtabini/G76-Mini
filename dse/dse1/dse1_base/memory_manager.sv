module MemoryManager(
  input                 reset,
  input                 clock,
  input  [2:0]          clockPhase,

  input  [8:0]          readXCoord,
  input  [7:0]          readYCoord,
  output logic [7:0]    pixel1,
  output logic [7:0]    pixel2,

  input [24:0]          pendingWriteQueueReadBus,
  input                 pendingWriteQueueReadEmpty,
  output                pendingWriteQueueReadRequest,

  output logic [16:0]   address,
  inout  logic [7:0]    data,
  output logic          outputEnable,
  output logic          writeEnable
);


  logic [8:0]     nextXCoord;
  logic           writePending;

  always_comb begin
    nextXCoord = readXCoord + 1'b1;
    outputEnable = ~writeEnable;
  end

  always @(posedge clock) begin
      case(clockPhase)
        CLOCK_PHASE_SET_PIXEL_1: begin
          writeEnable <= 1;
          data <= 'Z;
          address <= {readYCoord, readXCoord};
        end

        CLOCK_PHASE_READ_PIXEL_1: pixel1 <= data;

        CLOCK_PHASE_SET_PIXEL_2: address <= {readYCoord, nextXCoord};

        CLOCK_PHASE_READ_PIXEL_2: begin
          pixel2 <= data;

          if (!pendingWriteQueueReadEmpty) begin
            pendingWriteQueueReadRequest <= 1;
            writePending <= 1;
          end
        end

        CLOCK_PHASE_READY_WRITE: begin
          if (writePending) begin
            { address, data } <= pendingWriteQueueReadBus;
            pendingWriteQueueReadRequest <= 0;
          end
        end

        CLOCK_PHASE_START_WRITE: begin
          if (writePending) begin
            writeEnable <= 0;
          end
        end

        CLOCK_PHASE_COMPLETE_WRITE: begin
          if (writePending) begin
            writeEnable <= 1;
            writePending <= 0;
          end

          address <= {readYCoord, nextXCoord};
        end
      endcase
  end

endmodule