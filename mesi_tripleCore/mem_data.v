module mem_data (

	input clock,
	input reset,
	
	// Dados de um Write Back
	input wb_p0, wb_p1, wb_p2,
	input [15:0] p0_block, p1_block, p2_block,
	
	input [15:0] bus,
	
	output reg [15:0] mem_block

);

// A memória de dados só será acessada quando ocorrer um miss ou quando ocorrer um write back;

// Memória de Dados - Matriz 20x16
reg[15:0] mem_data[19:0];

// Registrador para salvar a tag a ser acessada na memória
reg [3:0] tag_mem;
reg [3:0] tag_mem_miss;

reg [9:0] data_missing;

initial begin
	
	// Inicializando a Memória de Dados
	mem_data[0] <= 16'b0000000000000000;
	mem_data[1] <= 16'b0000000000000000;
	mem_data[2] <= 16'b0000000000000000;
	mem_data[3] <= 16'b0000000000000000;
	mem_data[4] <= 16'b0000000000000000;
	mem_data[5] <= 16'b0000000000000000;
	mem_data[6] <= 16'b0000000000000000;
	mem_data[7] <= 16'b0000000000000000;
	mem_data[8] <= 16'b0000000000000000;
	mem_data[9] <= 16'b0000000000000000;
	mem_data[10] <= 16'b0000000000001010; // 10
	mem_data[11] <= 16'b0000000000001011; // 11
	mem_data[12] <= 16'b0000000000001100; // 12
	mem_data[13] <= 16'b0000000000001101; // 13
	mem_data[14] <= 16'b0000000000001110; // 14
	mem_data[15] <= 16'b0000000000000000;
	mem_data[16] <= 16'b0000000000000000;
	mem_data[17] <= 16'b0000000000000000;
	mem_data[18] <= 16'b0000000000000000;
	mem_data[19] <= 16'b0000000000000000;
	
	// Inicializando demais variáveis
	tag_mem = 3'b000;
	tag_mem_miss = 3'b000;
	mem_block = 16'b0000000000000000;
	
end

// Write Back
always @ (posedge clock && (wb_p0 || wb_p1 || wb_p2)) begin

	if (wb_p0 == 1'b1) begin
	
		tag_mem = p0_block[15:12];
		
		mem_data[tag_mem] = p0_block[9:0];
		
	end
	
	if (wb_p1 == 1'b1) begin
	
		tag_mem = p1_block[15:12];
		
		mem_data[tag_mem] = p1_block[9:0];
		
	end
	
	if (wb_p2 == 1'b1) begin
	
		tag_mem = p2_block[15:12];
		
		mem_data[tag_mem] = p2_block[9:0];
		
	end
	
end

// Read Miss ou Write Miss
always @ (posedge clock) begin
	
	if (bus[15:14] == 2'b00 || bus[15:14] == 2'b01) begin
	
		tag_mem_miss = bus[13:10];
		
		data_missing = mem_data[tag_mem_miss][9:0];
	
		// BLOCO -> TAG, ESTADO, DADO
		mem_block = {tag_mem_miss,2'b00,data_missing};
	
	end
	
end

endmodule
