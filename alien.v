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
