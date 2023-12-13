module piezo_drv(clk, rst_n, batt_low, fanfare, piezo, piezo_n);

  parameter FAST_SIM = 1;
  input logic clk, rst_n, batt_low, fanfare;
  output logic piezo, piezo_n;

  logic [23:0] dur_cnt;
  logic [14:0] freq_cnt;
  logic rst_dur, rst_freq;
  typedef enum logic[3:0] {IDLE, G6, G7,C7,E7, E7_LOWBAT, G6_LOWBAT, C7_LOWBAT, G7_2, E7_2} state_t;

  always_ff @(posedge clk) begin
    if(rst_dur)
      dur_cnt <= '0;
    else
      dur_cnt <= (FAST_SIM)? dur_cnt + 16: dur_cnt + 1;
  end

  always_ff @(posedge clk) begin
    if(rst_freq)
      freq_cnt <= '0;
    else
      freq_cnt <= (FAST_SIM)? freq_cnt + 16: freq_cnt + 1;
  end





  state_t state, nxt_state;
  always_comb begin
    piezo = 0;
    nxt_state = state;
    rst_freq = 0;
    rst_dur = 0;
    case (state)

    IDLE: begin
      if(batt_low) begin
        nxt_state = G6_LOWBAT;
        rst_freq = 1;
        rst_dur = 1;
      end
      else if (fanfare) begin
        nxt_state = G6;
        rst_freq = 1;
        rst_dur = 1;
      end
    end

    G6_LOWBAT:  begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq = 1;
        nxt_state = C7_LOWBAT;
      end
      else if(freq_cnt < 16000)
        piezo = 1;
      else if(freq_cnt > 31888) begin
        rst_freq = 1;
      end 
    end	

    C7_LOWBAT: begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq =1;
        nxt_state = E7_LOWBAT;
      end
      else if(freq_cnt < 12000)
        piezo = 1;
      else if(freq_cnt > 23890) begin
        rst_freq = 1;
      end 
    end

    E7_LOWBAT:  begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq =1;
        nxt_state = IDLE;
      end
      else if(freq_cnt < 9500)
        piezo = 1;
      else if(freq_cnt > 18960) begin
        rst_freq = 1;
      end 
    end
    
    G6:	begin
      if(dur_cnt > 8388608) begin
        rst_dur = 1;
        rst_freq = 1;
        nxt_state = C7;
      end
      else if(freq_cnt < 16000)
          piezo = 1;
      else if(freq_cnt > 31888) begin
          rst_freq = 1;
      end 
    end
    
    C7:	begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq =1;
        nxt_state = E7;
      end
      else if(freq_cnt < 12000)
        piezo = 1;
      else if(freq_cnt > 23890) begin
        rst_freq = 1;
      end 
    end
    
    E7: begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq =1;
        nxt_state = G7;
      end
      else if(freq_cnt < 9500)
        piezo = 1;
      else if(freq_cnt > 18960) begin
        rst_freq = 1;
      end 
    end

    G7: begin
      if(dur_cnt > 12582912) begin
        rst_dur = 1;
        rst_freq = 1;
        nxt_state = E7_2;
      end
      else if(freq_cnt < 7971)
          piezo = 1;
      else if(freq_cnt > 15943) begin
          rst_freq = 1;
      end 
    end
    
    E7_2:	begin
      if (dur_cnt >= 8388608) begin
        rst_dur = 1;
        rst_freq =1;
        nxt_state = G7_2;
      end
      else if(freq_cnt < 9500)
        piezo = 1;
      else if(freq_cnt > 18960) begin
        rst_freq = 1;
      end 
    end
    
    G7_2:begin
      if(dur_cnt > 12582912) begin
        rst_dur = 1;
        rst_freq = 1;
        nxt_state = IDLE;
      end
      else if(freq_cnt < 7971)
          piezo = 1;
      else if(freq_cnt > 15943) begin
          rst_freq = 1;
      end 
    end
    
    default: nxt_state = IDLE;
  endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  assign piezo_n = ~piezo;
endmodule





			