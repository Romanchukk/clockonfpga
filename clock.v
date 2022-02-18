module clock(i_sys_clk, i_key, o_hex0, o_hex1, o_hex2, o_hex3, o_hex4, o_hex5, o_led_red);

parameter       DIV_CONST = 50_000_000;

parameter [1:0] state_normal_mode = 2'b00, state_set_sec = 2'b01, 
                state_set_min = 2'b10, state_set_hour = 2'b11;

input           i_sys_clk;
input   [3:0]   i_key;
output  [6:0]   o_hex0, o_hex1, o_hex2, o_hex3, o_o_hex5, o_hex5;
output  [1:0]   o_led_red;

wire    [3:0]   sec0, sec1, min0, min1, hour0, hour1;

wire    [3:0]   s_sec0, s_sec1, s_min0, s_min1, s_hour0, s_hour1;

wire            sec0_to_sec1, sec1_to_min0, min0_to_min1, min1_to_hour0, hour0_to_hour1;
wire            set_overflow_sec, set_overflow_min, set_overflow_hour;
wire            tick_1hz;
wire            chng_time;

wire    [1:0]   sw_mode;

reg [23:0] time_reg;

wire sys_clk   = i_sys_clk;
wire sys_rst_n = i_key[0];
wire sys_mode  = i_key[1];

wire sys_switch_time = i_key[2];

wire clr_hrs = (8'h24 == {hour1, hour0});

assign o_led_red[1:0] = sw_mode;

counter  #(.MAX_VAL(3), .WIDTH(4) )           cnt_mode(.i_clk (~sys_mode), 
                                                        .i_rst_n (1'b1), 
                                                        .i_srst (1'b0),
                                                        .i_cnt_en (1'b1),
                                                        .i_load_en(1'b0),
																		                    .i_load_data(1'b0),
                                                        .o_data (sw_mode),
                                                        .o_tick ()
                                                       );

counter #(.MAX_VAL(DIV_CONST-1), .WIDTH(26) ) freq_div(.i_clk (sys_clk), 
                                                        .i_rst_n (sys_rst_n), 
                                                        .i_srst (1'b0),
                                                        .i_cnt_en (sw_mode == state_normal_mode),
                                                        .i_load_en(1'b0),
                                                        .i_load_data(1'b0),
                                                        .o_data (),
                                                        .o_tick (tick_1hz)
                                                       );

counter #(.MAX_VAL(9), .WIDTH(4) ) sec_0(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (1'b0),
                                          .i_cnt_en (tick_1hz), 
                                          .i_load_en(sw_mode == state_set_sec),
                                          .i_load_data(s_sec0),
                                          .o_data (sec0),
                                          .o_tick (sec0_to_sec1)
                                        );

counter #(.MAX_VAL(5), .WIDTH(4) ) sec_1(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (1'b0),
                                          .i_cnt_en (sec0_to_sec1),
                                          .i_load_en(sw_mode == state_set_sec),
                                          .i_load_data(s_sec1),
                                          .o_data(sec1), 
                                          .o_tick (sec1_to_min0)
                                        );

counter #(.MAX_VAL(9), .WIDTH(4) ) min_0(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (1'b0),
                                          .i_cnt_en (sec1_to_min0),
                                          .i_load_en(sw_mode == state_set_min),
                                          .i_load_data(s_min0), 
                                          .o_data(min0),
                                          .o_tick (min0_to_min1)
                                        );

counter #(.MAX_VAL(5), .WIDTH(4) ) min_1(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (1'b0),
                                          .i_cnt_en (min0_to_min1),
                                          .i_load_en(sw_mode == state_set_min),
                                          .i_load_data(s_min1), 
                                          .o_data(min1),
                                          .o_tick (min1_to_hour0)
                                        );

counter #(.MAX_VAL(9), .WIDTH(4) ) hour_0(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (clr_hrs),
                                          .i_cnt_en (min1_to_hour0),
                                          .i_load_en(sw_mode == state_set_hour),
                                          .i_load_data(s_hour0), 
                                          .o_data(hour0),
                                          .o_tick (hour0_to_hour1)
                                        );

counter #(.MAX_VAL(5), .WIDTH(4) ) hour_1(.i_clk (sys_clk), 
                                          .i_rst_n (sys_rst_n), 
                                          .i_srst (clr_hrs),
                                          .i_cnt_en (hour0_to_hour1),
                                          .i_load_en(sw_mode == state_set_hour),
                                          .i_load_data(s_hour1), 
                                          .o_data(hour1),
                                          .o_tick ()
                                        );

// Decoding secs, mins, hours from bin to 7-seg control signals

dec_7seg    dec_sec_0(.i_dat (sec0), 
                      .o_seg (o_hex0)
                      );

dec_7seg    dec_sec_1(.i_dat (sec1), 
                      .o_seg (o_hex1)
                      );

dec_7seg    dec_min_0(.i_dat (min0), 
                      .o_seg (o_hex2)
                      );

dec_7seg    dec_min_1(.i_dat (min1), 
                      .o_seg (o_hex3)
                      );

dec_7seg    dec_hour_0(.i_dat (hour0), 
                      .o_seg (o_o_hex5)
                      );

dec_7seg    dec_hour_1(.i_dat (hour1), 
                      .o_seg (o_hex5)
                      );

// Set mode
set_num #(.MAX_VAL(9), .WIDTH(4)) set_sec_0 (.i_inc(sys_switch_time),
                                            .i_en(sw_mode == state_set_sec),
                                            .i_rst(sys_rst_n),
                                            .o_data(s_sec0),
                                            .o_of(set_overflow_sec)
                                            );

set_num #(.MAX_VAL(5), .WIDTH(4)) set_sec_1 (.i_inc(set_overflow_sec),
                                            .i_en(sw_mode == state_set_sec),
                                            .i_rst(sys_rst_n),
                                            .o_data(s_sec1),
                                            .o_of()
                                            );

set_num #(.MAX_VAL(9), .WIDTH(4)) set_min_0 (.i_inc(sys_switch_time),
                                            .i_en(sw_mode == state_set_min),
                                            .i_rst(sys_rst_n),
                                            .o_data(s_min0),
                                            .o_of(set_overflow_min)
                                            );

set_num #(.MAX_VAL(5), .WIDTH(4)) set_min_1 (.i_inc(set_overflow_min),
                                             .i_en(sw_mode == state_set_min),
                                             .i_rst(sys_rst_n),
                                             .o_data(s_min1),
                                             .o_of()
                                            );

set_num #(.MAX_VAL(3), .WIDTH(4)) set_hour_0 (.i_inc(sys_switch_time),
                                              .i_en(sw_mode == state_set_hour),
                                              .i_rst(sys_rst_n),
                                              .o_data(s_hour0),
                                              .o_of(set_overflow_hour)
                                             );

set_num #(.MAX_VAL(2), .WIDTH(4)) set_hour_1 (.i_inc(set_overflow_hour),
                                              .i_en(sw_mode == state_set_hour),
                                              .i_rst(sys_rst_n),
                                              .o_data(s_hour1),
                                              .o_of()
                                             );

endmodule

