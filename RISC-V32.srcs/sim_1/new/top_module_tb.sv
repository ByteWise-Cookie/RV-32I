`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2025 05:20:39 PM
// Design Name: 
// Module Name: top_module_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module_tb;

  logic clk, reset;
  logic [31:0] instru, mem_data_in;
  logic [31:0] PC_instru_addr_out, mem_addr_out, mem_data_out;

  integer vectornum, errors;
  logic [127:0] testvectors [0:1023]; // each line from .tv file (adjust size)

  // Instantiate DUT
  top_module dut (
    .clk(clk),
    .master_reset(reset),
    .instru(instru),
    .mem_data_in(mem_data_in),
    .PC_instru_addr_out(PC_instru_addr_out),
    .mem_addr_out(mem_addr_out),
    .mem_data_out(mem_data_out)
  );

  // Clock generation
  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  // Initialization: load file, set reset
  initial begin
    $readmemb("", testvectors); // file must be in binary form
    vectornum = 0; 
    errors = 0;
    reset = 1;
    #20 reset = 0;
  end

  // Apply test vectors
  always @(posedge clk) begin
    if (!reset) begin
      {PC_instru_addr_out, mem_addr_out, mem_data_out, instru, mem_data_in} = testvectors[vectornum];
    end
  end

  // Optional checking (depends on what your DUT outputs)
  always @(negedge clk) begin
    if (!reset) begin
      // Add checks here like:
      // if (dut.output_signal !== expected_value) begin
      //   $display("Mismatch at vector %0d", vectornum);
      //   errors = errors + 1;
      // end
      vectornum++;
      if (testvectors[vectornum] === 'x) begin
        $display("Simulation complete. %0d errors.", errors);
        $finish;
      end
    end
  end

endmodule

