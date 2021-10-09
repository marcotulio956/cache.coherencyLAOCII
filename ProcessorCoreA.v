module ProcessorCoreA(
	input clk, input [15:0] fetched_data,
	output read, write, output [8:0] address, output [15:0] write_data
);//cada um com suas instrucoes separadas
// Instructions Scheme:
// |op ~1bit|address ~9bits|data ~16bits| ~26bits
//  25       24          16 15         0
// where, op==1: write, op==0 read 
	integer i,index;
	reg [25:0] instructions [0:64];//64x21bits instructions memory size
	initial begin
		$readmemb("core1_instructions.txt", instructions); // memory file
		index <= -1;
		$display("core1_instructions: ");
		for(i=0; i<10; i=i+1) begin
			$display("%b",instructions[i]);
		end
	end
	
	always@(posedge clk)begin
		index <= index + 1;
	end
	assign read = instructions[index][25] == 0 ? 1'b1:1'b0;
	assign write = instructions[index][25];
	assign address = instructions[index][24:16];
	assign write_data = instructions[index][15:0];
endmodule