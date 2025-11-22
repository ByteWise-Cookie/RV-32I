`timescale 1ns/1ps
module tb_ALU;

    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [2:0]  funct3;
    logic [31:0] alu_out;

    // Instantiate the ALU
    ALU uut (
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .alu_out(alu_out)
    );

    initial begin
        // Test MUL
        rs1 = 10;
        rs2 = 15;
        funct3 = 3'b000; // MUL lower bits
        #20;

        // Test MULH
        rs1 = 100000;
        rs2 = 100000;
        funct3 = 3'b001; // MUL upper bits
        #20;

        // Test DIV
        rs1 = 50;
        rs2 = 5;
        funct3 = 3'b100; // Signed divide
        #20;

        // Test REM
        rs1 = 50;
        rs2 = 7;
        funct3 = 3'b110; // Signed remainder
        #20;

        // Test divide by zero case
        rs1 = 50;
        rs2 = 0;
        funct3 = 3'b100; // DIV by zero
        #20;

        // Test default case (should output 0)
        rs1 = 0;
        rs2 = 0;
        funct3 = 3'b111; // REMU (unsigned remainder)
        #20;

        $stop; // stop simulation
    end

endmodule
