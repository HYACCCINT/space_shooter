module draw
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        draw_en,
		plot_x,
		plot_y,
		colour_in,
		resetn,
		shape,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input CLOCK_50;	
	input draw_en;
	input resetn;
	input [1 : 0] shape;
	input [2 : 0] colour_in;
	input [7 : 0] plot_x;
	input [6 : 0] plot_y;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;



	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	 wire update, end_h;
	 wire [4 : 0] add_xy;
	 wire [7:0] x_1p_16p;
	wire [6:0] y_1p_16p;
	 
	 assign x = x_1p_16p;
	 assign y = y_1p_16p;
	 assign colour = colour_in;
	shape_1p_16p sss(
		.select(shape[0]),
		.clk(CLOCK_50),
		.update(update),
		.resetn(resetn),
		.xy_add(add_xy),
		.end_h(end_h)
		);

	control_1p_16p c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.draw_en(draw_en),
		.end_h(end_h),
		.xy_add01(add_xy),
		.start_x(plot_x),
		.start_y(plot_y),
		.plot(writeEn),
		.x(x_1p_16p),
		.y(y_1p_16p),
		.update(update)
	 //output [2:0] color_out
    );
endmodule

module shape_1p_16p(
	input reg select,
	input clk,
	input update,
	input resetn,
	output reg [4 : 0] xy_add,
	output reg end_h);

	
	always @(posedge clk)
	begin
		if (~resetn) begin
			xy_add <= 0;
			end_h <= 0;
			end
		if (update) begin
			case (select)
				1'b0: begin // 4 pixels square
					if (xy_add[4]) begin
						xy_add <=0;
						end_h <= 1'b1;
						end
					else
						xy_add <= xy_add + 1'b1;
					end
				1'b1: begin // one pixel
					if (xy_add[0]) begin
						xy_add <= 0;
						end_h <= 1'b1;
						end
					else
						xy_add <= xy_add + 1'b1;
					end
			endcase
		end
	end

endmodule

module control_1p_16p(
    input clk,
    input resetn,
	 input draw_en,
	 input end_h,
	 input [4 : 0] xy_add01,
	 input [7 : 0] start_x,
    input [6 : 0] start_y,
	 output reg  plot,
	 output reg [7:0] x,
	 output reg [6:0] y,
	 output reg update
	 //output [2:0] color_out
    );

	 reg [7 : 0] org_x;
	 reg [6 : 0] org_y;
    reg [1:0] current_state, next_state;
	
    
    localparam  S_LOAD_XY       = 2'd0,
                S_LOAD_XY_WAIT  = 2'd1,
                S_PLOT_XY       = 2'd2,
					 S_UPDATE_XY     = 2'd3;

    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_XY: next_state = draw_en ? S_LOAD_XY_WAIT : S_LOAD_XY; // Loop in current state until value is input
                S_LOAD_XY_WAIT: next_state = S_PLOT_XY; // Loop in current state until go signal goes low
                S_PLOT_XY: next_state = S_UPDATE_XY; 
					 S_UPDATE_XY: next_state = end_h ? S_LOAD_XY : S_PLOT_XY; 

            default:     next_state = S_LOAD_XY;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
	always @(posedge clk)
   begin
		if(!resetn)
			current_state <= S_LOAD_XY;
      else begin
			update <= 1'b0;
			case (current_state)
				S_LOAD_XY_WAIT: begin
					org_x <= start_x;
					org_y <= start_y;
					end
				S_PLOT_XY: begin 
					plot <= 1'b1; 
					update <= 1'b1;
					end
				S_UPDATE_XY: begin
					x <= org_x + xy_add01[3:2];
					y <= org_y + xy_add01[1:0];
					end
			endcase

         current_state <= next_state;
		end
	end
		
        

endmodule


module control_ani(
    input clk,
    input resetn,

    output reg  ld_x, ld_y,
    output reg  ld_alu_out,
	 output reg  plot,
	 output reg [1:0] alu_op,
	 
	 input draw_en
    );

    reg [5:0] current_state, next_state; 
    
    localparam  S_LOAD_XY       = 6'd0,
                S_LOAD_XY_WAIT   = 6'd1,
                S_PLOT_XY       = 6'd4,
					 S_PLOT_X1Y      = 6'd5,
					 S_PLOT_X2Y      = 6'd6,
					
					 S_PLOT_X3Y      = 6'd7,
					 S_PLOT_X3Y1     = 6'd8,
					 S_PLOT_X2Y1     = 6'd9,
					 S_PLOT_X1Y1     = 6'd10,
					 
					 S_PLOT_XY1      = 6'd11,
					 S_PLOT_XY2      = 6'd12,
					 S_PLOT_X1Y2     = 6'd13,
					 S_PLOT_X2Y2     = 6'd14,
					 
					 S_PLOT_X3Y2     = 6'd15,
					 S_PLOT_X3Y3     = 6'd16,
					 S_PLOT_X2Y3     = 6'd17,
					 S_PLOT_X1Y3     = 6'd18,
					 S_PLOT_XY3      = 6'd19,
					 
					 S_PLOT_X1YG      = 6'd21,
					 S_PLOT_X2YG      = 6'd22,
					
					 S_PLOT_X3YG      = 6'd23,
					 S_PLOT_X3Y1G     = 6'd24,
					 S_PLOT_X2Y1G     = 6'd25,
					 S_PLOT_X1Y1G     = 6'd26,
					 
					 S_PLOT_XY1G      = 6'd27,
					 S_PLOT_XY2G      = 6'd28,
					 S_PLOT_X1Y2G     = 6'd29,
					 S_PLOT_X2Y2G     = 6'd30,
					 
					 S_PLOT_X3Y2G     = 6'd31,
					 S_PLOT_X3Y3G     = 6'd32,
					 S_PLOT_X2Y3G     = 6'd33,
					 S_PLOT_X1Y3G     = 6'd34,
					 S_PLOT_XY3G      = 6'd35;
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_XY: next_state = draw_en ? S_LOAD_XY_WAIT : S_LOAD_XY; // Loop in current state until value is input
                S_LOAD_XY_WAIT: next_state = S_PLOT_XY; // Loop in current state until go signal goes low
                S_PLOT_XY: next_state = S_PLOT_X1YG; 
				
				S_PLOT_X1YG: next_state = S_PLOT_X1Y;
				S_PLOT_X1Y: next_state = S_PLOT_X2YG;
					 
				S_PLOT_X2YG: next_state = S_PLOT_X2Y; 
				S_PLOT_X2Y: next_state = S_PLOT_X3YG; 
					 
				S_PLOT_X3YG: next_state = S_PLOT_X3Y;
				S_PLOT_X3Y: next_state = S_PLOT_X3Y1G;
					 
				S_PLOT_X3Y1G: next_state = S_PLOT_X3Y1;
				S_PLOT_X3Y1: next_state = S_PLOT_X2Y1G;
					 
				S_PLOT_X2Y1G: next_state = S_PLOT_X2Y1;
				S_PLOT_X2Y1: next_state = S_PLOT_X1Y1G;
					 
				S_PLOT_X1Y1G: next_state = S_PLOT_X1Y1;
				S_PLOT_X1Y1: next_state = S_PLOT_XY1G;
					 
				S_PLOT_XY1G: next_state = S_PLOT_XY1;
				S_PLOT_XY1: next_state = S_PLOT_XY2G;
					 
				S_PLOT_XY2G: next_state = S_PLOT_XY2;
				S_PLOT_XY2: next_state = S_PLOT_X1Y2G;
					 
				S_PLOT_X1Y2G: next_state = S_PLOT_X1Y2;
				S_PLOT_X1Y2: next_state = S_PLOT_X2Y2G;
					 
				S_PLOT_X2Y2G: next_state = S_PLOT_X2Y2;
				S_PLOT_X2Y2: next_state = S_PLOT_X3Y2G;
					 
				S_PLOT_X3Y2G: next_state =  S_PLOT_X3Y2;
				S_PLOT_X3Y2: next_state =  S_PLOT_X3Y3G;
					 
				S_PLOT_X3Y3G: next_state =  S_PLOT_X3Y3;
				S_PLOT_X3Y3: next_state =  S_PLOT_X2Y3G;
					 
				S_PLOT_X2Y3G: next_state =  S_PLOT_X2Y3;
				S_PLOT_X2Y3: next_state =  S_PLOT_X1Y3G;
					 
				S_PLOT_X1Y3G: next_state =  S_PLOT_X1Y3;
				S_PLOT_X1Y3: next_state =  S_PLOT_XY3G;
					 
				S_PLOT_XY3G: next_state = S_PLOT_XY3;
				S_PLOT_XY3: next_state = S_LOAD_XY;
					 
            default:     next_state = S_LOAD_XY;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_alu_out = 1'b0;
        ld_x = 1'b0;
        ld_y = 1'b0;
		  plot = 1'b0;
		  alu_op = 2'b00;

        case (current_state)
            S_LOAD_XY_WAIT: begin
                ld_x = 1'b1;
				ld_y = 1'b1;
                end
            S_PLOT_XY: begin 
                plot = 1'b1; // plot X,Y
					 alu_op = 2'b00;
					 end
			S_PLOT_X1YG: begin 
				ld_alu_out = 1'b1; ld_x = 1'b1;
				end

			S_PLOT_X1Y: begin 
                plot = 1'b1; 
				alu_op = 2'b00;
				end
			S_PLOT_X2YG: begin 
				ld_alu_out = 1'b1; ld_x = 1'b1;
				end

			S_PLOT_X2Y: begin 
                plot = 1'b1;
				alu_op = 2'b00;
				end

			S_PLOT_X3YG: begin
				ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X3Y: begin
                plot = 1'b1; 
				alu_op = 2'b10;
				end

			S_PLOT_X3Y1G: begin 
				ld_alu_out = 1'b1; ld_y = 1'b1;
				end
			S_PLOT_X3Y1: begin 
                plot = 1'b1;
				alu_op = 2'b01; 
				end
					 
			S_PLOT_X2Y1G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X2Y1: begin 
                plot = 1'b1;
				alu_op = 2'b01; 
				end
			S_PLOT_X1Y1G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X1Y1: begin 
                plot = 1'b1;
				alu_op = 2'b01; 
				end
				
			S_PLOT_XY1G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_XY1: begin 
                plot = 1'b1;
				alu_op = 2'b10; 
				end
				

			S_PLOT_XY2G: begin 
                ld_alu_out = 1'b1; ld_y = 1'b1;
				end
			S_PLOT_XY2: begin 
                plot = 1'b1;
				alu_op = 2'b00;
				end
					 
				//
			S_PLOT_X1Y2G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X1Y2: begin 
                plot = 1'b1;
				alu_op = 2'b00;
				end

			S_PLOT_X2Y2G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X2Y2: begin 
                plot = 1'b1;
				alu_op = 2'b00;
				end

			S_PLOT_X3Y2G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X3Y2: begin 
                plot = 1'b1;
				alu_op = 2'b10;
				end
				
				//

			S_PLOT_X3Y3G: begin 
                ld_alu_out = 1'b1; ld_y = 1'b1;
				end
			S_PLOT_X3Y3: begin 
                plot = 1'b1;
				alu_op = 2'b01;
				end
			S_PLOT_X2Y3G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X2Y3: begin 
                plot = 1'b1;
				alu_op = 2'b01;
				end
			S_PLOT_X1Y3G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_X1Y3: begin 
                plot = 1'b1;
				alu_op = 2'b01;
				end
			S_PLOT_XY3G: begin 
                ld_alu_out = 1'b1; ld_x = 1'b1;
				end
			S_PLOT_XY3: begin 
                plot = 1'b1;
				alu_op = 2'b10;
				end
				
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_XY;
        else
            current_state <= next_state;
    end // state_FFS
endmodule


