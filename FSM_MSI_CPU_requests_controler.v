module FSM_MSI_CPU_requests_controler(
	input [1:0] state_in,
	input cpu_write_hit, cpu_read_hit,
	input cpu_write_miss, cpu_read_miss,
	
	output reg write_back_block_next,//used in implementation
	output reg [1:0] state_next,bus_next
	);
	//States parameters, for state_in and state_out, simplificam a vida:
	parameter INVALID=2'b00, MODIFIED=2'b01, SHARED=2'b10;
	//Bus parameters, to go out for bus:
	parameter BUS_INVALIDATE=2'b00, BUS_WRITE_MISS=2'b01, BUS_READ_MISS=2'b10;
	
	wire cpu_write = cpu_write_hit | cpu_write_miss;//whenever a write
	wire cpu_read = cpu_read_hit | cpu_read_miss;
	
	initial begin
		state_next <= INVALID;
		bus_next <= 2'b0;
		write_back_block_next <= 0;
	end
	always@(*)begin
		case(state_in)
			INVALID:begin
				case({cpu_write,cpu_read})
					2'b01: begin
						state_next <= SHARED;
						bus_next <= BUS_READ_MISS;
						write_back_block_next <= 0;
					end
					2'b10: begin
						state_next <= MODIFIED;
						bus_next <= BUS_WRITE_MISS;
						write_back_block_next <= 0;
					end
					default:begin
						state_next <= 2'b11;//error code
						bus_next <= 2'b11;
						write_back_block_next <= 0;
						$display("Error: no cpu should write and read at the once");
					end
				endcase
			end
			MODIFIED:begin
				case({cpu_write_hit,cpu_read_hit,cpu_write_miss,cpu_read_miss})
					4'b0001:begin						
						state_next <= SHARED;
						bus_next <= BUS_READ_MISS;
						write_back_block_next <= 1;
					end
					4'b0010:begin
						state_next <= MODIFIED;
						bus_next <= BUS_WRITE_MISS;
						write_back_block_next <=1;					
					end
					4'b0100,4'b1000:begin
						state_next <= MODIFIED;
						write_back_block_next <= 0;
					end
					default:begin
						state_next <= 2'b11;//error code
						bus_next <= 2'b11;
						write_back_block_next <= 0;
					end
				endcase			
			end
			SHARED:begin
				case({cpu_write_hit,cpu_read_hit,cpu_write_miss,cpu_read_miss})
					4'b0001:begin
						state_next <= SHARED;
						bus_next <= BUS_READ_MISS;
						write_back_block_next <= 0;
					end
					4'b0010:begin
						state_next <= MODIFIED;
						bus_next <= BUS_WRITE_MISS;
						write_back_block_next <= 0;
					end
					4'b0100:begin
						state_next <= SHARED;
						write_back_block_next <= 0;
					end
					4'b1000:begin
						state_next <= MODIFIED;
						bus_next <= BUS_INVALIDATE;
						write_back_block_next <= 0;
					end
					default:begin
						state_next <= 2'b11;//error code
						bus_next <= 2'b11;
						write_back_block_next <= 0;
					end
				endcase
			end
		endcase
	end
endmodule