module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output reg [7:0] candidate;

parameter WAIT = 3'b000;
parameter GETDATA = 3'b001;
parameter GC_TEMP = 3'b010;
parameter CALCULATE = 3'b011;
parameter CALCULATE_mode = 3'b100;
parameter RETURN = 3'b101;
integer i;
reg finish_calculate, finish_calculate_mode,point_exist;
reg [2:0] map [1:64];
reg [6:0] rA, rB, rC, radius_;
reg [1:0] mode_, calculate_order;
reg [2:0] state, nextState;
reg [3:0] x, y, cx, cy, xA, xB, xC, yA, yB, yC;
reg [6:0] count, pre_position;
wire [6:0] position;
wire [6:0] multi2x_0, multi2x_1;
wire in, a, b, c, mode_1, mode_2, mode_3;
wire [7:0] multi2x;
assign position = x + (y - 1)* 8;
assign multi2x_0 = x - cx;
assign multi2x_1 = y - cy; 
assign multi2x = multi2x_0**2 + multi2x_1**2;
assign a = map[position][0];
assign b = map[position][1];
assign c = map[position][2];
assign mode_1 = (a & b);
assign mode_2 = (a | b) ? !(a & b): 0;
assign mode_3 = ((a & b) | (b & c) | (a & c)) ? !(a & b & c) : 0;
assign busy = !(state == WAIT);
assign valid = (state == RETURN);
assign in = (multi2x <= radius_);
always@(position)begin
	case(mode_)
		0:point_exist = map[position][0];
		1:point_exist = mode_1;
		2:point_exist = mode_2;
		3:point_exist = mode_3;
	endcase
end
always@(*)begin
	if(rst)begin
		for(i = 1;i <=64;i =i+ 1)begin
			map[i] = 3'd0;
		end
	end
	else 
		case(calculate_order)
			0:map[position][0] = in;
			1:map[position][1] = in;
			2:map[position][2] = in;
		endcase
end
always@(*)begin
	case(calculate_order)
		0:begin
			radius_ = rA;
			cx = xA;
			cy = yA;
		end
		1:begin			
			radius_ = rB;
			cx = xB;
			cy = yB;
		end
		2:begin
			radius_ = rC;
			cx = xC;
			cy = yC;
		end
	endcase
end

always@(state, finish_calculate, finish_calculate_mode, en)begin
	case(state)
		WAIT:
			if(en)
				nextState = GETDATA;
			else
				nextState = WAIT;
		GETDATA:
			nextState = GC_TEMP;
		GC_TEMP:
			nextState = CALCULATE;
		CALCULATE:
			if(finish_calculate)
				nextState = CALCULATE_mode;
			else
				nextState = CALCULATE;
		CALCULATE_mode:
			if(finish_calculate_mode)
				nextState = RETURN;
			else
				nextState = CALCULATE_mode;
		RETURN:
			nextState = WAIT;
	endcase
end
always@(posedge clk)begin
	if(rst)
		state <= 0;
	else
		state <= nextState;
end

always@(posedge clk)begin
	finish_calculate <= 0;
	finish_calculate_mode <= 0;
	
	if(rst)begin
		x <= 1;
		y <= 1;
		calculate_order <= 0;
		candidate <= 0;
		
	end
	else
		case(state)
			GETDATA:begin
				xA <= central[23:20];
				yA <= central[19:16];
				xB <= central[15:12];
				yB <= central[11:8];
				xC <= central[7:4];
				yC <= central[3:0];
				mode_ <= mode;
				rA <= radius[11:8] * radius[11:8];
				rB <= radius[7:4] * radius[7:4];
				rC <= radius[3:0] * radius[3:0];
				calculate_order <= 0;
			end
			
			CALCULATE:begin
				
				if(x == 8 && y == 8)begin
					
					x <= 1;
					y <= 1;
					if(calculate_order == 2)
						finish_calculate <= 1;
					else
						calculate_order <= calculate_order + 1;
				end
				else if(x == 8)begin
					x <= 1;
					y <= y + 1;
				end
				else
					x <= x + 1;
				
			end
			CALCULATE_mode:begin
				finish_calculate_mode <= 0;
				candidate <= candidate + point_exist;
				if(x == 8 && y == 8)begin
					finish_calculate_mode <= 1;
					x <= 1;
					y <= 1;
				end
				else if(x == 8)begin
					x <= 1;
					y <= y + 1;
					
				end
				else
					x <= x + 1;
			end
			RETURN:begin
				candidate <= 0;
				
				x <= 1;
				y <= 1;
				

			end
		endcase
end
endmodule