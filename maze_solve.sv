module maze_solve(cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt,sol_cmplt, clk, rst_n,
									strt_hdng, dsrd_hdng, strt_mv, stp_lft, stp_rght);

	input logic cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt, clk, rst_n;
	output logic strt_hdng, strt_mv, stp_lft, stp_rght;
	output logic [11:0] dsrd_hdng;

	logic change_hdng;
	logic [11:0] new_hdng;

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			dsrd_hdng <= '0;
		else if (change_hdng)
			dsrd_hdng <= new_hdng;
	end

	assign stp_lft = (cmd0)?1'b1:1'b0;
	assign stp_rght = ~stp_lft;


	typedef enum logic [2:0] {IDLE, WAIT_FRWRD, STRT_HDNG,STRT_MV, NEW_HDNG, WAIT_HDNG} state_t;

	state_t state, nxt_state;
	 
	always_comb begin
	nxt_state = state;
	change_hdng = 0;
	strt_hdng = 0;
	strt_mv = 0;
	new_hdng = '0;

	case (state)

	IDLE: begin
			if(!cmd_md) begin
				strt_mv = 1;
				nxt_state = WAIT_FRWRD;
			end
			end

	WAIT_FRWRD: begin
					if(mv_cmplt) begin
						nxt_state = NEW_HDNG;
					end
				end

	NEW_HDNG: begin
				if(sol_cmplt)
					nxt_state = IDLE;
				else if(cmd0) begin
					if(lft_opn) begin
						//turn left
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'h3FF:
											 (dsrd_hdng === 12'h3ff)?12'h7ff:
											 (dsrd_hdng === 12'h7ff)?12'hC00:12'h000;
											 
						nxt_state = STRT_HDNG;
					end
					else if (rght_opn) begin
						//turn right
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'hC00:
											 (dsrd_hdng === 12'hC00)?12'h7ff:
											 (dsrd_hdng === 12'h7ff)?12'h3ff:12'h000;
						nxt_state = STRT_HDNG;
					end
					else begin
						//pull a 180
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'h7ff:
											 (dsrd_hdng === 12'hC00)?12'h3ff:
											 (dsrd_hdng === 12'h7ff)?12'h000:12'hC00;;
						nxt_state = STRT_HDNG;
					end
				end
				else begin
					if(rght_opn) begin
					//turn right
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'hC00:
											 (dsrd_hdng === 12'hC00)?12'h7ff:
											 (dsrd_hdng === 12'h7ff)?12'h3ff:12'h000;
						nxt_state = STRT_HDNG;
					end
					else if (lft_opn) begin
						//turn left
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'h3FF:
											 (dsrd_hdng === 12'h3ff)?12'h7ff:
											 (dsrd_hdng === 12'h7ff)?12'hC00:12'h000;
						nxt_state = STRT_HDNG;
					end
					else begin
						//pull a 180
						change_hdng = 1;
						new_hdng = (dsrd_hdng === 12'h000)?12'h7ff:
											 (dsrd_hdng === 12'hC00)?12'h3ff:
											 (dsrd_hdng === 12'h7ff)?12'h000:12'hC00;;
						nxt_state = STRT_HDNG;
					end
				end
				end
	STRT_HDNG: begin
							strt_hdng = 1;
							nxt_state = WAIT_HDNG;
						end
	WAIT_HDNG: begin
							if(mv_cmplt) begin
							
							 nxt_state = STRT_MV;
							end
						end
	STRT_MV: begin
			strt_mv = 1;
			nxt_state = WAIT_FRWRD;
	end
	endcase
	end


	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end


endmodule