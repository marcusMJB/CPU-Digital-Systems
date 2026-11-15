module module_alu(
  input wire [3:0] valor1,
  input wire [3:0] valor2,
  input wire signed [6:0] imm,
  input wire [2:0] operacao,
  output reg signed [10:0] resultado
);
  localparam ADD = 3'b001,
  			 ADDI = 3'b010,
  			 SUB = 3'b011,
  			 SUBI = 3'b100,
  			 MULT =3'b101;
  
  always @* begin
    case (operacao)
      ADD: resultado = valor1 + valor2;
      ADDI: resultado = $signed({1'b0, valor1}) + imm;
      SUB: resultado = valor1;
      SUBI: resultado = $signed({1'b0, valor1}) - imm;
      MULT: resultado = $signed({1'b0, valor1}) * imm;
      default: resultado = 11'd0;
    endcase
  end

endmodule
