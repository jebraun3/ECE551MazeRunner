module SPI_mnrch(rst_n, clk,wrt, MISO, wt_data, MOSI, SCLK, SS_n, done, rd_data);


input logic wrt, MISO , clk , rst_n;
input [15:0] wt_data;
output logic MOSI, SCLK, SS_n, done;
output logic [15:0] rd_data;

typedef enum logic [1:0] {IDLE, FRONTPORCH ,TRANSACTION, BACKPORCH} state_t;
state_t state, nxt_state;

logic ld_SCLK;
logic [4:0] SCLK_div;
logic smpl, shft_imm, shft, init , set_done;
logic [3:0]bit_cnt;
logic MISO_smpl;
logic [15:0]shft_reg;
logic done15;


always_ff @(posedge clk) begin
	SCLK_div <= (ld_SCLK)?5'b10111:(SCLK_div+1);
end 

assign rd_data = shft_reg;

assign SCLK = SCLK_div[4];

//SM inputs from decoding ff outputs
assign smpl = (SCLK_div === 5'b01111)?1'b1:1'b0;
assign shft_imm = (SCLK_div === 5'b11111)?1'b1:1'b0;
assign done15 = (bit_cnt === 4'b1111);

//ff for bit counter
always_ff @(posedge clk) begin
	if(init)
		bit_cnt <= 4'b0000;
	else if(shft) 
		bit_cnt <=bit_cnt+1;
end

//ff and comb logic for sampled miso
always_ff @(posedge clk) begin
	MISO_smpl <= (smpl)?MISO:MISO_smpl;
end

//ff and comb logic for shift reg
always_ff @(posedge clk) begin
	shft_reg <= (init)?wt_data:
	            (shft)?{shft_reg[14:0],MISO_smpl}:shft_reg;
end

assign MOSI = shft_reg[15];

//state machine
always_comb begin
init = 0;
ld_SCLK = 0;
set_done = 0;
shft = 0;
nxt_state = state;
case(state)
IDLE:				begin
              ld_SCLK = 1;
              if(wrt) begin
              init = 1;
              nxt_state = FRONTPORCH;
              end
            end

FRONTPORCH:	begin
              if(shft_imm)
              nxt_state = TRANSACTION;
            end

TRANSACTION: begin
              if(done15) begin
              nxt_state = BACKPORCH;
             end
             else if(shft_imm) begin
              shft = 1;
              end
             end

BACKPORCH:   begin
              if(shft_imm) begin
              ld_SCLK = 1;
              shft = 1;
              set_done = 1;
              nxt_state = IDLE;
              end
            end
endcase
end

//State ff
always_ff @(posedge clk , negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;
end

//SR ff for SS_n
always_ff @(posedge clk , negedge rst_n) begin
	if(!rst_n)
		SS_n <= 1;
	else if(init)
		SS_n <= 0;
	else if(set_done)
		SS_n <= 1;
end

//SR ff for done
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		done <= 0;
	else if(init)
		done <= 0;
	else if(set_done)
		done <= 1;
end

endmodule
