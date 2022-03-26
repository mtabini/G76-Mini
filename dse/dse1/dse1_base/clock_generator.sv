module ClockGenerator(
  input               reset,
  input               clock,
  output logic [2:0]  clockPhase
);

  logic [2:0] nextPhase;

  always_ff @(posedge clock or posedge reset) begin
    if(reset) clockPhase <= '0;
    else      clockPhase <= nextPhase;
  end

  always_comb begin
    nextPhase = clockPhase + 1'b1;
  end

endmodule


module ClockGeneratorTB();
 
  logic         reset;
  logic         clock;
  logic [2:0]   clockPhase;

  ClockGenerator clockGenerator(
    .reset(reset),
    .clock(clock),
    .clockPhase(clockPhase)
  );


  initial begin
    clock = 0;
    reset = 0;
    #1 reset = 1;
    #1 reset = 0;
    forever #1 clock = ~clock;
  end

endmodule
