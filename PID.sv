
////////// I Term ////////////////////////
module I_term(err_sat,moverflowing,hdng_vld,clk,rst_n,I_term);
	input signed [9:0]err_sat;
	input moverflowing,hdng_vld , clk, rst_n;
	output signed [11:0]I_term;

	logic signed [15:0]integrator;
	logic signed [15:0]nxt_integrator;
	logic signed [15:0]err_ext;
	logic signed [15:0]sum;
	logic overflow;
	logic update;

	assign err_ext = {{6{err_sat[9]}},err_sat[9:0]};
	assign sum = err_ext + integrator;

	assign overflow = (integrator[15] === err_ext[15] && err_ext[15] !== sum[15] )?1'b1:1'b0;
	assign update = (~overflow && hdng_vld)?1'b1:1'b0;

	assign nxt_integrator = (~moverflowing)?16'h0000:
													(update)?sum:integrator;
							
							
							
	assign I_term = integrator[15:4];
	
	
  //integrator reg
	always_ff @(posedge clk, negedge rst_n) begin
	 if (!rst_n)
		integrator <= 16'h0000;
	 else
		integrator <= nxt_integrator;
	end
 
endmodule
 

/////////////////// D_term /////////////////////////
module D_term(err_sat, hdng_vld, rst_n, clk ,D_term);

	input signed [9:0] err_sat;
	input hdng_vld, rst_n, clk;
	output signed [12:0] D_term;

	localparam signed [4:0]D_COEFF = 5'h0E;

	logic signed [9:0] d1;
	logic signed [9:0] d2;
	logic signed [9:0] q1;
	logic signed [9:0] q2;
	logic signed [10:0]diff;
	logic signed [7:0]diff_sat;

	assign d1 = (hdng_vld)?err_sat:q1;
	assign d2 = (hdng_vld)?q1:q2;


	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			q1 <= 0;
			q2 <= 0;
		end
		else begin
			q1 <= d1;
			q2 <= d2;
		end
	end

	assign diff = err_sat - q2;

	assign diff_sat = (diff[10] === 0 && |diff[9:7])?8'b01111111:
									  (diff[10] === 1 && !(&diff[9:7]))?8'b10000000:diff[7:0];
						
	assign D_term = diff_sat * D_COEFF;

endmodule

//////////////////////// P_term ///////////////////////////////

module P_term(error, P_term_out);
	input signed [11:0] error;
	output signed [13:0] P_term_out;
	localparam signed [3:0] P_COEFF = 4'h3;
	logic signed [9:0] err_sat;

	assign err_sat = (error[11] === 0 && |error[10:9])?10'b0111111111:
									 (error[11] === 1 && !(&error[10:9]))?10'b1000000000:
										error[9:0];

	assign P_term_out =  P_COEFF * err_sat;

endmodule

module PID(actl_hdng , dsrd_hdng , lft_spd , rght_spd , clk, rst_n ,moverflowing , hdng_vld, frwrd_spd , at_hdng);
	input signed [11:0] actl_hdng;
	input signed [11:0] dsrd_hdng;
	input signed [10:0] frwrd_spd;
	input clk, rst_n, moverflowing, hdng_vld;
	output signed [11:0] lft_spd;
	output signed [11:0] rght_spd;
	output at_hdng;


	localparam signed [9:0]low_err_pos = 10'b0000011110;
	localparam signed [9:0]low_err_neg = 10'b1111100010;
	logic signed [9:0] err_sat;
	logic signed [11:0] error;
	logic signed [13:0] P_term_out;
	logic signed [11:0] I_term_out;
	logic signed [12:0] D_term_out;

	logic signed [11:0] ext_frwrd_spd;

	logic signed [15:0] sum;

	logic signed [14:0] ext_P_term_out;
	logic signed [14:0] ext_D_term_out;
	logic signed [14:0] ext_I_term_out;

	assign error[11:0] = actl_hdng - dsrd_hdng;
	assign ext_frwrd_spd = {1'b0,frwrd_spd} ;
	assign err_sat = (error[11] === 0 && |error[10:9])?10'b0111111111:
									 (error[11] === 1 && !(&error[10:9]))?10'b1000000000:
										error[9:0];

	P_term P(.error(error) , .P_term_out(P_term_out));

	assign ext_P_term_out = {P_term_out[13],P_term_out} ;

	I_term I(.err_sat(err_sat),.moverflowing(moverflowing),.hdng_vld(hdng_vld),.clk(clk),.rst_n(rst_n),.I_term(I_term_out));

	assign ext_I_term_out = {{3{I_term_out[11]}},I_term_out} ;


	D_term D(.err_sat(err_sat), .hdng_vld(hdng_vld), .rst_n(rst_n), .clk(clk) ,.D_term(D_term_out));
	assign ext_D_term_out = {{2{D_term_out[12]}},D_term_out} ;

	assign sum = ext_D_term_out + ext_I_term_out + ext_P_term_out ;

	assign lft_spd =  (moverflowing)? sum[14:3] +  ext_frwrd_spd : 12'h000;

	assign rght_spd =  (moverflowing)?  ext_frwrd_spd - sum[14:3]: 12'h000;
	assign at_hdng = (err_sat < low_err_pos && err_sat > low_err_neg);


endmodule













































 
 