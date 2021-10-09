module FSM_directory_testbenches(input [8:0] test_all, input [7:0] rand_bit_vector, input [7:0] rand_requesting_processor);
	wire cb_send_write_miss;//saidas do cache block
	wire cb_send_read_miss;
	wire cb_send_invalidate;
	wire cb_send_write_back;
	wire [1:0] cb_state_out;

	wire t_send_fetch;//saidas da table
	wire t_send_invalidate;
	wire t_send_data_value_reply;
	wire [1:0] t_state_out;
	wire [7:0] t_bit_vector_out;
	
	FSM_DIRECTORY_cache_block B1(
		.state_in(test_all[8:7]),
		.fetch(test_all[6]), 
		.invalidate(test_all[5]), 
		.write_back(test_all[4]),
		.write_hit(test_all[3]),
		.read_hit(test_all[2]),
		.write_miss(test_all[1]),
		.read_miss(test_all[0]),

		.send_write_miss(cb_send_write_miss), .send_read_miss(cb_send_read_miss), .send_invalidate(cb_send_invalidate), .send_write_back(cb_send_write_back),
		.state_out(cb_state_out)
	);
	FSM_DIRECTORY_table B2(
		.state_in(test_all[6:5]),
		.read_miss(test_all[4]), .write_miss(test_all[3]),
		.external_write_back(test_all[2]), .external_write_miss(test_all[1]), .external_read_miss(test_all[0]),
		.requesting_processor(rand_requesting_processor),
		.bit_vector(rand_bit_vector), 

		.send_fetch(t_send_fetch), .send_invalidate(t_send_invalidate), .send_data_value_reply(t_send_data_value_reply),
		.state_out(t_state_out),
		.bit_vector_out(t_bit_vector_out)
	);
endmodule