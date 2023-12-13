module MazeRunner_tb();

 // << optional include or import >>
  
  reg clk,RST_n;
  reg send_cmd;					// assert to send command to MazeRunner_tb
  reg [15:0] cmd;				// 16-bit command to send
  reg [11:0] batt;				// battery voltage 0xDA0 is nominal
  
  logic cmd_sent;				
  logic resp_rdy;				// MazeRunner has sent a pos acknowledge
  logic [7:0] resp;				// resp byte from MazeRunner (hopefully 0xA5)
  logic hall_n;					// magnet found?
  
  /////////////////////////////////////////////////////////////////////////
  // Signals interconnecting MazeRunner to RunnerPhysics and RemoteComm //
  ///////////////////////////////////////////////////////////////////////
  wire TX_RX,RX_TX;
  wire INRT_SS_n,INRT_SCLK,INRT_MOSI,INRT_MISO,INRT_INT;
  wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;
  wire IR_lft_en,IR_cntr_en,IR_rght_en;  
  
  localparam FAST_SIM = 1'b1;

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  MazeRunner iDUT(.clk(clk),.RST_n(RST_n),.INRT_SS_n(INRT_SS_n),.INRT_SCLK(INRT_SCLK),
                  .INRT_MOSI(INRT_MOSI),.INRT_MISO(INRT_MISO),.INRT_INT(INRT_INT),
				  .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),
				  .A2D_MISO(A2D_MISO),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
				  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.RX(RX_TX),.TX(TX_RX),
				  .hall_n(hall_n),.piezo(),.piezo_n(),.IR_lft_en(IR_lft_en),
				  .IR_rght_en(IR_rght_en),.IR_cntr_en(IR_cntr_en),.LED());
	
  ///////////////////////////////////////////////////////////////////////////////////////
  // Instantiate RemoteComm which models bluetooth module receiving & forwarding cmds //
  /////////////////////////////////////////////////////////////////////////////////////
  RemoteComm iCMD(.clk(clk), .rst_n(RST_n), .RX(TX_RX), .TX(RX_TX), .cmd(cmd), .send_cmd(send_cmd),
               .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
			   
				  
  RunnerPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(INRT_SS_n),.SCLK(INRT_SCLK),.MISO(INRT_MISO),
                      .MOSI(INRT_MOSI),.INT(INRT_INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),
                     .IR_lft_en(IR_lft_en),.IR_cntr_en(IR_cntr_en),.IR_rght_en(IR_rght_en),
					 .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),
					 .A2D_MISO(A2D_MISO),.hall_n(hall_n),.batt(batt));
	
  
					 
  initial begin
	batt = 12'hFFF;  	// this is value to use with RunnerPhysics

   //reset
   clk = 0;
   RST_n = 0;
   @(posedge clk);
   @(negedge clk);
   RST_n = 1;

   //calibrate command test
   cmd = 16'h0000;
   send_cmd = 1;
   @(negedge clk);
   send_cmd = 0;
   
   fork
   begin: timeout1
   repeat(80000) @(posedge clk);
   end
    begin
      @(posedge iDUT.iNEMO.cal_done);
      @(posedge resp_rdy);
      if(resp !== 8'hA5) begin
        $display("unexpected response from calibration");
        $stop();
      end
      disable timeout1;
      $display("Calibration test passed");

    end
    join
    
    batt = 12'hDFF;
    



   @(posedge clk);
   @(negedge clk);

   
   
   //change heading command
   
   cmd = 16'h23FF;
   send_cmd = 1;
   @(negedge clk);
   send_cmd = 0;
    //do self check
    fork 
      begin : timeout2
        repeat(1000000) begin
          @(posedge clk);
          @(negedge clk);
        end
        $display("change heading command timed out");
        $stop();
      end
      begin
        @(posedge iDUT.iCNTRL.at_hdng)
        if (iPHYS.heading_robot[19:16] !== 4'h3 && iPHYS.heading_robot[19:16] !== 4'h4) begin
          $display("heading not similar to requested heading");
          $stop();
        end
        @(posedge resp_rdy);
        if(resp !== 8'hA5) begin
          $display("unexpected response from change heading");
          $stop();
        end
        
        $display("change heading test 1 passed");
        disable timeout2;
      end
    join
   
   @(posedge clk);
   @(negedge clk);
  
  
  batt = 12'hDA0;
  //change heading command
   
   cmd = 16'h2000;
   send_cmd = 1;
   @(negedge clk);
   send_cmd = 0;
   fork 
      begin : timeout3
        repeat(1000000) begin
          @(posedge clk);
          @(negedge clk);
        end
        $display("change heading command timed out");
        $stop();
      end
      begin
     @(posedge iDUT.iCNTRL.at_hdng)
        if (iPHYS.heading_robot[19:16] !== 4'hF && iPHYS.heading_robot[19:16] !== 4'h0) begin
          $display("heading not similar to requested heading");
          $stop();
        end
        @(posedge resp_rdy);
        if(resp !== 8'hA5) begin
          $display("unexpected response from change heading");
          $stop();
        end
        
        $display("change heading test 2 passed");
        disable timeout3;
      end
    join

   @(posedge clk);
   @(negedge clk);

  //move command to stop at left opening
  cmd = 16'h4002;
  send_cmd = 1;
  @(negedge clk);
   send_cmd = 0;
  fork 
      begin : timeout4
        repeat(1000000) begin
          @(posedge clk);
          @(negedge clk);
        end
        $display("change heading command timed out");
        $stop();
      end
      begin
        @(posedge resp_rdy);
        if(resp !== 8'hA5) begin
          $display("unexpected response from move");
          $stop();
        end
        if (iPHYS.xx[14:12] !== 3'b010) begin
          $display("x position not correct");
          $stop();
        end
         if (iPHYS.yy[14:12] !== 3'b001) begin
          $display("y position not correct");
          $stop();
        end
        $display("move test passed");
        disable timeout4;
      end
    join
   
   @(posedge clk);
   @(negedge clk);
   //maze solve command with right affinity
    cmd = 16'h6000;
    send_cmd = 1;
    @(posedge clk);
    @(negedge clk);
    send_cmd = 0;
   
 
  
  fork 
      begin : timeout5
        repeat(60000000) begin
          @(posedge clk);
          @(negedge clk);
        end
        $display("maze solve command timed out");
        $stop();
      end
      begin
        @(posedge resp_rdy);
        if(resp !== 8'hA5) begin
          $display("unexpected response from maze solve");
          $stop();
        end
        if (iPHYS.xx[14:12] !== 3'b001) begin
          $display("x position not correct");
          $stop();
        end
         if (iPHYS.yy[14:12] !== 3'b000) begin
          $display("y position not correct");
          $stop();
        end
        $display("maze solve test passed");
        disable timeout5;
      end
    join

  @(posedge clk);
   @(negedge clk);
 
  //low battery
  batt = 12'h001;


  fork 
      begin : timeout6
        repeat(1000000) begin
          @(posedge clk);
          @(negedge clk);
        end
        $display("batt_low timed out");
        $stop();
      end
      begin
          @(iDUT.ICHRG.batt_low)
          $display("batt_low test passed");
          disable timeout6;
      end
    join
 

 

  $display("yahooooooooo!");
  $stop();



  end
  
  always
    #5 clk = ~clk;
	
endmodule