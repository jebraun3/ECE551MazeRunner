//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of mazeRunner.  Fusion correction     //
// comes from IR_Dtrm when en_fusion is high.   //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,IR_Dtrm,
                  SS_n,SCLK,MOSI,MISO,INT,moving,en_fusion);

  parameter FAST_SIM = 0;	// used to speed up simulation
  
  input logic clk, rst_n;
  input logic MISO;							// SPI input from inertial sensor
  input logic INT;							// goes high when measurement ready
  input logic strt_cal;						// initiate claibration of yaw readings
  input logic moving;							// Only integrate yaw when going
  input logic en_fusion;						// do fusion corr only when forward at decent clip
  input logic [8:0] IR_Dtrm;					// derivative term of IR sensors (used for fusion)
  
  output logic cal_done;				// pulses high for 1 clock when calibration done
  output logic signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output logic rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output logic SS_n,SCLK,MOSI;		// SPI outputs
 


	//////////////////////////////////////////////////////////////
  // Declare any needed internal signals that connect blocks //
  ////////////////////////////////////////////////////////////
  logic done;
  logic [15:0] inert_data;		// Data back from inertial sensor (only lower 8-bits used)
  logic signed [15:0] yaw_rt;
	
	//////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
  logic C_Y_H, C_Y_L, wrt, vld;
  logic  [15:0] wt_data;
  
	////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  logic [15:0] timer;
  logic [7:0] yawL;
  logic [7:0] yawH;
  logic ff1_INT, ff2_INT;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      timer <= '0;
    else
      timer <= timer + 1;
  end
  
  always_ff @(posedge clk) begin
    if(C_Y_L)
      yawL <= inert_data[7:0];
  end
  
  always_ff @(posedge clk) begin
    if(C_Y_H)
      yawH <= inert_data[7:0];
  end
  
  always_ff @(posedge clk) begin
		ff1_INT <= INT;
		ff2_INT <= ff1_INT;
  end
	
	assign yaw_rt = {yawH,yawL};
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum logic [2:0] {INIT1, INIT2,INIT3, WAIT,READH, READL, DONE} state_t; 
  state_t state, nxt_state;
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
                 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rd_data(inert_data),.wt_data(wt_data));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and gaurdrail info and produces a heading reading            //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),
                        .vld(vld),.rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),
						.en_fusion(en_fusion),.IR_Dtrm(IR_Dtrm),.heading(heading));
	

  //state machine
  always_comb begin
  nxt_state = state;
  C_Y_H = 0;
  C_Y_L = 0;
  wrt = 0;
  vld = 0;
  wt_data = 16'h0000;
  
  case (state)
  
  INIT1: begin
          wt_data = 16'h0D02;
          if(&timer) begin
            wrt = 1;
            nxt_state = INIT2;
          end
         end
  INIT2: begin
          wt_data = 16'h1160;
          if(done) begin 
						wrt = 1;
						nxt_state = INIT3;
          end
         end
  INIT3: begin
          wt_data = 16'h1440;
          if(done) begin 
						wrt = 1;
						nxt_state = WAIT;
          end
				 end
  
  WAIT:  begin
          if(ff2_INT) begin
            wt_data = 16'hA700;
            wrt = 1;
            nxt_state = READH;
          end
				 end
  
  
  READH: begin
          if(done) begin
						C_Y_H = 1;
						wt_data = 16'hA600;
						wrt = 1;
						nxt_state = READL;
          end
         end
  
	READL: begin
          if(done) begin
						C_Y_L = 1;
						nxt_state = DONE;
          end
         end
  
	DONE:  begin
          vld = 1;
          nxt_state = WAIT;
         end 
	
	default: nxt_state = INIT1;
  endcase
  end
          
  always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= INIT1;
	else
		state <= nxt_state;
  end
  
 
endmodule
	  