module UART_tx(clk , rst_n ,trmt , tx_data, tx_done, TX);
input clk, trmt, rst_n ;
input [7:0] tx_data;
output TX ;
output reg tx_done;

typedef enum logic {IDLE , TRANSMITTING} state_t;

logic init, shift ,transmitting;
logic [3:0] bit_cnt;
logic [3:0] nxt_bit_cnt;
logic [11:0] baud_cnt;
logic [11:0] nxt_baud_cnt;
logic [8:0] shift_reg;
logic [8:0] nxt_shift_reg;

always_comb begin
priority case ({init,shift}) inside
2'b1x: nxt_bit_cnt = '0;
2'b01: nxt_bit_cnt = bit_cnt + 1;
2'b00: nxt_bit_cnt = bit_cnt;
endcase
end


always_ff @(posedge clk) begin
bit_cnt <= nxt_bit_cnt;
end


always_comb begin
priority case ({(init || shift),transmitting}) inside
2'b1x: nxt_baud_cnt = '0;
2'b01: nxt_baud_cnt = baud_cnt + 1;
2'b00: nxt_baud_cnt = baud_cnt;
endcase
end

always_ff @(posedge clk) begin
baud_cnt <= nxt_baud_cnt;
end

assign shift = (baud_cnt === 12'hA2C)?1'b1:1'b0;

always_comb begin
priority case ({init,shift}) inside
2'b1x: nxt_shift_reg = {tx_data,1'b0};
2'b01: nxt_shift_reg = {1'b1,shift_reg[8:1]};
2'b00: nxt_shift_reg = shift_reg;
endcase
end

always_ff @(posedge clk , negedge rst_n) begin
if(!rst_n)
shift_reg = '1;
else
shift_reg = nxt_shift_reg;
end

assign TX = shift_reg[0];

state_t state, nxt_state;
logic setdone;
always_comb begin
nxt_state = state;
init = 0;
transmitting = 0;
setdone = 0;
unique case(state)
IDLE: if(trmt) begin
      init = 1;
	  nxt_state = TRANSMITTING;
	  end
TRANSMITTING: begin
               init = 0;
               transmitting = 1;
               if(bit_cnt === 4'b1010) begin
               setdone = 1;
			   nxt_state = IDLE;
			   end
			   end
endcase
end
			   
always_ff @(posedge clk, negedge rst_n) begin
if(!rst_n)
state <= IDLE;
else
state <= nxt_state;
end     
 
always_ff @(posedge clk, negedge rst_n) begin

if(!rst_n)
tx_done <= 1'b0;
else begin

	if(init)
	tx_done <= 1'b0;
	else if(setdone)
	tx_done <= 1'b1;

end
end

endmodule
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 





