module UART_rcv(clk , rst_n ,clr_rdy , rx_data, rdy, RX);
input clk, RX, rst_n , clr_rdy;
output [7:0] rx_data;

output reg rdy;

typedef enum logic {IDLE , RCVNG} state_t;
logic start, shift ,receiving;
logic [3:0] bit_cnt;
logic [3:0] nxt_bit_cnt;
logic [11:0] baud_cnt;
logic [11:0] nxt_baud_cnt;
logic [8:0] shift_reg;
logic [8:0] nxt_shift_reg;

logic [1:0] start_shift;

assign start_shift = {start,shift};

always_comb begin

if( start_shift === 2'b01)
	 nxt_bit_cnt = bit_cnt + 1;
else if(start_shift === 2'b00)
	 nxt_bit_cnt = bit_cnt;
else
	 nxt_bit_cnt = '0;
end

always_ff @(posedge clk) begin
bit_cnt <= nxt_bit_cnt;
end

always_comb begin
case ({(start || shift),receiving}) inside

2'b01: nxt_baud_cnt = baud_cnt - 1;
2'b00: nxt_baud_cnt = baud_cnt;
default: begin 
       if(start == 1)
	   nxt_baud_cnt = 12'h516;
	   else
	   nxt_baud_cnt = 12'hA2C;
	   end
endcase
end

always_ff @(posedge clk) begin
baud_cnt <= nxt_baud_cnt;
end

assign shift = (baud_cnt === 12'h000)?1'b1:1'b0;


always_comb begin
if(shift) begin
	 nxt_shift_reg = {RX,shift_reg[8:1]};
end
else begin
	 nxt_shift_reg = shift_reg;
end
end




always_ff @(posedge clk) begin
shift_reg <= nxt_shift_reg;
end
assign rx_data = shift_reg[7:0];


state_t state, nxt_state;
logic set_rdy ;
always_comb begin
nxt_state = state;
receiving= 0;
set_rdy = 0;
unique case(state)
IDLE: if(start) begin
      
	  nxt_state = RCVNG;
	  end
RCVNG: begin
               
               receiving = 1;
               if(bit_cnt === 4'b1010) begin
               set_rdy = 1;
			   nxt_state = IDLE;
			   end
			   end
endcase
end


assign start = (state === IDLE && RX === 0)?1'b1:1'b0;

always_ff @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= nxt_state;
end     

always_ff @(posedge clk, negedge rst_n) begin

if(!rst_n)
rdy <= 1'b0;
else begin

	if(start | clr_rdy)
	rdy <= 1'b0;
	else if(set_rdy)
	rdy <= 1'b1;

end
end


endmodule







