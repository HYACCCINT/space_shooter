module main
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
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

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

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
	
	
	wire resetn;
	assign resetn = KEY[0];
	wire left;
	wire right;
	wire fire;
	assign left =  KEY[3];
	assign right = KEY[2];
	assign fire = KEY[1];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [7:0] y;
	wire writeEn;
	wire enable,ld_c;

	wire [9:0]spaceshipX;
	wire [8:0]spaceshipY;
	wire [9:0]rocketX;
	wire [8:0]rocketY;

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
		spaceship ship (spaceshipX, spaceshipY, left, right, clock, resetn, colour);
		rocket shiprocket(clk,resetn,spaceshipX,spaceshipY,rocketX,rocketY,1,fire,flying,hit, colour);

		alien ALN1(clock,resetn,500,150,alienX1,alienY1,30,rocketX,rocketY,1,100000000,0, colour);
		alien ALN2(clock,resetn,430,150,alienX2,alienY2,30,rocketX,rocketY,0,150000000,0, colour);
		alien ALN3(clock,resetn,360,150,alienX3,alienY3,30,rocketX,rocketY,0,150000000,0, colour);

	   	control c0(clock,KEY[0],~KEY[1],enable,ld_c,writeEn);

    
endmodule

module spaceship
    (spaceshipX,spaceshipY,left,right,clk,resetn, colour);
    input left,right;
    input clk,resetn;
    output reg [9:0]spaceshipX;
    output reg [8:0]spaceshipY;
	
	output reg colour;
	colour <= 3'b0;

    always@(posedge clk or posedge resetn)
    begin
        if(resetn)
        begin
            spaceshipX <= 10'd310;
            spaceshipY <= 9'd400;
			colour <= 3'b0;
        end
        else begin
            if(left) begin
                spaceshipX <= (spaceshipX > 11)? (spaceshipX - 10'd1):spaceshipX;
            end 
            else if(right) begin
                spaceshipX <= (spaceshipX < 598)? (spaceshipX + 9'd1):spaceshipX;
            end
        end
    end
endmodule


module rocket(clk,resetn,startX,startY,
        rocketX,rocketY,
        direction,fire,flying,hit, colour
        );

    input clk,resetn,fire,hit,direction;
    input [9:0]startX;
    input [8:0]startY;
    output reg flying;
    output reg [9:0]rocketX;
    output reg [8:0]rocketY;
	output reg colour;
    reg [23:0] counter;
    reg speed;
	colour <= 3'b0;
    always@(posedge clk or posedge resetn)
    begin
        if(resetn)
        begin   
            flying <=0;
			colour <= 3'b0;
        end 
		else
        begin
            if(fire)
            begin
                if(flying == 0)begin
                    flying <=1;
                    rocketX <= startX + 10'd13;
                    rocketY <= startY;
                end
            end 
            if(flying)
            begin   
                rocketY <= direction ? (rocketY - speed):(rocketY + speed);
                if((rocketY == 10) || (rocketY == 470) )
                begin
                    flying <= 0;
                end
            end
        end
    end
    
    always@(posedge clk)
        if(flying)
        begin
            if(counter == 24'd150_000)begin
                 speed <= 1'b1;
                 counter <= 0;
            end else begin
                 counter <= counter + 1'b1;
                 speed <= 0;
            end
        end else begin
            counter <= 0;
            speed <= 0;
        end
    
endmodule

module control(clock,resetn,go,enable,ld_c,plot);
	input clock,resetn,go;
	output reg enable,ld_c,plot;	
	
	reg [3:0] current_state, next_state;
	
	localparam  S_LOAD_SIGNAL       = 4'd0,
                S_LOAD_SIGNAL_WAIT   = 4'd1,
					 S_MOVE = 4'd2;
	
	always@(*)
      begin: state_table 
            case (current_state)
                S_LOAD_SIGNAL: next_state = go ? S_LOAD_SIGNAL_WAIT : S_LOAD_SIGNAL; 
                S_LOAD_SIGNAL_WAIT: next_state = go ? S_MOVE : S_LOAD_SIGNAL_WAIT;  
                S_MOVE: next_state = S_MOVE; 
            default:     next_state = S_LOAD_SIGNAL;
        endcase
      end 
   
	always@(*)
      begin: enable_signals
        // By default make all our signals 0
        ld_c = 1'b0;
		  enable = 1'b0;
		  plot = 1'b0;
		  
		  case(current_state)
				S_MOVE:begin
				   ld_c = 1'b1;
					enable = 1'b1;
					plot = 1'b1;
					end
		  endcase
    end
	 
	 always@(posedge clock)
      begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_SIGNAL;
        else
            current_state <= next_state;
      end 
endmodule

module alien(clk,resetn,startX,startY,alienX,alienY,width,rocketX,rocketY,firefreq,frontalive, colour);

    input clk,resetn;
    input frontalive;
    input [9:0] startX;
    input [8:0] startY;
    input [9:0] rocketX;
    input [8:0] rocketY;
    input [9:0] width;
    input [27:0] firefreq;
    output reg [9:0]alienX;
    output reg [8:0]alienY;
    reg [23:0] counter;
    reg [27:0] firecounter;
    reg speed,direction;
	output reg colour;

    
    always@(posedge clk or posedge resetn)
    begin
        if(resetn)
        begin
            alienX <= startX;
			colour <= 3'b0;
        end else if(counter == 24'd400_000)
            begin
                 speed <= 1'b1;
                 counter <= 0;
             end else 
             begin
                if(direction) 
                begin
                    counter <= counter + 1'b1;
                    alienX <= alienX + speed;
                    speed <= 0;
                end else 
                begin
                    counter <= counter + 1'b1;
                    alienX <= alienX - speed;
                    speed <= 0;
                end
            end
        end
    
    
    always@(posedge clk or posedge resetn)begin
        if(resetn)
        begin
            direction <= 0;
            alienY <= startY;
        end else begin
            if(alienX == startX - 170 && direction == 0) begin
                direction <= 1'b1;
                alienY <=  alienY + 20;
            end else if(alienX == startX + 50 && direction == 1)begin
                direction <= 0;
                alienY <= alienY + 20;
            end
        end
    end
   
endmodule
