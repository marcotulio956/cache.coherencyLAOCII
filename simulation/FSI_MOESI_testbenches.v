module FSM_MOESI_testbenches();
	parameter FROM_M=3'b001, FROM_O=3'b011, FROM_E=3'b100, FROM_MEM=3'b101;
	parameter INVALID=3'b000, MODIFIED=3'b001, SHARED=3'b010, OWNED=3'b011, EXCLUSIVE=3'b100;

	reg [2:0] coherency_state_attending_cpu;
	reg cpu_write_hit, cpu_read_hit;//crh has not an actual meaning
	reg cpu_write_miss, cpu_read_miss;

	reg [2:0] coherency_state_attending_bus;
	reg [1:0] bus_from_state;//from (M|O|E|MM)
	reg bus_read;
	reg bus_rwitm; // read miss but "read with intention to modify"
	reg bus_invalidate;
	reg bus_shared;
	//--
	wire [2:0] cpu_next_state;

	wire read;
	wire rwitm;
	wire invalidate;
	wire shared;
	wire abort_mem_access_next;//intervention

	initial begin
		#0
		coherency_state_attending_cpu <= INVALID;
		cpu_write_hit <= 0;
		cpu_read_hit <= 0;
		cpu_write_miss <= 0;
		cpu_read_miss <= 1'b1;
		coherency_state_attending_bus <= INVALID;
		bus_from_state <= INVALID;
		bus_read <= 0;
		bus_rwitm <= 0;
		bus_invalidate <= 0;
		bus_shared <= 0;
		// #10
		// your stuff
	end

	FSM_MOESI_controler TEST(
		.coherency_state_attending_cpu(coherency_state_attending_cpu),
		.cpu_write_hit(cpu_write_hit),
		.cpu_read_hit(cpu_read_hit),
		.cpu_write_miss(cpu_write_miss),
		.cpu_read_miss(cpu_read_miss),

		.coherency_state_attending_bus(coherency_state_attending_bus),
		.bus_from_state(bus_from_state),
		.bus_read(bus_read),
		.bus_rwitm(bus_rwitm),
		.bus_invalidate(bus_invalidate),
		.bus_shared(bus_shared),
		//--
		.cpu_next_state(cpu_next_state),

		.read(read),
		.rwitm(rwitm),
		.invalidate(invalidate),
		.shared(shared),
		.abort_mem_access_next(abort_mem_access_next)
	);
endmodule