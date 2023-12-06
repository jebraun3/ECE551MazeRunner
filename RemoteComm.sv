module RemoteComm(clk, rst_n, RX, TX, cmd, send_cmd, cmd_sent, resp_rdy, resp);

input clk, rst_n;		// clock and active low reset
input RX;				// serial data input
input send_cmd;			// indicates to tranmit 24-bit command (cmd)
input [15:0] cmd;		// 16-bit command

output TX;				// serial data output
output logic cmd_sent;		// indicates transmission of command complete
output resp_rdy;		// indicates 8-bit response has been received
output [7:0] resp;		// 8-bit response from DUT


logic tx_done;
logic byte_sel;
logic [7:0] tx_data;
logic [7:0]lower_byte;
logic set_cmd_snt;
logic trmt;


///////////////////////////////////////////////
// Instantiate basic 8-bit UART transceiver //
/////////////////////////////////////////////
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
           .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy));


//ff to store lower byte
always_ff @(posedge clk) begin
	if(send_cmd)
		lower_byte <= cmd[7:0];
end

assign tx_data = (byte_sel)?cmd[15:8]:lower_byte;

typedef enum logic [1:0] {IDLE,UPPER_BYTE,LOWER_BYTE,WAIT} state_t;

state_t state , next_state;

//State Machine
always_comb begin
	next_state = state;
	byte_sel = 0;
	set_cmd_snt = 0;
	trmt = 0;

	case (state)
	IDLE: 			begin
								if(send_cmd) begin
									byte_sel = 1;
									trmt = 1;
									next_state = UPPER_BYTE;
								end
							end
	
	UPPER_BYTE: begin
								if(tx_done)begin
									byte_sel = 0;
									trmt = 1;
									next_state = LOWER_BYTE;
								end
							end
	
	LOWER_BYTE: begin
								if(tx_done)begin
								set_cmd_snt = 1;
								next_state = WAIT;
								end
							end
	
	WAIT:				begin
								if(resp_rdy)
								next_state = IDLE;
							end
	endcase
end

//ff for state
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

//SR ff for cmd_sent
always_ff @(posedge clk) begin
	if(send_cmd)
		cmd_sent <= 0;
	else if(set_cmd_snt)
		cmd_sent <= 1;
end


endmodule	
