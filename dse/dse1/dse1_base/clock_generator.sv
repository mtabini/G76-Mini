module ClockGenerator(
  input               clock,
  output logic [2:0]  clockPhase
);

  logic [2:0] nextPhase;

  always_ff @(posedge clock) begin
    clockPhase <= nextPhase;
  end

  always_comb begin
    nextPhase = clockPhase + 1'b1;
  end

endmodule

