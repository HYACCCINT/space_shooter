module spaceship
    (spaceshipX,spaceshipY,left,right,clk,resetn, colour);
    input left,right;
    input clk,resetn;
    output reg [7:0]spaceshipX= 8'b0101_0000,
    output reg [6:0]spaceshipY= 7'b011_1100;
	
	output reg colour;
	colour <= 3'b0;

    always@(posedge clk or posedge resetn)
    begin
        if(resetn)
        begin
            spaceshipX <= 8'b0101_0000;
            spaceshipY <= 7'b011_1100;
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