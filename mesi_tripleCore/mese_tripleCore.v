module mesi (
	
	input clock,
	input reset
	
	// Dado retornado pelo processador
	// output [15:0] proc0_out, proc1_out, proc2_out
	
);

// Cache
// [15:12] -> Tag
// [11:10] -> Estado
// [9:0]   -> Dado

// Posições de Memória
// 10 -> 1010
// 11 -> 1011
// 12 -> 1100
// 13 -> 1101
// 14 -> 1110

// Estados
// I -> 00 (0)
// S -> 01 (1)
// E -> 10 (2)
// M -> 11 (3)

// Sinais do BUS
// 00 -> Read Miss  - Pode acontecer sozinho ou junto de um Write Back
// 01 -> Write Miss - Pode acontecer sozinho ou junto de um Write Back
// 10 -> Invalidate

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

// Sinal do Bus
wire [15:0] bus, bus_out_p0, bus_out_p1, bus_out_p2;

// Sinais Memória de Instruções
reg send;
wire [1:0] proc, opcode;
wire [3:0] tag;
wire [7:0] data;

// Sinais Processadores
wire wb_p0, wb_p1, wb_p2;
wire [15:0] wb_block_p0, wb_block_p1, wb_block_p2;
wire done_p0, done_p1, done_p2;
wire p0_has_block, p1_has_block, p2_has_block;
wire [15:0] p0_block, p1_block, p2_block;
wire [15:0] proc0_out, proc1_out, proc2_out;

// Sinais Memória de Dados
wire [15:0] data_mem;

reg [15:0] inst_aux;

// Lógica para controlar o envio de instruções
initial begin

	send = 1'b1;

end

always @ (posedge clock) begin

	if (done_p0 == 1'b0 || done_p1 == 1'b0 || done_p2 == 1'b0) begin
	
		send = 1'b0;
		
	end
	
	else begin
	
		send = 1'b1;
	
	end
	
end

// Instanciar Memória de Instruções
mem_inst instruction_memory (clock, reset, send, done_p0, done_p1, done_p2, proc, opcode, tag, data);

// Instanciar Memória de Dados
mem_data data_memory (clock, reset, wb_p0, wb_p1, wb_p2, wb_block_p0, wb_block_p1, wb_block_p2, bus, data_mem);

// Instanciar Bus Arbiter
bus_arbiter Bus_Arbiter (clock, reset, proc, bus_out_p0, bus_out_p1, bus_out_p2, bus);

// Instanciar Processador 0
processador0 p0 (clock, reset, proc, opcode, tag, data, p1_block, p2_block, data_mem, p1_has_block, p2_has_block, bus, // INPUTS
					  bus_out_p0, proc0_out, wb_p0, wb_block_p0, done_p0, p0_block, p0_has_block); // OUTPUTS

// Instanciar Processador 1
processador1 p1 (clock, reset, proc, opcode, tag, data, p0_block, p2_block, data_mem, p0_has_block, p2_has_block, bus, // INPUTS
					  bus_out_p1, proc1_out, wb_p1, wb_block_p1, done_p1, p1_block, p1_has_block); // OUTPUTS

// Instanciar Processador 2
processador2 p2 (clock, reset, proc, opcode, tag, data, p0_block, p1_block, data_mem, p0_has_block, p1_has_block, bus, // INPUTS
					  bus_out_p2, proc2_out, wb_p2, wb_block_p2, done_p2, p2_block, p2_has_block); // OUTPUTS
 
endmodule
