module cache_directlyMapped_32x21bits(
	input clk,core,
/*DUVIDA: existem nas maquinas de estado dois write backs, se estamos na cache 1 e p1 escreve numa linha em que
o bloco estava como imediato e com outra tag(write miss) e ao mesmo tempo a cache 2 ....... eh possivel termos 2 write backs ?*/
	input read,//from cpu
	input write,
	input [15:0] write_data,
	input [8:0] mem_address,
	
	input [1:0] bus_requests,//from other caches: BUS_INVALIDATE=2'b00, BUS_WRITE_MISS=2'b01, BUS_READ_MISS=2'b10;
	input [8:0] bus_request_mem_address,//the position they reffer	
	
	input bus_data_found,//if the other cache says abort mem access 
	input [15:0] bus_data_delivery,//if we ever need a data that's in other cache, there it is
	
	input [15:0] mem_data_delivery,
	
	output [15:0] data_out_cpu,//reading going to cpu 

	output cpu_write_back,bus_write_back,//promote upper in the hierarchy, main mem is watching this
	output [8:0] address_out_mem_cpu,address_out_mem_bus,
	output [15:0] data_out_mem_cpu,data_out_mem_bus,//unique data goes to ram

	output bus_reply_abort_mem_access,//announces to the other core we have the data needed
	output [15:0] bus_reply_data_found,//attends bus_request
	
	output [8:0] ask_mem_address,//what they need to find
	output [1:0] bus_reply//write on bus for another core that's snooping it
	);

// Cache Line Configuration Scheme:
// |coherency state ~2bits|tag ~4bits|data ~16bits|
//  21                  20 19      16 15         0
	integer i,cc;//inicialization
	integer j,k;//loops
	
	//States parameters, for state_in and state_out, simplificam a vida:
	parameter INVALID=2'b00, MODIFIED=2'b01, SHARED=2'b10;
	//Bus parameters, to go out for bus:
	parameter BUS_INVALIDATE=2'b00, BUS_WRITE_MISS=2'b01, BUS_READ_MISS=2'b10;
	
	reg [21:0] cache [0:31];//estrutura de dados da cache que armazenara o que a fsm r e b retorna
	
	wire [4:0] cache_index = mem_address[4:0];//decomposing the cpu address input into index and tag
	wire [3:0] mem_tag = mem_address[8:5];

	wire [4:0] cache_tag_attending_bus = bus_request_mem_address[8:5];//decomposing the bus address input into index and tag
	wire [4:0] cache_index_attending_bus = bus_request_mem_address[4:0];
	wire [1:0] coherency_state_attending_bus = cache[cache_index_attending_bus][21:20];

	wire [1:0] coherency_state_attending_cpu = cache[cache_index][21:20];//decomposing cache's line
	wire [3:0] tag = cache[cache_index][19:16];
	wire [15:0] data = cache[cache_index][15:0];


	wire write_hit  = (write & ~read) & ( mem_tag == tag) & coherency_state_attending_cpu!=INVALID;//for calculating the next block state
	wire write_miss = (write & ~read) & ((mem_tag != tag) | coherency_state_attending_cpu==INVALID);
	wire read_hit   = (~write & read) & ( mem_tag == tag) & coherency_state_attending_cpu!=INVALID;
	wire read_miss  = (~write & read) & ((mem_tag != tag) | coherency_state_attending_cpu==INVALID);

	wire cpu_match = (coherency_state_attending_cpu!=INVALID?1'b1:1'b0) & (tag==mem_tag? 1'b1:1'b0);//whenever a hit
	wire bus_resquest_match = (cache[cache_index_attending_bus][21:20]!=INVALID?1'b1:1'b0) & (cache[cache_index_attending_bus][19:16]==cache_tag_attending_bus? 1'b1:1'b0);
	wire cpu_controler_write_back, bus_controler_write_back, bus_controler_abort_mem_access;
	wire [1:0] state_next_cpu,state_next_bus;//first is used in the block, the second is what our FSI MSI BUS calculated to attend bus a request
	
	assign data_out_cpu = read_hit == 1'b1 ? data : (bus_data_found == 1 ? bus_data_delivery : mem_data_delivery);

	assign cpu_write_back = cpu_controler_write_back;
	assign bus_write_back = bus_controler_write_back;

	assign address_out_mem_cpu = {cache[cache_index][19:16],cache_index};
	assign address_out_mem_bus =  {cache[cache_index_attending_bus][19:16],cache_index_attending_bus};
	assign data_out_mem_cpu = cache[cache_index][15:0];
	assign data_out_mem_bus = cache[cache_index_attending_bus][15:0];

	assign bus_reply_abort_mem_access = bus_resquest_match == 1 ? bus_controler_abort_mem_access : 1'b0;
	assign bus_reply_data_found = cache[cache_index_attending_bus][15:0];//think as abort mem access data

	assign ask_mem_address = mem_address;

	initial begin		
		#0
		cc = 0;
		for(i=0;i<32;i=i+1) begin
			cache[i]<=21'b0;
		end
	end
	FSM_MSI_CPU_requests_controler _CTRL_R_(
		.state_in(coherency_state_attending_cpu),
		.cpu_write_hit(write_hit),.cpu_read_hit(read_hit),
		.cpu_write_miss(write_miss),.cpu_read_miss(read_miss),
		.write_back_block_next(cpu_controler_write_back),//send to mem //<-outputs:
		.state_next(state_next_cpu),//used in block
		.bus_next(bus_reply)//writen on bus
	);
	FSM_MSI_BUS_requests_controler _CTRL_B_(
		.state_in(coherency_state_attending_bus),
		.bus_write_miss(bus_requests==BUS_WRITE_MISS?1'b1:1'b0), 
		.bus_read_miss(bus_requests==BUS_READ_MISS?1'b1:1'b0), 
		.bus_invalidate(bus_requests==BUS_INVALIDATE?1'b1:1'b0),	
		.abort_mem_access_next(bus_controler_abort_mem_access),//send to bus //<-outputs:
		.write_back_block_next(bus_controler_write_back),//send to mem
		.state_next(state_next_bus)//used on block
	);
	always@(posedge clk)begin//monitora as suas bordas para antes e depois da escrita
		$display("cc %b Cache %b  w %b r %b data %b address %b\n\tbr %b br_adrs %b\n\tline %b    lineBus %b | cpu_match? %b bus_match? %b\n\twh %b rh %b wm %b rm %b\n\tw_bus %b | ncpu %b nbus %b\n\tcpu _wb %b bus_wb %b\n\tabort %b\n\tout_cpu %b out_mem_cpu %b out_mem_bus %b  out_bus %b",
			cc,core,write,read,write_data,mem_address,
			bus_requests, bus_request_mem_address,
			cache[cache_index],cache[cache_index_attending_bus],cpu_match,bus_resquest_match,
			write_hit,read_hit,write_miss,read_miss,
			bus_reply, state_next_cpu, state_next_bus,
			cpu_write_back, bus_write_back,
			bus_reply_abort_mem_access,
			data_out_cpu, data_out_mem_cpu, data_out_mem_bus, bus_reply_data_found
		);
		for(i=0;i<10;i=i+1)begin
			$display("\t%d: %b",i,cache[i]);
		end
	end
	always@(posedge clk)begin
		cc = cc + 1;
		cache[cache_index][21:20] <= state_next_cpu;//update line state from cpu request
		cache[cache_index][19:16] <= mem_tag;
		if (bus_resquest_match==1'b1)begin
			cache[cache_index_attending_bus][21:20] <= state_next_bus;//update line state from bus request
		end
		if(write==1'b1)begin
			cache[cache_index][15:0] <= write_data;
		end
		if (bus_data_found==1'b1 && read_miss == 1'b1)begin
			cache[cache_index][15:0] <= bus_data_delivery;
		end 
		else if (bus_data_found==1'b0 && read_miss == 1'b1)begin
			cache[cache_index][15:0] <= mem_data_delivery;
		end
	end
endmodule