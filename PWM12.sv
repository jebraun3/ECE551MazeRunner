module PWM12(clk,rst_n,duty,PWM1,PWM2);
input clk, rst_n;
input [11:0] duty;
output reg PWM1, PWM2;
reg [11:0] cnt;
localparam NONOVERLAP = 12'h02C;
logic S1,S2,R1,R2;

always_comb begin
S1 = 0;
R1 = 0;
S2 = 0;
R2 = 0;
if(cnt >= NONOVERLAP)
	S1 = 1;
if(cnt >= (duty+NONOVERLAP))
	S2 = 1;
if(cnt >= duty)
	R1 = 1;
if(&cnt)
	R2 = 1;

end











always_ff @(posedge clk, negedge rst_n) begin

if(!rst_n)
PWM1 <= 1'b0;
else begin

	if(R1)
	PWM1 <= 1'b0;
	else if(S1)
	PWM1 <= 1'b1;
    else
	PWM1 <= PWM1;
	
end
end



always_ff @(posedge clk, negedge rst_n) begin

if(!rst_n)
PWM2 <= 1'b0;
else begin

	if(R2)
	PWM2 <= 1'b0;
	else if(S2)
	PWM2 <= 1'b1;
    else
	PWM2 <= PWM2;
end
end







always_ff @(posedge clk , negedge rst_n) begin
if(!rst_n)
cnt = '0;
else
cnt = cnt + 1;
end



endmodule