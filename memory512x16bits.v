module memory512x16bits(
	input clk,
	input [8:0] address_read1,address_read2,
	input write1, write2, write3, write4,
	input [8:0] address_write1,address_write2,address_write3,address_write4, 
	input [15:0] data_write1, data_write2,data_write3, data_write4,
	
	output [15:0] readed1,readed2	
);
	integer i,j;
	reg [15:0] mem [0:511];
	assign readed1 = mem[address_read1];
	assign readed2 = mem[address_read2];
	initial begin
		#0
		for(i=0;i<512;i=i+1)begin
			mem[i] <= 16'b0;
		end
		#1
		mem[4] <= 1'b1;
		mem[5] <= 2'b11;
		mem[34] <= 3'b111;
		mem[35] <= 4'b1111;
	end
	always@(posedge clk)begin
		$display("\t\tMem");
		for(j=0;j<12;j=j+1)begin//apenas 12 das 2^9=512 linhas
			$display("\t\t%d %b",j,mem[j]);
		end
		$display("\t\t\t 34 %b",mem[34]);
		$display("\t\t\t 35 %b",mem[35]);
		$display("\t\t\t256 %b",mem[256]);
		$display("\t\t\t257 %b",mem[257]);
		if(write1==1'b1)
			mem[address_write1] <= data_write1;
		if(write2==1'b1)
			mem[address_write2] <= data_write2;
		if(write3==1'b1)
			mem[address_write3] <= data_write3;
		if(write4==1'b1)
			mem[address_write4] <= data_write4;
	end
endmodule