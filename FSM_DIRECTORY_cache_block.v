module FSM_DIRECTORY_cache_block(

	input [1:0] state_in,
	
	input fetch, invalidate, write_back,// outside requests
	input write_hit, read_hit, write_miss, read_miss, // cpu requests 

	output reg send_write_miss, send_read_miss, send_invalidate, send_write_back,
	output reg [1:0] state_out
	);

	parameter INVALID = 2'b0, MODIFIED = 2'b01, SHARED = 2'b10;

	wire write = write_hit | write_miss; // whenever a write
	wire read = read_hit | read_miss;

	initial begin
		send_write_miss <= 1'b0;
		send_read_miss <= 1'b0;
		send_invalidate <= 1'b0;
		send_write_back <= 1'b0;
		state_out <= INVALID;
	end

	always @(*) begin
		$display("cb: state_in %b f %b i %b wb %b wh %b rh %b wm %b rm %b                        -->>  state_out %b    swm %b srm %b si %b swb %b",
			state_in, fetch, invalidate, write_back, write_hit, read_hit, write_miss, read_miss,
			state_out, send_write_miss, send_read_miss, send_invalidate, send_write_back
		);
		case(state_in)
			INVALID:begin
				case({write,read})
					2'b01:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b1;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= SHARED;
					end
					2'b10:begin
						send_write_miss <= 1'b1;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= MODIFIED;
					end
				endcase
			end
			MODIFIED:begin
				case({fetch,invalidate,write_back,write_hit,read_hit,write_miss,read_miss})
					7'b1010000,7'b0110000:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= INVALID;	
					end
					7'b0000001:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b1;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b1;
						state_out <= SHARED;	
					end					
					7'b1010000:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= SHARED;		
					end
					7'b0000010:begin
						send_write_miss <= 1'b1;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b1;
						state_out <= MODIFIED;	
					end
					7'b0001100:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= MODIFIED;	
					end
				endcase
			end
			SHARED:begin
				case({fetch,invalidate,write_back,write_hit,read_hit,write_miss,read_miss})
					7'b010000:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= INVALID;	
					end
					7'b0000100:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= SHARED;	
					end
					7'b0000001:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b1;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b0;
						state_out <= SHARED;	
					end
					7'b0000010:begin
						send_write_miss <= 1'b1;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b0;
						send_write_back <= 1'b1;
						state_out <= MODIFIED;	
					end
					7'b0001000:begin
						send_write_miss <= 1'b0;
						send_read_miss <= 1'b0;
						send_invalidate <= 1'b1;
						send_write_back <= 1'b0;
						state_out <= MODIFIED;	
					end
				endcase
			end
		endcase
	end
endmodule