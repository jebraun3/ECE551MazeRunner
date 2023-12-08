module UART_wrapper(clk, rst_n, RX, trmt, resp, tx_done, TX, clr_cmd_rdy, cmd, cmd_rdy);

input logic clk, rst_n, RX, trmt, clr_cmd_rdy;
input logic [7:0] resp;
output logic cmd_rdy, tx_done, TX;
output logic [15:0] cmd;

logic rx_rdy, clr_rdy, byte_sel;
logic [7:0] rx_data;
logic [7:0] ff_in;
logic [7:0]upperbyte;
logic set_cmd_rdy;

//instantiate UART module
UART uart(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),.clr_rx_rdy(clr_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(resp),.tx_done(tx_done));

typedef enum logic {IDLE , RCVNG} state_t; 


state_t state, nxt_state;

//ff to store upper byte
always_ff @(posedge clk) begin
	upperbyte <= (byte_sel)?rx_data:upperbyte;
end

//state ff
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

//State Machine
always_comb begin
	nxt_state = state ;
	set_cmd_rdy = 0;
	clr_rdy = 0;
	byte_sel = 0;


	case (state)
	IDLE:   begin
					  if(rx_rdy) begin
							byte_sel = 1;
							clr_rdy = 1;
							nxt_state = RCVNG;
						end
				  end
	
	RCVNG:  begin
					 if(rx_rdy) begin
						set_cmd_rdy = 1;
						clr_rdy = 1;
						nxt_state = IDLE;
					 end
					end
	endcase
end

//SR ff for cmd_rdy
always_ff @(posedge clk) begin
	if(set_cmd_rdy)
		cmd_rdy <= 1;
	else if(rx_rdy)
		cmd_rdy <= 0;
	else if(clr_cmd_rdy)
		cmd_rdy <= 0;
	
end


assign cmd = {upperbyte,rx_data};

endmodule