module ProcessorCoreB(
	input clk, input [15:0] fetched_data,
	output read, write, output [8:0] address, output [15:0] write_data
);
	integer i,index;
	reg [25:0] instructions [0:64];
	initial begin
		$readmemb("core2_instructions.txt", instructions);
		index <= -1;
		$display("core2_instructions: ");
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