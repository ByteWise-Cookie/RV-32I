`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 12:48:17 AM
// Design Name: 
// Module Name: _32b_ALU
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


module _32b_ALU(
input logic [31:0] op1, op2,
input logic [3:0] alu_ctl,
output logic [31:0] result,
output logic zero_flag,
input logic [0:2] comparator_clt
);

logic [31:0] output_buffer [3:0];
logic [31:0] adder_src [1:0];
logic [31:0] adder_buffer, xor_out;
logic [31:0] adder_result;
logic adder_carry;
logic gnd;
logic [31:0] comprarator_out;

//INVERTER
assign adder_src[0] = op2;
assign adder_src[1] = ~op2;


// alu_ctl[1:0] -> decoder
// alu_ctl[2] -> adder input MUX_sel (0 -> addtion, 1 -> subraction), carry
// alu_clt[3] -> select adder_result / comprarator_out

_2o1_MUX adder_src_mux(.s(alu_ctl[2]), .id0(adder_src[0]), .id1(adder_src[1]), .od(adder_buffer));

//output_buffer[2] selection MUX id10 = adder_result, id1 = comparator result
_2o1_MUX output_buffer2_src(.s(alu_ctl[3]), .id0(adder_result), .id1(comprarator_out), .od(adder_buffer));

// XOR

always_comb begin 
xor_out = op1 ^ op2;
end

// AND

// OR 
always_comb begin 
if(comparator_clt == 2'b11) begin 
    output_buffer[0] = op1 ^ op2;
    end
else begin 

output_buffer[0] = op1 & op2;

end
end 

// ADD
_32b_ADDER _ALU_adder(.op1(op1), .op2(adder_buffer), .cin(alu_ctl[2]), .carry(gnd), .sum(adder_result));

//SHIFTERS
always_comb begin
case(alu_ctl[3:2]) // alu_ctl[1:0] controls output MUX *line 67 (do not use those bits)

2'b00: output_buffer[3] = op1 << op2[4:0]; //left logical, MUX_sel = 00
2'b01: output_buffer[3] = op1 >> op2[4:0]; //right logical, MUX_sel = 01
2'b10: output_buffer[3] = op1 >>> op2[4:0]; //right arithmetic, MUX_sel = 10
2'b11: output_buffer[3] = op1;

endcase
end



//COMPARATOR, FLAGS
/*
diff = rs1 - rs2
rs1 == rs2 : (diff == 0)
rs1 < rs2  : (diff[31] == 1)                   // signed less than
rs1 > rs2  : (diff[31] == 0 && diff != 0)
rs1 < rs2 (unsigned) : carry == 0
rs1 > rs2 (unsigned) : carry == 1 && diff != 0
*/

always_comb begin

case(adder_result)

  32'b0: begin comprarator_out = 0; zero_flag = 1;  end //rs1 == rs2

  default:
  begin
  if (adder_result[31] == 1'b1&& comparator_clt == 2'b00) 
    begin  
        comprarator_out = 1;
        zero_flag = 1;
    end// rs1 < rs2 

  else if (adder_result[31] != 1'b0 && comparator_clt == 2'b01) begin 
      comprarator_out = 0;
      zero_flag = 1;
  end //rs1 > rs2 

  else if (~adder_carry && comparator_clt == 2'b10) begin 
      comprarator_out = 1;
      zero_flag = 1;
  end // rs1 < rs2 (unsigned)

  else if (adder_carry && comparator_clt == 2'b11) begin 
      comprarator_out = 0;
      zero_flag = 1;
  end // rs1 > rs2 (unsigned)
  end

endcase

end 


// OUTPUT MUX

always_comb begin 

case(alu_ctl[1:0])
2'b00: result = output_buffer[0]; // result = AND op1, op2
2'b01: result = output_buffer[1]; // result = OR op1, op2
2'b10: result = output_buffer[2]; // result = ADD op1, adder_sel
2'b11: result = output_buffer[3]; // result = shifters


endcase
end

endmodule
