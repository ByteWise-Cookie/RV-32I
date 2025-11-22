module ALU(
    input  logic [31:0] rs1,      
    input  logic [31:0] rs2,      
    input  logic [2:0]  funct3,    
    output logic [31:0] alu_out
);

    logic signed   [31:0] signed_rs1, signed_rs2;
    logic signed   [63:0] full_signed_mul, mixed_signed_mul;
    logic         [63:0]  full_unsigned_mul;

    assign signed_rs1 = rs1;
    assign signed_rs2 = rs2;
    assign full_signed_mul       = signed_rs1 * signed_rs2;
    assign mixed_signed_mul      = signed_rs1 * $signed({1'b0, rs2});
    assign full_unsigned_mul     = rs1 * rs2;

    always_comb begin
        alu_out = 32'b0;
        case (funct3)
            3'b000:  alu_out = full_signed_mul[31:0];         // MUL (lower 32 bits)
            3'b001:  alu_out = full_signed_mul[63:32];        // MULH (upper 32 bits)
            3'b010:  alu_out = mixed_signed_mul[63:32];       // MULHSU
            3'b011:  alu_out = full_unsigned_mul[63:32];      // MULHU

            3'b100:  // Signed division
                if (rs2 == 0)
                    alu_out = 32'hFFFFFFFF;                
                else if ((rs1 == 32'h8000_0000) && (rs2 == 32'hFFFF_FFFF))
                    alu_out = 32'h8000_0000;                  
                else
                    alu_out = $signed(rs1) / $signed(rs2);

            3'b101:  // Unsigned division
                if (rs2 == 0)
                    alu_out = 32'hFFFFFFFF;
                else
                    alu_out = rs1 / rs2;

            3'b110:  // Signed remainder
                if (rs2 == 0)
                    alu_out = rs1;
                else if ((rs1 == 32'h8000_0000) && (rs2 == 32'hFFFF_FFFF))
                    alu_out = 0;
                else
                    alu_out = $signed(rs1) % $signed(rs2);

            3'b111:  // Unsigned remainder
                if (rs2 == 0)
                    alu_out = rs1;
                else
                    alu_out = rs1 % rs2;

            default: alu_out = 32'b0;
        endcase
    end
endmodule
