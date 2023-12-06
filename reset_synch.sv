module reset_synch(RST_n,rst_n,clk);

input logic RST_n, clk;
output logic rst_n;


logic ff1;

always_ff @(negedge clk, negedge RST_n) begin
	if(!RST_n) begin
		ff1 <= 0;
		rst_n <= 0;
	end
	else begin
		ff1 <= 1'b1;
		rst_n <= ff1;
	end
end

endmodule
