// ---------------------------------------------------------------------------
// Módulo: lcd_controller
// Função: mostra no LCD 16x2 (HD44780) o resultado de cada instrução da Mini_CPU.
//
//   Linha 1: [nome da operação (10 col)] [ddd d]  -> "ADD       [0001]"
//   Linha 2: [10 espaços]               +NNNNN   -> "          +00012"
//
// Uso pela CPU:
//   - power  = 1 liga o display (inicializa e mostra tela inicial)
//   - power  = 0 apaga o display
//   - update = pulso de 1 ciclo (só com busy = 0), com op/dest/value válidos
//   - busy   = 1 enquanto o LCD está sendo escrito
//
// Depende de: lcd_init_hd44780
// Estilo: FSM com bloco sequencial / combinacional (próximo estado) / saídas.
// Valores de delay assumem clock de 50 MHz (DE2-115).
// ---------------------------------------------------------------------------

module lcd_controller (
    input  wire               clk,      //clock
    input  wire               rst,      // reset assíncrono, ativo em 1
    input  wire               power,    // 1 = sistema ligado
    input  wire               update,   // pulso: mostrar nova informação
    input  wire        [2:0]  op,       // opcode da instrução
    input  wire        [3:0]  dest,     // registrador (mostrado em binário)
    input  wire signed [15:0] value,    // valor com sinal

    output wire               busy, //se esta ocupado
    output wire        [7:0]  lcd_data, //transporta os 8 bits que serão enviados ao lcd
    output wire               lcd_rs, //define se comando ou caractere
    output wire               lcd_rw, //define leitura ou escrita
    output wire               lcd_e //enable
);

    // -----------------------------------------------------------------------
    // Temporizações (clock de 50 MHz = 20 ns)
    parameter [31:0] DELAY_SETUP = 32'd10;      // ~200 ns (RS/dados antes do E)
    parameter [31:0] DELAY_PULSE = 32'd50;      // ~1 us   (largura do E)
    parameter [31:0] DELAY_STD   = 32'd50_000;  // ~1 ms   (recomendado no projeto)
    parameter [31:0] DELAY_CLEAR = 32'd100_000; // ~2 ms   (Clear Display)

    localparam [2:0] OP_CLEAR = 3'b110; //criação da var do clear

    // -----------------------------------------------------------------------
    // Estados
    localparam [2:0]
        S_OFF       = 3'd0,  // desligado
        S_WAIT_INIT = 3'd1,  // lcd_init_hd44780 trabalhando
        S_IDLE      = 3'd2,  // pronto para receber update
        S_BCD       = 3'd3,  // binário -> decimal (16 ciclos)
        S_SETUP     = 3'd4,  // coloca RS/dados, E = 0
        S_PULSE     = 3'd5,  // E = 1
        S_WAIT      = 3'd6;  // espera o LCD processar

    // -----------------------------------------------------------------------
    // Declarações (tudo declarado ANTES de ser usado)
    reg [2:0]  state, next_state; //estado e proximo estado
    reg [31:0] delay_cnt, next_delay_cnt; //contador do delay e proximo contador de delay
    reg [5:0]  tx_idx, next_tx_idx;      // índice da transferência
    reg        job_off, next_job_off;    // sequência de desligar

    // Dados latcheados da instrução
    reg        is_init;                  // 1 = mostrando tela inicial
    reg [2:0]  op_r;
    reg [3:0]  dest_r;
    reg        neg;                      // negativo
    reg [15:0] sh;                       // magnitude (double dabble)
    reg [19:0] bcd;                      // 5 dígitos BCD
    reg [4:0]  bcd_cnt;                  // contador do bcd

    reg        init_rst_r;               // reset do módulo init (registrado)

    wire [7:0] init_data;
    wire       init_rs, init_rw, init_e, init_done;
    wire       start_init = (state == S_WAIT_INIT);
    wire       accept     = (state == S_IDLE) && power && update; //operacao aceita

    // -----------------------------------------------------------------------
    // Instância do módulo de inicialização
    lcd_init_hd44780 lcd_init (
        .clk      (clk),
        .rst      (init_rst_r),
        .start    (start_init),
        .done     (init_done),
        .lcd_data (init_data),
        .lcd_rs   (init_rs),
        .lcd_rw   (init_rw),
        .lcd_e    (init_e)
    );

    // -----------------------------------------------------------------------
    // Função: caractere da posição i (0..15 = linha 1, 16..31 = linha 2)
    function [7:0] get_char;
        input [4:0] i; //posicao do caractere
        input       init; //indica se esta mostrando a tela
        input [2:0] opc; //codigo da operacao
        input [3:0] dst; //reg de destino
        input       ng; //negativo?
        input [19:0] b; //resultado convertido
        reg  [79:0] name;   // 10 caracteres
        reg         name_only;
        begin
            if (init) name = "-----     ";
            else begin
                case (opc)
                    3'b000:  name = "LOAD      ";
                    3'b001:  name = "ADD       ";
                    3'b010:  name = "ADDI      ";
                    3'b011:  name = "SUB       ";
                    3'b100:  name = "SUBI      ";
                    3'b101:  name = "MUL       ";
                    3'b110:  name = "CLEAR     ";
                    default: name = "DPL       ";
                endcase
            end
            name_only = (!init && opc == OP_CLEAR);  // CLEAR: só o nome

            if (i < 10)
                get_char = name[(9 - i) * 8 +: 8];
            else if (i == 10)
                get_char = name_only ? " " : "[";
            else if (i <= 14)   // 11..14 : dest[3] .. dest[0]
                get_char = name_only ? " " : (init ? "-" : (dst[14 - i] ? "1" : "0"));
            else if (i == 15)
                get_char = name_only ? " " : "]";
            else if (i <= 25)   // 16..25 : espaços
                get_char = " ";
            else if (i == 26)
                get_char = name_only ? " " : (ng ? "-" : "+");
            else                // 27..31 : dígitos d4..d0
                get_char = name_only ? " " : (8'h30 + b[4 * (31 - i) +: 4]);
        end
    endfunction

    // Double dabble: soma 3 em cada dígito >= 5
    function [19:0] adj;
        input [19:0] b;
        integer k;
        begin
            for (k = 0; k < 5; k = k + 1)
                adj[4*k +: 4] = (b[4*k +: 4] >= 4'd5) ? (b[4*k +: 4] + 4'd3) : b[4*k +: 4];
        end
    endfunction

    // -----------------------------------------------------------------------
    // Byte atual da sequência de transmissão
    //   idx 0       : comando 0x80 (início da linha 1)
    //   idx 1..16   : caracteres 0..15
    //   idx 17      : comando 0xC0 (início da linha 2)
    //   idx 18..33  : caracteres 16..31
    //   (job_off)   : 0x01 (clear) e 0x08 (display off)
    // -----------------------------------------------------------------------
    reg [7:0] tx_byte; //byte que será enviado
    reg       tx_rs; //caractere ou comando
    reg       tx_last; //ultimo byte?

    always @(*) begin
        tx_byte = 8'h00;
        tx_rs   = 1'b0;
        tx_last = 1'b0;
        if (job_off) begin
            tx_byte = (tx_idx == 6'd0) ? 8'h01 : 8'h08; 
            tx_last = (tx_idx == 6'd1);
        end else begin
            if (tx_idx == 6'd0)
                tx_byte = 8'h80; //posicionando o cursor no começo da primeira linha (quando tx vale 0)
            
            else if (tx_idx <= 6'd16) begin //nas posições de 1 até 16, envia os 16 caracteres da primeira linha
                tx_byte = get_char(tx_idx - 6'd1, is_init, op_r, dest_r, neg, bcd);
                tx_rs   = 1'b1;
                
            end else if (tx_idx == 6'd17) 
                tx_byte = 8'hC0; //posicionando o cursor no começo da primeira linha (quando tx vale 17)
            
            else begin //nas posições de 18 até 33, envia os 16 caracteres da segunda linha
                tx_byte = get_char(tx_idx - 6'd2, is_init, op_r, dest_r, neg, bcd);
                tx_rs   = 1'b1;
                
            end
            tx_last = (tx_idx == 6'd33); //ultimo tx?
        end
    end

    // Delay depois do byte: Clear precisa de mais tempo
    wire [31:0] wait_delay = (job_off && tx_idx == 6'd0) ? DELAY_CLEAR : DELAY_STD;

    // =======================================================================
    // 1) BLOCO SEQUENCIAL: controle
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin //resetou?
            state      <= S_OFF;
            delay_cnt  <= 32'd0;
            tx_idx     <= 6'd0;
            job_off    <= 1'b0;
            init_rst_r <= 1'b1;
        end else begin //nao resetou?
            state      <= next_state;
            delay_cnt  <= next_delay_cnt;
            tx_idx     <= next_tx_idx;
            job_off    <= next_job_off;
            init_rst_r <= (next_state == S_OFF); // mantém o init em reset enquanto desligado
        end
    end

    // =======================================================================
    // 1b) BLOCO SEQUENCIAL: datapath (latch da instrução + BCD)
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin //resetou?
            is_init <= 1'b1;
            op_r    <= 3'd0;
            dest_r  <= 4'd0;
            neg     <= 1'b0;
            sh      <= 16'd0;
            bcd     <= 20'd0;
            bcd_cnt <= 5'd0;
            
        end else begin //nao resetou?
            if (state == S_OFF || state == S_WAIT_INIT) begin
                // prepara a tela inicial
                is_init <= 1'b1;
                op_r    <= 3'd0;
                dest_r  <= 4'd0;
                neg     <= 1'b0;
                bcd     <= 20'd0;
                
            end else if (accept) begin //nova operação foi aceita?
                is_init <= 1'b0;
                op_r    <= op;
                dest_r  <= dest;
                neg     <= value[15]; //guarda o sinal
                sh      <= value[15] ? (~value + 16'd1) : value;  // magnitude/valor absoluto (usando complementa 2)
                bcd     <= 20'd0;
                bcd_cnt <= 5'd0;
                
            end else if (state == S_BCD) begin
                {bcd, sh} <= {adj(bcd), sh} << 1; //junta os bits (bcd e sh), inplementa a funcao e desloca 1 bit
                bcd_cnt   <= bcd_cnt + 5'd1; //resultado da conversão
            end
        end
    end

    // =======================================================================
    // 2) BLOCO COMBINACIONAL: próximo estado / delay / índice
    
    always @(*) begin
        next_state     = state;
        next_delay_cnt = delay_cnt;
        next_tx_idx    = tx_idx;
        next_job_off   = job_off;

        case (state)
            S_OFF: begin
                if (power) next_state = S_WAIT_INIT;
            end

            S_WAIT_INIT: begin
                // Espera a inicialização terminar (~20 ms). Se o usuário desligou
                // nesse meio tempo, em vez da tela inicial já envia Clear + Display OFF.
                if (init_done) begin
                    next_job_off   = ~power;
                    next_tx_idx    = 6'd0;
                    next_delay_cnt = DELAY_SETUP;
                    next_state     = S_SETUP;
                end
            end

            S_IDLE: begin
                if (!power) begin
                    next_job_off   = 1'b1;      // Clear + Display OFF
                    next_tx_idx    = 6'd0;
                    next_delay_cnt = DELAY_SETUP;
                    next_state     = S_SETUP;
                end else if (update) begin
                    next_state = S_BCD;
                end
            end

            S_BCD: begin
                if (bcd_cnt == 5'd15) begin //acabou a conversão?
                    next_job_off   = 1'b0;
                    next_tx_idx    = 6'd0;
                    next_delay_cnt = DELAY_SETUP;
                    next_state     = S_SETUP;
                end
            end

            S_SETUP: begin
                if (delay_cnt > 0) next_delay_cnt = delay_cnt - 1;
                else begin
                    next_state     = S_PULSE;
                    next_delay_cnt = DELAY_PULSE;
                end
            end

            S_PULSE: begin
                if (delay_cnt > 0) next_delay_cnt = delay_cnt - 1;
                else begin
                    next_state     = S_WAIT;
                    next_delay_cnt = wait_delay;
                end
            end

            S_WAIT: begin
                if (delay_cnt > 0) next_delay_cnt = delay_cnt - 1;
                else begin
                    if (tx_last) begin
                        next_state = job_off ? S_OFF : S_IDLE;
                    end else begin
                        next_tx_idx    = tx_idx + 6'd1;
                        next_delay_cnt = DELAY_SETUP;
                        next_state     = S_SETUP;
                    end
                end
            end

            default: begin
                next_state     = S_OFF;
                next_delay_cnt = 32'd0;
                next_tx_idx    = 6'd0;
                next_job_off   = 1'b0;
            end
        endcase
    end

    // =======================================================================
    // 3) BLOCO COMBINACIONAL: saídas (Moore)
    
    reg [7:0] wr_data;
    reg       wr_rs;
    reg       wr_e;

    always @(*) begin
        wr_data = 8'h00; //byte
        wr_rs   = 1'b0; //comando ou caractere (dado)
        wr_e    = 1'b0; //enable (momento em que deve receber e processar o comando)
        
        case (state)
            S_SETUP, S_PULSE, S_WAIT: begin
                wr_data = tx_byte;
                wr_rs   = tx_rs;
                wr_e    = (state == S_PULSE);
            end
            default: ;
        endcase
    end

    // MUX: durante a inicialização quem manda é o lcd_init_hd44780
    wire sel_init = (state == S_WAIT_INIT);
    assign lcd_data = sel_init ? init_data : wr_data;
    assign lcd_rs   = sel_init ? init_rs   : wr_rs;
    assign lcd_rw   = sel_init ? init_rw   : 1'b0;
    assign lcd_e    = sel_init ? init_e    : wr_e;

    assign busy = (state != S_IDLE); //se nao esta no estado do IDLE, esta ocupado e nao deve receber novos dados

endmodule
