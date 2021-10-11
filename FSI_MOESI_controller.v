// input from cpu refering to coherency_state_attending_cpu and if it was a (write|read)(miss|read)
// 	defines the next address state on bus for other caches(bus_reply_state) 
// 	and what we'll modify in our own(cpu_next_state).
// input from bus refering to coherency_state_attending_bus:
// 	what comes from the bus(writen by other caches, bus_state_in), 
// 	and what we'll modify in our own(cpu_next_state). 
module FSM_MOESI_controler(
	input [2:0] coherency_state_attending_cpu,
	input cpu_write_hit, cpu_read_hit,//crh has not an actual meaning
	input cpu_write_miss, cpu_read_miss,

	input [2:0] coherency_state_attending_bus,
	input [1:0] bus_from_state,//from (M|O|E|MM)
	input bus_read,
	input bus_rwitm, // read miss but "read with intention to modify"
	input bus_invalidate,
	input bus_shared,
	//--
	output reg [2:0] cpu_next_state,

	output reg read,
	output reg rwitm,
	output reg invalidate,
	output reg shared,
	output reg abort_mem_access_next//intervention
	);
	parameter FROM_M=3'b001, FROM_O=3'b011, FROM_E=3'b100, FROM_MEM=3'b101;
	parameter INVALID=3'b000, MODIFIED=3'b001, SHARED=3'b010, OWNED=3'b011, EXCLUSIVE=3'b100;
	
	wire cpu_write = cpu_write_hit | cpu_write_miss;//whenever a write
	wire cpu_read = cpu_read_hit | cpu_read_miss;

	initial begin 
		cpu_next_state <= INVALID;
		invalidate <= 0;
		rwitm <= 0;
		abort_mem_access_next <= 0;
		shared <= 0;
		read <= 0;
	end
	always@(*)begin
		case(coherency_state_attending_cpu)
			MODIFIED:begin
				if(cpu_write_hit==1'b1)begin
					cpu_next_state <= MODIFIED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 0;
				end
			end
			OWNED:begin
				if(cpu_write_hit==1'b1)begin
					cpu_next_state <= MODIFIED;
					invalidate <= 1'b1;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 0;
				end
			end
			EXCLUSIVE:begin
				if(cpu_write_hit==1'b1)begin
					cpu_next_state <= MODIFIED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 0;
				end
			end
			SHARED:begin
				if(cpu_write_hit==1'b1)begin
					cpu_next_state <= MODIFIED;
					invalidate <= 1;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 0;
				end
			end
			default:begin
				if(cpu_write_miss==1'b1 
					&& (bus_from_state==FROM_O 
						|| bus_from_state==FROM_M
						|| bus_from_state==FROM_MEM
					)
				)begin
					cpu_next_state <= MODIFIED;
					invalidate <= 0;
					rwitm <= 1;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 0;
				end
				if(cpu_read_miss==1'b1 
					&& (
						(	bus_from_state==FROM_O 
							|| bus_from_state==FROM_M
							|| bus_from_state==FROM_MEM
						)
						||
						(shared==1'b1)
					)
				)begin
					cpu_next_state <= SHARED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <=0;
					read <= 1'b1;
				end
				if(cpu_read_miss==1'b1
					&& bus_from_state==FROM_MEM
					&& shared==0
				)begin
					cpu_next_state <= EXCLUSIVE;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;
					shared <= 0;
					read <= 1;
				end
			end
		endcase
		case(coherency_state_attending_bus)
			MODIFIED:begin
				if(bus_rwitm==1'b1)begin
					cpu_next_state <= INVALID;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 1;
					shared <= 0;
					read <= 0;
				end else if(bus_read==1'b1)begin
					cpu_next_state <= OWNED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 1;
					shared <= 1'b1;
					read <= 0;
				end
			end
			OWNED:begin
				if(bus_read==1'b1)begin
					cpu_next_state <= OWNED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 1;
					shared <= 1'b1;
					read <= 0;
				end
			end
			EXCLUSIVE:begin
				if(bus_rwitm==1'b1)begin
					cpu_next_state <= INVALID;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 1;//depends on implementation
					shared <= 0;
					read <= 0;
				end else if(bus_read==1'b1)begin
					cpu_next_state <= SHARED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 1;//depends on implementation
					shared <= 1'b1;
					read <= 0;
				end
			end
			SHARED:begin
				if(bus_read==1'b1)begin
					cpu_next_state <= SHARED;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;//depends on implementation
					shared <= 1'b1;
					read <= 0;
				end
				if(bus_rwitm==1'b1 || bus_invalidate==1'b1)begin
					cpu_next_state <= INVALID;
					invalidate <= 0;
					rwitm <= 0;
					abort_mem_access_next <= 0;//depends on implementation
					shared <= 0;
					read <= 0;
				end
			end
		endcase
	end
endmodule