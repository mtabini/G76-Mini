module GFXClearScreen(
  input         reset,
  input         clock,
  input         enable,

  input [16:0]  memoryAddress,
  output [7:0]  memoryWriteData,
  output        memoryWriteRequest,
  input         memoryWriteComplete
);

  logic [8:0] xCoord;
  logic [7:0] yCoord;

  always @(posedge clock) begin
    if (reset) begin
      xCoord <= 0;
      yCoord <= 0;
    end else if (enable) begin
      if (xCoord == 319) begin
        xCoord <= 0;
        yCoord <= (yCoord == 239) ? 1'b0 : yCoord + 1'b1;
      end else begin
        xCoord <= xCoord + 1'b1;
      end
    end
  end

endmodule