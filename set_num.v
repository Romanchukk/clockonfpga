module set_num(i_inc, i_en, i_rst, o_data, o_of);

parameter MAX_VAL = 9, WIDTH = 4;

input i_inc;
input i_en;
input i_rst;

output [WIDTH-1:0] o_data;
output o_of;

wire sys_rst_cnt = (MAX_VAL == counter);

reg [WIDTH-1:0] counter;

assign  o_of   = sys_rst_cnt;
assign  o_data = (MAX_VAL+1 == counter) ? 4'd0 : counter;

always @(negedge i_inc, negedge i_rst) begin
    if (~i_rst)
        counter <= 0;
    else if (sys_rst_cnt)
        counter <= 0;
    else if (i_en)
        counter <= counter + 1'b1;
end

endmodule