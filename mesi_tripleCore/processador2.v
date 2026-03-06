module processador2(
	
	input clock,
	input reset,
	
	// Instrução
	input[1:0] proc,
	input[1:0] opcode,
	input[3:0] tag,
	input[7:0] data,
	
	// Dado dos outros processadores e da memória
	input[15:0] p0_block,
	input[15:0] p1_block,
	input[15:0] data_mem,
	input p0_has_block,
	input p1_has_block,
	
	// Entrada Bus
	// [15:14] -> Mensagem
	// [13:10] -> Tag
	input[15:0] bus_in,
	
	// Saída Bus
	// [15:14] -> Mensagem
	// [13:10] -> Tag
	output reg [15:0] bus_out,
	
	// Saída de dados do Processador
	output reg [15:0] proc_out,
	
	// Saída que indica write back
	output reg wb,
	
	// Saída que passa o bloco que sofrerá write back
	output reg [15:0] wb_block,
	
	// Saída que indica o fim da instrução
	output reg done,
	
	// Saídas para quando o processador for ouvinte
	output reg [15:0] p2_block,
	output reg p2_has_block

);

// Declarando i
integer i;

// Registrador para controle de Loop
reg break_loop;

// Cache L1 de P1
reg[15:0] CacheL1[4:0];

// Registrador para salvar posição da Cache - Emissor
reg [2:0] pos;

// Registrador para salvar posição da Cache - Ouvinte
reg [2:0] pos_o;

// Registrador para salvar estado da posição de cache acessada - Emissor
reg [1:0] state;

// Registrador para salvar estado da posição de cache acessada - Ouvinte
reg [1:0] state_o;

// Registrador para salvar última instrucao executada
reg [15:0] last_inst;

// Registrador para salvar a ocorrência de Read Miss e Write Miss
reg read_miss;
reg write_miss;

// Inicializar Variáveis
initial begin

	// Inicializando a Cache L1 de P2
	CacheL1[0] <= 16'b1011000000001011; // I | 11 | 00 11
	CacheL1[1] <= 16'b1100000000001100; // I | 12 | 00 12
	CacheL1[2] <= 16'b1101010000001101; // S | 13 | 00 13
	CacheL1[3] <= 16'b1110010000001110; // S | 14 | 00 14
	CacheL1[4] <= 16'b0000000000000000;
	
	// Inicializar demais variáveis
	done = 1'b0;
	pos = 3'b000;
	pos_o = 3'b000;
	bus_out = 16'b0000000000000000;
	proc_out = 16'b0000000000000000;
	last_inst = 16'b1111111111111111; // TODO
	read_miss = 1'b0;
	write_miss = 1'b0;
	wb = 1'b0;
	wb_block = 16'b0000000000000000;
	state = 2'b00;
	state_o = 2'b00;
	break_loop = 1'b0;
	p2_block = 16'b0000000000000000;
	p2_has_block = 1'b0;
	
end

always @(posedge clock) begin

// Processador 2 - Emissor - Esperando um dado devido a um Read Miss
if (read_miss && proc == 2'b10 && bus_in != 16'b0000000000000000 && data_mem != 16'b0000000000000000) begin

	case (state)

		// INVALID
		2'b00: begin
		
			// READ MISS SHARED
			if (p0_has_block == 1'b1 || p1_has_block == 1'b1) begin
			
				// Checar se P0 possui o bloco modificado
				if (p0_block != 16'b0000000000000000) begin
				
					// Nesse caso o processador emissor da instrução deve receber o bloco proveniente de outro processador
					CacheL1[pos] = p0_block;
					
				end
				
				// Checar se P2 possui o bloco modificado
				else if (p1_block != 16'b0000000000000000) begin
				
					// Nesse caso o processador emissor da instrução deve receber o bloco proveniente de outro processador
					CacheL1[pos] = p1_block;
					
				end
				
				// Caso nenhum dos outros processadores tenham o bloco modificado, buscar o bloco na memória
				else begin
					
					// Nesse caso o processador emissor da instrução deve receber o bloco proveniente da memória
					CacheL1[pos] = data_mem;
					
				end
				
				// Alterar o estado do bloco da cache para SHARED
				CacheL1[pos][11:10] = 2'b01;
				
				// Processador recebe o dado lido
				proc_out = CacheL1[pos][9:0];
				
				// Fim da instrução
				done = 1'b1;
				read_miss = 1'b0;
				
			end
			
			// READ MISS EXCLUSIVE
			if (p0_has_block != 1'b1 && p1_has_block != 1'b1) begin
			
				// Receber o bloco da memória
				CacheL1[pos] = data_mem;
				
				// Alterar o estado do bloco da cache para EXCLUSIVE
				CacheL1[pos][11:10] = 2'b10;
				
				// Processador recebe o dado lido
				proc_out = CacheL1[pos][9:0];
				
				// Fim da instrução
				done = 1'b1;
				read_miss = 1'b0;
				
			end
			
		end
		
		// SHARED OU EXCLUSIVE OU MODIFIED
		2'b01, 2'b10, 2'b11: begin
		
			// Checar se P0 possui o bloco modificado
			if (p0_block != 16'b0000000000000000) begin
			
				// Nesse caso o processador emissor da instrução deve receber o bloco proveniente de outro processador
				CacheL1[pos] = p0_block;

			end
				
			// Checar se P2 possui o bloco modificado
			else if (p1_block != 16'b0000000000000000) begin
				
				// Nesse caso o processador emissor da instrução deve receber o bloco proveniente de outro processador
				CacheL1[pos] = p1_block;
			
			end
			
			else begin
				
				// Receber o bloco da memória
				CacheL1[pos] = data_mem;
				
			end
			
			// Estado do bloco se mantém SHARED
			CacheL1[pos][11:10] = 2'b01;
			
			// Processador recebe o dado lido
			proc_out = CacheL1[pos][9:0];
				
			// Fim da instrução
			done = 1'b1;
			read_miss = 1'b0;
			
		end
		
	endcase

end

// Processador 2 - Emissor - Esperando um dado devido a um Write Miss
if (write_miss && proc == 2'b10 && bus_in != 16'b0000000000000000 && data_mem != 16'b0000000000000000) begin

	// Receber o bloco da memória
	CacheL1[pos] = data_mem;
	
	// Aleterar o estado do bloco para MODIFIED
	CacheL1[pos][11:10] = 2'b11;
	
	// Escrever dado no bloco
	CacheL1[pos][9:0] = data;
	
	// Fim da instrução
	done = 1'b1;
	write_miss = 1'b0;

end

// Checar se a instrução recebida é uma nova instrução
if ({proc,opcode,tag,data} != last_inst) begin
	
	// Resetar Variáveis
	done = 1'b0;
	wb = 1'b0;
	read_miss = 1'b0;
	write_miss = 1'b0;
	state = 2'b00;
	state_o = 2'b00;
	break_loop = 1'b0;
	pos = 3'b000;
	pos_o = 3'b000;
	p2_has_block = 1'b0;
	bus_out = 16'b0000000000000000;
	proc_out = 16'b0000000000000000;
	last_inst = 16'b0000000000000000;
	wb_block = 16'b0000000000000000;
	p2_block = 16'b0000000000000000;
	
end

// Processador 2 = Emissor
if (proc == 2'b10 /*P2*/ && done == 1'b0) begin
	
	// Salvar a posição da cache que será acessada
	if (tag == 4'b1010) begin
		pos = 3'b000;
	end
	else if (tag == 4'b1011) begin
		pos = 3'b001;
	end
	else if (tag == 4'b1100) begin
		pos = 3'b010;
	end
	else if (tag == 4'b1101) begin
		pos = 3'b011;
	end
	else if (tag == 4'b1110) begin
		pos = 3'b100;
	end
	
	// Salvar o estado da posição de cache acessada
	state = CacheL1[pos][11:10];
	
	// MESI - Emissor
	case (state)
		
		// INVALID
		2'b00: begin
		
			// READ MISS SHARED OU READ MISS EXCLUSIVE
			if (opcode == 2'b00) begin
			
				// Ativar sinal de Read Miss
				read_miss = 1'b1;
				
				// Escrever Read Miss no bus
				bus_out[15:14] = 2'b00;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
			// WRITE MISS
			if (opcode == 2'b01) begin
			
				// Ativar o sinal de Write Miss
				write_miss = 1'b1;
				
				// Escrever Write Miss no bus
				bus_out[15:14] = 2'b01;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
		end
		
		// SHARED
		2'b01: begin
			
			// READ HIT
			if (opcode == 2'b00 && tag == CacheL1[pos][15:12]) begin
				
				// Processador recebe o dado lido
				proc_out = CacheL1[pos][9:0];
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE HIT
			if (opcode == 2'b01 && tag == CacheL1[pos][15:12]) begin
				
				// Alterar o estado do bloco para modificado
				CacheL1[pos][11:10] = 2'b11;
				
				// Escrever o novo dado no bloco
				CacheL1[pos][9:0] = data;
				
				// Escrever invalidate no bus
				bus_out[15:14] = 2'b10;
				bus_out[13:10] = tag;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// READ MISS
			if (opcode == 2'b00 && tag != CacheL1[pos][15:12]) begin
				
				// Ativar sinal de Read Miss
				read_miss = 1'b1;
				
				// Escrever Read Miss no bus
				bus_out[15:14] = 2'b00;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
			// WRITE MISS
			if (opcode == 2'b01 && tag != CacheL1[pos][15:12]) begin
			
				// Ativar o sinal de Write Miss
				write_miss = 1'b1;
				
				// Escrever Write Miss no bus
				bus_out[15:14] = 2'b01;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
		end
		
		// EXCLUSIVE
		2'b10: begin
		
			// READ HIT
			if (opcode == 2'b00 && tag == CacheL1[pos][15:12]) begin
				
				// Processador recebe o dado lido
				proc_out = CacheL1[pos][9:0];
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE HIT
			if (opcode == 2'b01 && tag == CacheL1[pos][15:12]) begin
				
				// Alterar o estado do bloco para modificado
				CacheL1[pos][11:10] = 2'b11;
				
				// Escrever o novo dado no bloco
				CacheL1[pos][9:0] = data;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// READ MISS
			if (opcode == 2'b00 && tag != CacheL1[pos][15:12]) begin
				
				// Ativar sinal de Read Miss
				read_miss = 1'b1;
				
				// Escrever Read Miss no bus
				bus_out[15:14] = 2'b00;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
			// WRITE MISS
			if (opcode == 2'b01 && tag != CacheL1[pos][15:12]) begin
			
				// Ativar o sinal de Write Miss
				write_miss = 1'b1;
				
				// Escrever Write Miss no bus
				bus_out[15:14] = 2'b01;
				bus_out[13:10] = tag;
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
		end
		
		// MODIFIED
		2'b11: begin
			
			// READ HIT
			if (opcode == 2'b00 && tag == CacheL1[pos][15:12]) begin
				
				// Processador recebe o dado lido
				proc_out = CacheL1[pos][9:0];
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE HIT
			if (opcode == 2'b01 && tag == CacheL1[pos][15:12]) begin
				
				// Escrever o novo dado no bloco
				CacheL1[pos][9:0] = data;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// READ MISS
			if (opcode == 2'b00 && tag != CacheL1[pos][15:12]) begin
				
				// Ativar sinal de Read Miss
				read_miss = 1'b1;
				
				// Escrever Read Miss no bus
				bus_out[15:14] = 2'b00;
				bus_out[13:10] = tag;
				
				// Faz write back do bloco modificado
				wb = 1'b1;
				wb_block = CacheL1[pos];
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
			// WRITE MISS
			if (opcode == 2'b01 && tag != CacheL1[pos][15:12]) begin
			
				// Ativar o sinal de Write Miss
				write_miss = 1'b1;
				
				// Escrever Write Miss no bus
				bus_out[15:14] = 2'b01;
				bus_out[13:10] = tag;
				
				// Faz write back do bloco modificado
				wb = 1'b1;
				wb_block = CacheL1[pos];
				
				// A cache não será alterada nesse if pois é necessário buscar o bloco em outro processador ou na memória
				
			end
			
		end
		
	endcase
	
end

// Processador 2 = Ouvinte
else if (proc != 2'b10 /*P2*/ && done == 1'b0  && bus_in != 16'b0000000000000000) begin
	
	// Checar se a tag emissora da instrução está presente neste processador
	for(i = 0 ; i <= 4 && break_loop != 1 ; i = i + 1) begin
	
		if (CacheL1[i][15:12] == bus_in[13:10]) begin
			
			// Salvar o estado do bloco que contém a tag emissora (Bloco Ouvinte)
			state_o = CacheL1[i][11:10];
			
			// Salvar a posicao do bloco que contém a tag emissora (Bloco Ouvinte)
			pos_o = i;
			
			// Sair do loop
			break_loop = 1'b1;
			
		end
		
	end
	
	// MESI - OUVINTE
	case (state_o)
	
		// INVALID
		2'b00: begin
			
			// Fim da instrução
			done = 1'b1;
		
		end
		
		// SHARED
		2'b01: begin
		
			// READ MISS
			if (bus_in[15:14] == 2'b00) begin
				
				// O estado se mantém SHARED
				
				// Avisar para os demais processadores que este processador possui o bloco
				p2_has_block = 1'b1;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE MISS
			if (bus_in[15:14] == 2'b01) begin
			
				// O estado é alterado para INVALID
				CacheL1[pos_o][11:10] = 2'b00;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// INVALIDATE
			if (bus_in[15:14] == 2'b10) begin
			
				// O estado é alterado para INVALID
				CacheL1[pos_o][11:10] = 2'b00;
			
				// Fim da instrução
				done = 1'b1;
				
			end
			
		end
		
		// EXCLUSIVE
		2'b10: begin
		
			// READ MISS
			if (bus_in[15:14] == 2'b00) begin
				
				// O estado é alterado para SHARED
				CacheL1[pos_o][11:10] = 2'b01;
				
				// Avisar para os demais processadores que este processador possui o bloco
				p2_has_block = 1'b1;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE MISS
			if (bus_in[15:14] == 2'b01) begin
			
				// O estado é alterado para INVALID
				CacheL1[pos_o][11:10] = 2'b00;
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// INVALIDATE
			if (bus_in[15:14] == 2'b10) begin
			
				// O estado é alterado para INVALID
				CacheL1[pos_o][11:10] = 2'b00;
				
				// Fim da instrução
				done = 1'b1;

			end
			
		end
		
		// MODIFIED
		2'b11: begin
		
			// READ MISS
			if (bus_in[15:14] == 2'b00) begin
			
				// O estado é alterado para SHARED
				CacheL1[pos_o][11:10] = 2'b01;
				
				// Avisar para os demais processadores que este processador possui o bloco
				p2_has_block = 1'b1;
				
				// Passar o bloco modificado para o processador que está solicitando
				p2_block = CacheL1[pos_o];
				
				// Faz write back do bloco modificado
				wb = 1'b1;
				wb_block = CacheL1[pos_o];
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
			// WRITE MISS
			if (bus_in[15:14] == 2'b01) begin
			
				// Passar o bloco modificado para o processador que está solicitando
				p2_block = CacheL1[pos_o];
			
				// O estado é alterado para INVALID
				CacheL1[pos_o][11:10] = 2'b00;
				
				// Faz write back do bloco modificado
				wb = 1'b1;
				wb_block = CacheL1[pos_o];
				
				// Fim da instrução
				done = 1'b1;
				
			end
			
		end
	
	endcase

end

// Salvar última instrução executada
last_inst = {proc,opcode,tag,data};

end

endmodule
