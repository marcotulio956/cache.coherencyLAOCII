module bus_arbiter(

	input clock,
	input reset,
	input[1:0] proc,
	input [15:0] bus_p0, bus_p1, bus_p2,
	
	output reg [15:0] bus
	
);

initial begin
	
	bus = 16'b0000000000000000;

end

always @ (posedge clock) begin

	if (proc == 2'b00) begin
	
		bus = bus_p0;
	
	end
	
	else if (proc == 2'b01) begin
	
		bus = bus_p1;
	
	end
	
	else if (proc == 2'b10) begin
	
		bus = bus_p2;
	
	end
	
end

endmodule
