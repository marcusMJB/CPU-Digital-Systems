
`timescale 1ns / 1ps

module ula_4bits_tb;
    // Entradas do DUT são declaradas como 'reg' no testbench para receberem valores
    reg  [3:0] a;
    reg  [3:0] b;
  	reg  signed [6:0] imm;
  	reg  [2:0] op;
    
    // Saídas do DUT são declaradas como 'wire' para serem monitoradas
  wire signed [7:0] resultado;

    // Instanciação da ULA
    module_alu dut (
      .valor1(a),
      .valor2(b),
      .imm(imm),
      .operacao(op),
      .resultado(resultado)
    );

    initial begin
        // 1. Configura a gravação das formas de onda
        $dumpfile("simulacao_ula.vcd");
        $dumpvars(0, ula_4bits_tb);

        // 2. Monitora mudanças no terminal em tempo real
      $monitor("Tempo=%0t ns | op=%b | a=%d (%b) | b=%d (%b) | imm=%d (%b) | res=%d (%b)", 
                 $time, op, a, a, b, b, imm, imm, resultado, resultado);

        // 3. Aplica os estímulos de teste
        a = 4'd3; b = 4'd6; imm = -11'sd23; op = 3'b001; // Testa Soma: 6 + 3 = 9
        #10 op = 3'b010;                  // Testa Subtração: 6 - 3 = 3
        #10 op = 3'b100;                  // Testa AND: 0110 & 0011 = 0010 (2)
        #10 op = 3'b101;                  // Testa XOR: 0110 ^ 0011 = 0101 (5)
      	#10 op = 3'b011;
        #10 a = 4'd5; b = 4'd5; imm = 11'd8; op = 2'b01; // Testa Flag Zero: 5 - 5 = 0 (zero deve ir para 1)
        #10 op = 3'b010;                  // Testa Subtração: 6 - 3 = 3
        #10 op = 3'b100;                  // Testa AND: 0110 & 0011 = 0010 (2)
        #10 op = 3'b101;                  // Testa XOR: 0110 ^ 0011 = 0101 (5)
      	#10 op = 3'b011;
      
        #10 $finish; // Encerra a simulação em 50ns
    end

endmodule