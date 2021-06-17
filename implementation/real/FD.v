module FD(input wire C, input wire D, output reg Q);
  always @(posedge C) begin
    Q <= D;
  end
  //FDCE tfd(.C(C), .D(D), .Q(Q));
endmodule

