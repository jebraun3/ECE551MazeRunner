module MtrDrv(lft_spd, vbatt, rght_spd, clk, rst_n, lftPWM1, lftPWM2, rghtPWM1, rghtPWM2);

input logic [11:0] vbatt;
input logic signed [11:0] lft_spd, rght_spd;
input logic clk, rst_n;
output logic lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;

logic signed [12:0] scale;

DutyScaleROM ROM(.clk(clk),.batt_level(vbatt[9:4]),.scale(scale));

logic signed [23:0] lft_prod , rght_prod;
logic [11:0] lft_duty , rght_duty;
assign lft_prod = scale * lft_spd;
assign rght_prod = scale * rght_spd;

logic signed [11:0] lft_scaled, rght_scaled;


logic signed [12:0]  lft_div, rght_div;

assign lft_div = lft_prod[23:11];

assign rght_div = rght_prod[23:11];



assign lft_scaled =  (lft_div[12] === 0 && lft_div[11])?12'b011111111111:
									 (lft_div[11] === 1 && (!lft_div[11]))?12'b100000000000:
										lft_div[11:0];
										
assign rght_scaled =  (rght_div[12] === 0 && rght_div[11])?12'b011111111111:
									 (rght_div[11] === 1 && (!rght_div[11]))?12'b100000000000:
										rght_div[11:0];										



assign lft_duty = lft_scaled + 12'h800;
assign rght_duty = 12'h800 - rght_scaled;
										
PWM12 lftPWM(.clk(clk),.rst_n(rst_n),.duty(lft_duty),.PWM1(lftPWM1),.PWM2(lftPWM2));

PWM12 rghtPWM(.clk(clk),.rst_n(rst_n),.duty(rght_duty),.PWM1(rghtPWM1),.PWM2(rghtPWM2));

endmodule