// Tested

module slower_clk(
	input clk, 
	output slower);
	reg [19 : 0] out = 20'b0000_0000_0000_0000_0000;
	reg [19 : 0] mux4to1 = 20'b1100_1011_0111_0011_0101;
	
//	always @(*)
//	begin // 60 Hz, 50M/60 - 1
//		mux4to1 <= 20'b1100_1011_0111_0011_0101;
//	end
	
	always @(posedge clk)
	// change count when changing switches
	begin
		//if (out == 0 | select)
		if (out == mux4to1)
			out <= 0;
		else
			out <= out + 1'b1;
	end
	
	assign slower = (out == 0) ? 1 : 0;

 endmodule 