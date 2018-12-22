module top(input [3 : 0] KEY,
	input CLOCK_50, 
	output VGA_CLK, 
	output VGA_VS, 
	output VGA_BLANK_N,
	output VGA_SYNC_N, 
	output [9 : 0] VGA_R, 
	output [9 : 0] VGA_G, 
	output [9 : 0] VGA_B);

	wire frame;
	wire [4 : 0] s; // Connections of s are unfinished
	wire [14 : 0] curr_pos0, curr_pos1, curr_pos2, curr_pos3, curr_pos_ship, plot_xy; 
	wire [2 : 0] colour; 
	assign colour = s[0] ? 3'b100 : 3'b000;
    wire spaceshipC;
    wire a0C, a1C, a2C;
    

    wire left;
    wire right;
    wire fire;
    wire resetn;
    assign left = KEY[3];
    assign right = KEY[2];
    assign fire = KEY[1];
    assign resetn = KEY[0];

	mux5to1 muxer(
		.a(curr_pos0),
		.b(curr_pos1),
		.c(curr_pos2),
		.d(curr_pos3),
		.e(curr_pos_ship),
		.select(s[4:2]),
	
		.out(plot_xy));
	slower_clk slw0(
		.clk(CLOCK_50),
		.slower(frame)
		);
	fivebits_counter fbc0(
		.clk(CLOCK_50),
		.reset(KEY[0]),
		.activate(frame),
		.out(s)
		);


	spaceship ss(
        .spaceshipX(curr_pos_ship[14:7]),
		.spaceshipy(curr_pos_ship[6:0])
        .left(left),
        .right(right),
		.clk(CLOCK_50),
		.clk(frame),
		.resetn(KEY[0]), // reset the space ship
        .colour(spaceshipC)
		);

     alien a0(
         .clk(frame),
         .resetn(resetn),
         .startX(100),
         .startY(200),
         .alienX(curr_pos0[14:7])
         .alienY(curr_pos0[6:0]),
         .colour(a0C)
         );  

    alien a1(
         .clk(frame),
         .resetn(resetn),
         .startX(110),
         .startY(200),
         .alienX(curr_pos1[14:7])
         .alienY(curr_pos1[6:0]),
         .colour(a1C)
         );
    
    alien a2(
         .clk(frame),
         .resetn(resetn),
         .startX(120),
         .startY(200),
         .alienX(curr_pos2[14:7])
         .alienY(curr_pos2[6:0]),
         .colour(a2C)
         );
    alien a3(
         .clk(frame),
         .resetn(resetn),
         .startX(130),
         .startY(200),
         .alienX(curr_pos3[14:7])
         .alienY(curr_pos3[6:0]),
         .colour(a3C)
         );   
    

	draw d0(
		.CLOCK_50(CLOCK_50),						
      .draw_en(s[0]),
		.plot_x(plot_xy[14:7]),
		.plot_y(plot_xy[6:0]),
		.colour_in(colour),
		.resetn(KEY[0]),
		// The ports below are for the VGA output.  Do not change.
		.VGA_CLK(VGA_CLK),   						//	VGA Clock
		.VGA_HS(VGA_HS),							//	VGA H_SYNC
		.VGA_VS(VGA_VS),							//	VGA V_SYNC
		.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
		.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
		.VGA_R(VGA_R),   						//	VGA Red[9:0]
		.VGA_G(VGA_G),	 						//	VGA Green[9:0]
		.VGA_B(VGA_B)   						//	VGA Blue[9:0]
		);

//// draw_box.v
//	draw_box d0(
//		.CLOCK_50(CLOCK_50),						
//      .draw_en(s[0]),
//		.plot_x(plot_xy[14:7]),
//		.plot_y(plot_xy[6:0]),
//		.colour_in(colour),
//		.resetn(KEY[0]),
//		.shape(2'b01),
//		// The ports below are for the VGA output.  Do not change.
//		.VGA_CLK(VGA_CLK),   						//	VGA Clock
//		.VGA_HS(VGA_HS),							//	VGA H_SYNC
//		.VGA_VS(VGA_VS),							//	VGA V_SYNC
//		.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
//		.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
//		.VGA_R(VGA_R),   						//	VGA Red[9:0]
//		.VGA_G(VGA_G),	 						//	VGA Green[9:0]
//		.VGA_B(VGA_B)   						//	VGA Blue[9:0]
//		);
//		

endmodule



module fivebits_counter(
	input clk,
	input reset,
	input activate,
	
	output [4 : 0] out);
	
	reg [5 : 0] ops;
	always @(posedge clk)
	begin
		if (ops < 6'b10_0000)
			ops <= ops + 1'b1;
		else if (activate)
			ops <= 6'b00_0000;
	end
	
	assign out[4 : 2] = ops[4 : 2];
	assign out[1] = reset ? ops[1] : reset;
	assign out[0] = ops[0];
endmodule