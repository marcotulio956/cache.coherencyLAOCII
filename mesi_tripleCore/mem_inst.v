module mem_inst (

	input clock,
	input reset,
	
	// Sinal de entrada que controla quando uma nova instrução poderá ser despachada
	input send,
	
	input done_p0, done_p1, done_p2,
	
	output reg[1:0] proc,
	output reg[1:0] opcode,
	output reg[3:0] tag,
	output reg[7:0] data
	
);

// Memória de Instruções - Matriz 5x16
reg[15:0] mem_inst[4:0];

// Contador
reg[2:0] counter;

// Instrução
// [15:14] -> Processador
// [13:12] -> Opcode
// [11:8]  -> Tag
// [7:0]   -> Dado

// Instruções
// Read  -> 00 
// Write -> 01

// Posições de Memória
// 10 -> 1010
// 11 -> 1011
// 12 -> 1100
// 13 -> 1101
// 14 -> 1110

// Processadores
// P0 -> 00
// P1 -> 01
// P2 -> 10

// Inicialização das variáveis
initial begin

	// Inicializando o Contador
	counter <= 0;
	
	// Inicializando a Memória de Instruções
	//mem_inst[0] <= 16'b0000101011111111; // P0: read 10
	//mem_inst[0] <= 16'b0101101000000010; // P1: write 10 <- 00 02
	mem_inst[0] <= 16'b0000101111111111; // P0: read 11
	mem_inst[0] <= 16'b0100110011111111; // P1: read 12
	mem_inst[1] <= 16'b0100101011111111; // P1: read 10
	mem_inst[2] <= 16'b0101101000000010; // P1: write 10 <- 00 02
	mem_inst[3] <= 16'b0001101000000111; // P0: write 10 <- 00 07
	mem_inst[4] <= 16'b1000110011111111; // P2: read 12
	
end


always @(posedge clock) begin
	
	if (reset == 1'b1 || counter > 3'b101) begin
		
		// Resetando as variáveis
		proc <= 2'b11;
		opcode <= 2'b11;
		tag <= 4'b1111;
		data <= 8'b11111111;
		
	end
	
	else if ((send == 1'b1) && (mem_inst[counter] != 16'b1111111111111111)) begin
		
		proc   <= mem_inst[counter][15:14];
		opcode <= mem_inst[counter][13:12];
		tag    <= mem_inst[counter][11:8];
		data   <= mem_inst[counter][7:0];
		
		// Incrementa o Contador
		counter <= counter + 1'b1;
		
	end
	
end



endmodule
