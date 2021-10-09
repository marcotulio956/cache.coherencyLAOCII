module FSM_DIRECTORY_table(
	input read_miss, write_miss,//within the directory
	input external_write_back, external_write_miss, external_read_miss,
	input [7:0] requesting_processor,
	input [1:0] state_in,
	input [7:0] bit_vector,// block's sharers 


	output reg send_fetch, send_invalidate, send_data_value_reply,
	output reg [1:0] state_out,
	output reg [7:0] bit_vector_out
	);
	parameter UNCACHED = 2'b0, EXCLUSIVE = 2'b01, SHARED = 2'b10;
// it was meant to be for at most 8 processors, which is the reason which the sharers(bitvector) is eight bits, as well as the processors indexing 
	initial begin
		send_fetch <= 1'b0;
		send_invalidate <= 1'b0;
		send_data_value_reply <= 1'b0;
		state_out <= UNCACHED;
		bit_vector_out <= 7'b0; 
	end
	always@(*) begin
		$display("t:  state_in %b rm %b wm %b ewb %b ewm %b wrm %b req %b bitv %b  -->>  state_out %b sf %b si %b sdvr %b bitvo %b",
			state_in, read_miss, write_miss, external_write_back, external_write_miss, external_read_miss, requesting_processor, bit_vector,
			state_out, send_fetch, send_invalidate, send_data_value_reply, bit_vector_out
		);
		case(state_in)
			UNCACHED:begin
				case({external_write_miss,external_read_miss})
					2'b01:begin
						send_fetch <= 1'b0;
						send_invalidate <= 1'b0;
						send_data_value_reply <= 1'b1;
						state_out <= SHARED;
						bit_vector_out <= bit_vector; 
					end
					2'b10:begin
						send_fetch <= 1'b0;
						send_invalidate <= 1'b0;
						send_data_value_reply <= 1'b1;
						state_out <= EXCLUSIVE;
						bit_vector_out <= bit_vector; 
					end
				endcase
			end
			EXCLUSIVE:begin
				case({read_miss,external_write_back,external_write_miss})
					3'b001:begin
						send_fetch <= 1'b1;
						send_invalidate <= 1'b1;
						send_data_value_reply <= 1'b1;
						state_out <= EXCLUSIVE;
						bit_vector_out <= requesting_processor; 
					end
					3'b010:begin
						send_fetch <= 1'b0;
						send_invalidate <= 1'b0;
						send_data_value_reply <= 1'b0;
						state_out <= UNCACHED;
						bit_vector_out <= 7'b0; 
					end
					3'b100:begin
						send_fetch <= 1'b1;
						send_invalidate <= 1'b0;
						send_data_value_reply <= 1'b1;
						state_out <= SHARED;
						bit_vector_out <= bit_vector | requesting_processor;// sharers U= p 
					end
				endcase
			end
			SHARED:begin
				case({write_miss,external_read_miss})
					2'b01:begin
						send_fetch <= 1'b0;
						send_invalidate <= 1'b0;
						send_data_value_reply <= 1'b1;
						state_out <= SHARED;
						bit_vector_out <= bit_vector | requesting_processor; 
					end
					2'b10:begin
						send_fetch <= 1'b0;
						send_invalidate <= 1'b1;
						send_data_value_reply <= 1'b1;
						state_out <= EXCLUSIVE;
						bit_vector_out <= bit_vector; 
					end
				endcase
			end
		endcase
	end
endmodule