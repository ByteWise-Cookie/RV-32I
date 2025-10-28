`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 07:05:20 PM
// Design Name: 
// Module Name: _ALU_ctl
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


module _ALU_ctl(
  input logic [2:0] fun3,
  input logic [6:0] fun7,
  output logic [3:0] alu_ctl,
  output logic carry,
  output logic [1:0] comparator_clt
  );

typedef enum logic [2:0] {
  S_IDLE,
  S_AND,
  S_OR,
  S_ADD,
  S_SUB
} state_t;

state_t state, next_state;

always_comb begin
  next_state = S_IDLE;
  case (fun3)
    3'b111: next_state = S_AND;
    3'b110: next_state = S_OR;
    3'b000: begin
      if (fun7 == 7'b0000000)
        next_state = S_ADD;
      else if (fun7 == 7'b0100000)
        next_state = S_SUB;
      else
        next_state = S_IDLE;
    end
    default: next_state = S_IDLE;
  endcase
end

always_ff @(posedge fun3[0]) begin
  state <= next_state;
end

always_comb begin
  alu_ctl = 4'b0000;
  carry = 1'b0;
  comparator_clt = 2'b00;

  case (state)
    S_AND: alu_ctl = 4'b0000;
    S_OR:  alu_ctl = 4'b0001;
    S_ADD: alu_ctl = 4'b0010;
    S_SUB: begin
      alu_ctl = 4'b0011;
      carry = 1'b1;
    end
    default: alu_ctl = 4'b0000;
  endcase
end


/*
  always_comb begin
casex(fun3)
  3'b000: begin
    alu_ctl[1:0] = 2'b00; end

  3'b110: begin
    alu_ctl[1:0] = 2'b01; end

  3'b111: begin 
    alu_ctl = 2'b10; end
end
// alu_ctl[1:0] -> decoder
// alu_ctl[2] -> adder input MUX_sel (0 -> addtion, 1 -> subraction), carry
// alu_clt[3] -> select adder_result / comprarator_out

//output_buffer[2] selection MUX id10 = adder_result, id1 = comparator result


//COMPARATOR, FLAGS
/*
diff = rs1 - rs2
rs1 == rs2 : (diff == 0)
rs1 < rs2  : (diff[31] == 1)                   // signed less than
rs1 > rs2  : (diff[31] == 0 && diff != 0)
rs1 < rs2 (unsigned) : carry == 0
rs1 > rs2 (unsigned) : carry == 1 && diff != 0
*/
/*case(alu_ctl[1:0])
2'b00: result = output_buffer[0]; // result = AND op1, op2
2'b01: result = output_buffer[1]; // result = OR op1, op2
2'b10: result = output_buffer[2]; // result = ADD op1, adder_sel
2'b11: result = output_buffer[3]; // result = shifters


endcase
*/


endmodule

