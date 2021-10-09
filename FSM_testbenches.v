module TEST_FSM_MSI_CPU_requests_controler(
	input clk
);
	reg [1:0] test_state;
	reg [3:0] test_cpu_reqts;
	
	wire write_back_block;
	wire [1:0] state_out,bus_out;
	
	initial begin
		#0
		test_state <= 2'b0;
		test_cpu_reqts <= 4'b0001;
		#100
		test_state <= 2'b0;
		test_cpu_reqts <= 4'b0010;
		#100
		test_state <= 2'b0;
		test_cpu_reqts <= 4'b0100;
		#100
		test_state <= 2'b0;
		test_cpu_reqts <= 4'b1000;
		#100
		test_state <= 2'b01;
		test_cpu_reqts <= 4'b0001;
		#100
		test_state <= 2'b01;
		test_cpu_reqts <= 4'b0010;
		#100
		test_state <= 2'b01;
		test_cpu_reqts <= 4'b0100;
		#100
		test_state <= 2'b01;
		test_cpu_reqts <= 4'b1000;
		#100
		test_state <= 2'b10;
		test_cpu_reqts <= 4'b0001;
		#100
		test_state <= 2'b10;
		test_cpu_reqts <= 4'b0010;
		#100
		test_state <= 2'b10;
		test_cpu_reqts <= 4'b0100;
		#100
		test_state <= 2'b10;
		test_cpu_reqts <= 4'b1000;
	end
	
	FSM_MSI_CPU_requests_controler TEST(clk,test_state,test_cpu_reqts[3],test_cpu_reqts[2],test_cpu_reqts[1],test_cpu_reqts[0],write_back_block,state_out,bus_out);
endmodule
module TEST_FSM_MSI_BUS_requests_controler(
	input clk
);
	reg [1:0] test_state;
	reg [2:0] test_bus_reqts;
	
	wire abort_mem_access, write_back_block;
	wire [1:0] state_out;
	
	initial begin
		#0
		test_state <= 2'b0;
		test_bus_reqts <= 3'b001;
		#100
		test_state <= 2'b0;
		test_bus_reqts <= 3'b010;
		#100
		test_state <= 2'b0;
		test_bus_reqts <= 3'b100;
		#100
		test_state <= 2'b01;
		test_bus_reqts <= 3'b001;
		#100
		test_state <= 2'b01;
		test_bus_reqts <= 3'b010;
		#100
		test_state <= 2'b01;
		test_bus_reqts <= 3'b100;
		#100
		test_state <= 2'b10;
		test_bus_reqts <= 3'b001;
		#100
		test_state <= 2'b10;
		test_bus_reqts <= 3'b010;
		#100
		test_state <= 2'b10;
		test_bus_reqts <= 3'b100;
	end
	FSM_MSI_BUS_requests_controler TEST(clk,test_state,test_bus_reqts[2],test_bus_reqts[1],test_bus_reqts[0],abort_mem_access,write_back_block,state_out);
endmodule