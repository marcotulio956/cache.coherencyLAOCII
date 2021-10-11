module FSM_MSI_BUS_requests_controller(
	input [1:0] state_in,
	input bus_write_miss, 
	input bus_read_miss, 
	input bus_invalidate,
	
	output reg abort_mem_access_next,
	output reg write_back_block_next,
	output reg [1:0] state_next
	);
	parameter INVALID=2'b00, MODIFIED=2'b01, SHARED=2'b10;
	initial begin 
		state_next <= INVALID;
		write_back_block_next <= 0;
		abort_mem_access_next <= 0;
	end
	always@(*)begin
		case(state_in)
			MODIFIED:begin
				case({bus_write_miss,bus_read_miss})
					2'b01:begin
						state_next <= SHARED;
						write_back_block_next <= 1;
						abort_mem_access_next <= 1;
					end
					2'b10:begin
						state_next <= INVALID;
						write_back_block_next <= 1;
						abort_mem_access_next <= 1;
					end
					default: begin
						state_next <= state_next; 
					 	write_back_block_next <= 0;
					 	abort_mem_access_next <= 0;
					end
				endcase
			end
			SHARED:begin
				case({bus_invalidate,bus_write_miss,bus_read_miss})
					3'b001:begin
						state_next <= SHARED;
						write_back_block_next <= 0;
						abort_mem_access_next <= 0;
					end
					3'b010,3'b100:begin
						state_next <= INVALID;
						write_back_block_next <= 0;
						abort_mem_access_next <= 0;
					end
					default:begin
					 	write_back_block_next <= 0;
					 	abort_mem_access_next <= 0;
					 	state_next <= state_next;
					end
				endcase
			end
		endcase
	end
endmodule
