module IR_math(lft_opn, rght_opn,lft_IR,rght_IR, IR_Dtrm,en_fusion,dsrd_hdng,dsrd_hdng_adj);

parameter NOM_IR = 12'h970;

input signed  lft_opn , rght_opn;
input   [11:0]lft_IR;
input   [11:0]rght_IR;
input signed  [8:0]IR_Dtrm;
input signed  en_fusion;
input signed  [11:0]dsrd_hdng;
output signed  [11:0]dsrd_hdng_adj;


logic signed [12:0] diff_lftright;
logic signed [12:0] diff_lftNOM;
logic signed [12:0] diff_NOMright;

logic signed [11:0]mux0;
logic signed [11:0]mux1;
logic signed [11:0]mux2;

assign diff_lftright = lft_IR - rght_IR;
assign diff_lftNOM = lft_IR - NOM_IR;
assign diff_NOMright = NOM_IR - rght_IR;

assign mux0 = (rght_opn)?diff_lftNOM[11:0]:diff_lftright[12:1];
assign mux1 = (lft_opn)?diff_NOMright[11:0]:mux0;
assign mux2 = (lft_opn&&rght_opn)?12'h000:mux1;

logic signed [12:0]extmux2;
assign extmux2 = {{6{mux2[11]}},mux2[11:5]};
logic signed [12:0]extIR_Dtrm;
assign extIR_Dtrm =  {{4{IR_Dtrm[8]}},IR_Dtrm[6:0],2'b00};
logic [12:0]sum_extmux2_extDterm;

assign sum_extmux2_extDterm = extIR_Dtrm + extmux2;
logic signed [12:0]div2sum_extmux2_extDterm;
assign div2sum_extmux2_extDterm = {sum_extmux2_extDterm[12],sum_extmux2_extDterm[12:1]};
logic signed [12:0]fin; 
assign fin = div2sum_extmux2_extDterm + dsrd_hdng;
assign dsrd_hdng_adj = (en_fusion)?fin[11:0]:dsrd_hdng;












endmodule

