`define hdl_path_regf c.regs

module testbench;

  reg clk;
  reg resetn;
  wire trap;
  reg [7:0] cnt;

  twitchcore c (
    .clk (clk),
    .resetn (resetn),
    .trap (trap)
  );

  initial begin
    string firmware;
    clk = 0;
    cnt = 0;
    // put core to reset while initializing ram
    resetn = 0;

    $display("programming the mem");
    if ($value$plusargs("firmware=%s", firmware)) begin
        $display($sformatf("Using %s as firmware", firmware));
    end else begin
        $display($sformatf("Expecting a command line argument %s", firmware), "ERROR");
        $finish;
    end
    $readmemh(firmware, c.r.mem);

    $display("doing work", cnt);
    @(posedge clk);
    resetn = 1;
  end

  always
    #5 clk = !clk;

  always @(posedge clk) begin
    cnt <= cnt + 1;
    resetn <= 0;
  end



  always @(posedge clk) begin
    if (c.step[6] == 1'b1) begin
      $display("%b: %h %d pc:%h -- opcode:%b -- func:%h alt:%d left:%h imm:%h pend:%h d_addr:%h d_data:%h trap:%d",
        c.step, c.i_data, c.resetn, c.pc, c.opcode, c.alu_func, c.alu_alt, c.alu_left, c.alu_imm, c.pend, c.d_addr, c.d_data, c.trap);
    end
  end

  always @(posedge trap) begin
    $display("TRAP", c.regs[3]);
    $finish;
  end

  initial begin
    int char_0, char_1, char_2, char_3;
    $dumpfile("waves.vcd");
    $dumpvars(0,testbench);
    #50000
    $display("no more work ", cnt);
    // At the end of risc-v test, we should see OK\n or
    // Err\n in registers a0-a3 ()
    char_0 = `hdl_path_regf[10];
    char_1 = `hdl_path_regf[11];
    char_2 = `hdl_path_regf[12];
    char_3 = `hdl_path_regf[13];
    $display($sformatf("RISC-V TEST Result: %s%s%s%s", char_0, char_1, char_2, char_3));
    $finish;
  end
endmodule

