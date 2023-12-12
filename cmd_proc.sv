module cmd_proc(cmd, cmd_rdy, clk, rst_n, cal_done, sol_cmplt, mv_cmplt, dsrd_hdng, stp_lft, stp_rght,
								strt_mv,strt_hdng,cmd_md, strt_cal, clr_cmd_rdy, send_resp, in_cal);

	input logic [15:0] cmd;
	input logic cmd_rdy, clk, rst_n, cal_done, sol_cmplt, mv_cmplt;
	output logic [11:0] dsrd_hdng;
	output logic stp_lft, stp_rght, strt_mv, strt_hdng, cmd_md, strt_cal, clr_cmd_rdy, send_resp, in_cal;

	logic [11:0] new_hdng;
	logic new_stp_lft, new_stp_rght;

	//mux selects for ffs holding dsrd hdng, stp lft and stp rght
	logic change_dsrd_hdng, change_stp;


	typedef enum logic [1:0] {IDLE, WAIT_CAL, WAIT_MV, WAIT_SLV} state_t;

	state_t state , nxt_state;

	//ff to register drsd hdng
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			dsrd_hdng <= '0;
		else
			dsrd_hdng <= (change_dsrd_hdng)?new_hdng:dsrd_hdng;
	end

	//ff to register stp_left/right
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			stp_lft <= 0;
			stp_rght <= 0;
		end
		else begin
			stp_lft <= (change_stp)?new_stp_lft:stp_lft;
			stp_rght <= (change_stp)?new_stp_rght:stp_rght;
		end
	end
 
 //state ff
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
 
 //state machine
	always_comb begin
		nxt_state = state;
		change_dsrd_hdng = 0;
		strt_hdng = 0;
		cmd_md = 1;
		strt_cal = 0;
		clr_cmd_rdy = 0;
		in_cal = 0;
		send_resp = 0;
		new_hdng = '0;
		strt_mv = 0;
		case (state)
			IDLE:	begin
							if(cmd_rdy) begin
								clr_cmd_rdy = 1;
								if(cmd[15:13] === 3'b000) begin
									strt_cal = 1;
									nxt_state = WAIT_CAL;
								end
								else if(cmd[15:13] === 3'b001) begin
									new_hdng = cmd[11:0];
									change_dsrd_hdng = 1;
									strt_hdng = 1;
									nxt_state = WAIT_MV;
								end
								else if(cmd[15:13] === 3'b010) begin
									strt_mv = 1;
									change_stp = 1;
									new_stp_lft = cmd[1];
									new_stp_rght = cmd[0];
									nxt_state = WAIT_MV;
								end
								else if(cmd[15:13] === 3'b011) begin
									cmd_md = 0;
									nxt_state = WAIT_SLV;
								end
								else 
									nxt_state = state;
							end
						end
			
			WAIT_CAL: begin
									in_cal = 1;
									if(cal_done) begin
										send_resp = 1;
										nxt_state = IDLE;
									end
								end
									
			WAIT_MV:	begin
									if(mv_cmplt) begin
										send_resp = 1;
										nxt_state = IDLE;
									end
								end
			WAIT_SLV: begin
									cmd_md = 0;
									if(sol_cmplt) begin
										send_resp = 1;
										nxt_state = IDLE;
									end
								end
		endcase
	end

endmodule
