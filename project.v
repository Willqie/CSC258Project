// Every port labeled as fastclock should be connect to CLOCK_50
// module project
// 	(
// 		CLOCK_50,						//	On Board 50 MHz
// 		// Your inputs and outputs here
//         KEY,
//         SW,
// 		// The ports below are for the VGA output.  Do not change.
// 		VGA_CLK,   						//	VGA Clock
// 		VGA_HS,							//	VGA H_SYNC
// 		VGA_VS,							//	VGA V_SYNC
// 		VGA_BLANK_N,						//	VGA BLANK
// 		VGA_SYNC_N,						//	VGA SYNC
// 		VGA_R,   						//	VGA Red[9:0]
// 		VGA_G,	 						//	VGA Green[9:0]
// 		VGA_B   						//	VGA Blue[9:0]
// 	);

// 	input			CLOCK_50;				//	50 MHz
// 	input   [9:0]   SW;
// 	input   [3:0]   KEY;

// 	// Declare your inputs and outputs here
// 	// Do not change the following outputs
// 	output			VGA_CLK;   				//	VGA Clock
// 	output			VGA_HS;					//	VGA H_SYNC
// 	output			VGA_VS;					//	VGA V_SYNC
// 	output			VGA_BLANK_N;				//	VGA BLANK
// 	output			VGA_SYNC_N;				//	VGA SYNC
// 	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
// 	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
// 	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
// 	wire resetn;
// 	assign resetn = KEY[0];
	
// 	// Create the colour, x, y and writeEn wires that are inputs to the controller.
// 	wire [2:0] colour;
// 	wire [7:0] x;
// 	wire [6:0] y;
// 	wire writeEn;

// 	// Create an Instance of a VGA controller - there can be only one!
// 	// Define the number of colours as well as the initial background
// 	// image file (.MIF) for the controller.
// 	vga_adapter VGA(
// 			.resetn(resetn),
// 			.clock(CLOCK_50),
// 			.colour(colour),
// 			.x(x),
// 			.y(y),
// 			.plot(writeEn),
// 			/* Signals for the DAC to drive the monitor. */
// 			.VGA_R(VGA_R),
// 			.VGA_G(VGA_G),
// 			.VGA_B(VGA_B),
// 			.VGA_HS(VGA_HS),
// 			.VGA_VS(VGA_VS),
// 			.VGA_BLANK(VGA_BLANK_N),
// 			.VGA_SYNC(VGA_SYNC_N),
// 			.VGA_CLK(VGA_CLK));
// 		defparam VGA.RESOLUTION = "160x120";
// 		defparam VGA.MONOCHROME = "FALSE";
// 		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
// 		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
// 	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
// 	// for the VGA controller, in addition to any other functionality your design may require.
    
//     // Instansiate datapath
// 	// datapath d0(...);

//     // Instansiate FSM control
//     // control c0(...);
    
// endmodule

module project(KEY, HEX0, HEX1, CLOCK_50, SW);
    input [3:0] KEY;
    input [9:0] SW;
    input CLOCK_50;
    output [6:0] HEX0, HEX1;

    wire [2:0] xcoor, ycoor;

    frogDataControl dp(
        .fastclock(CLOCK_50),
        .resetn(SW[0]),
        .up(~KEY[3]),
        .down(~KEY[2]),
        .left(~KEY[1]),
        .right(~KEY[0]),
        .xpos(xcoor),
        .ypos(ycoor)
    );

    hex hex0(
        .HEX(HEX0),
        .x({1'b0, xcoor})
    );

    hex hex1(
        .HEX(HEX1),
        .x({1'b0, ycoor})
    );

endmodule

module frogDataControl(fastclock, resetn, up, down, left, right, xpos, ypos);
    input fastclock, resetn, up, down, left, right;
    output [2:0] xpos, ypos;

    wire leftwire, rightwire, upwire, downwire;

    frogControl frogControlInstance(
        .fastclock(fastclock),
        .upin(up),
        .downin(down),
        .leftin(left),
        .rightin(right),
        .left(leftwire),
        .right(rightwire),
        .up(upwire),
        .down(downwire),
        .resetn(resetn)
    );

    frogData frogdataInstance(
        .fastclock(fastclock),
        .resetn(resetn),
        .up(upwire),
        .down(downwire),
        .left(leftwire),
        .right(rightwire),
        .xpos(xpos),
        .ypos(ypos)
    );

endmodule

module frogData(fastclock, resetn, up, down, left, right, xpos, ypos);
    input resetn, up, down, left, right, fastclock;
    // xpos and ypos are index of the grid the frog is in
    output reg [2:0] xpos;
    output reg [2:0] ypos;

    always @(posedge fastclock)
    begin
        if (resetn == 1'b0) begin
            ypos <= 3'd6;
            xpos <= 3'd4;
        end
        if (up == 1'b1) 
            ypos <= ypos - 1'b1;
        if (down == 1'b1)
            ypos <= ypos + 1'b1;
        if (left == 1'b1)
            xpos <= xpos - 1'b1;
        if (right == 1'b1)
            xpos <= xpos + 1'b1;
    end

endmodule

module frogControl(fastclock, upin, downin, leftin, rightin, left, right,
up, down, resetn);
    input fastclock, upin, downin, leftin, rightin, resetn;
    output left, right, up, down;

    frogPartiallControl upControl(
        .fastclock(fastclock),
        .in(upin),
        .out(up),
        .resetn(resetn)
    );

    frogPartiallControl downControl(
        .fastclock(fastclock),
        .in(downin),
        .out(down),
        .resetn(resetn)
    );

    frogPartiallControl leftControl(
        .fastclock(fastclock),
        .in(leftin),
        .out(left),
        .resetn(resetn)
    );

    frogPartiallControl rightControl(
        .fastclock(fastclock),
        .in(rightin),
        .out(right),
        .resetn(resetn)
    );

endmodule

// Control module for each direction in up, down, left and right
module frogPartiallControl(fastclock, in, out, resetn);
    input fastclock, in, resetn;
    output reg out;

    reg current_state, next_state;

    localparam s_wait   = 4'd0,
               s_press1 = 4'd1,
               s_inter  = 4'd2,
					s_press2 = 4'd3;
    
    always @(*)
    begin: state_table
        case (current_state)
            s_wait:   next_state = in ? s_inter : s_wait;
            s_press1:  next_state = s_press2;
				s_press2:  next_state = s_wait;
            s_inter : next_state = in ? s_inter : s_press1;
        endcase
    end

    always @(*)
    begin enable_signals:
        out = 1'b0;
        case(current_state)
            s_press1: out = 1'b1;
				s_press2: out = 1'b1;
        endcase
    end

    always @(posedge fastclock)
    begin: state_FFs
        if (!resetn)
            current_state <= s_wait;
        else
            current_state <= next_state;
    end

endmodule

module hex(HEX, x);
    input [3:0] x;
    output [6: 0] HEX;

    Hex0 h0(
        .y(HEX[0]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex1 h1(
        .y(HEX[1]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex2 h2(
        .y(HEX[2]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex3 h3(
        .y(HEX[3]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex4 h4(
        .y(HEX[4]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex5 h5(
        .y(HEX[5]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );
    Hex6 h6(
        .y(HEX[6]),
        .c3(x[3]),
        .c2(x[2]),
        .c1(x[1]),
        .c0(x[0])
    );


endmodule



module Hex0(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~((c1 & ~c0) | (~c3 & c1) | (c3 & ~c1 & ~c0) | (c0 & ~c3 & c2) | (~c2 & ~c1 & ~c0) | (c1 & c3 & c2) | (~c1 & c3 & ~c2));

endmodule

module Hex1(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~((~c3 & ~c2) | ( ~c1 & ~c2) | (~c2 & c1 & ~c0) | (~c3 & c1 & c0) | (c3 & c0 & ~c1) | ( ~c3 & ~c1 & ~c0));

endmodule

module Hex2(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~(~c1 & c0 | ~c3 & c2 | c3 & ~c2 | ~c1 & ~c3 | ~c3 & c0);
endmodule

module Hex3(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~(c3 & ~c1 & ~c0 | ~c1 & c2 & c0 | c1 & ~c3 & ~c2 | c2 & c1 & ~c0 | ~c2 & c1 & c0 | ~c2 & ~c1 & ~c0);

endmodule

module Hex4(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~(c1 & ~c0 | c3 & c2 | c1 & c3 | ~c2 & ~c1 & ~c0);

endmodule

module Hex5(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y =~( ~c1 & ~c0 | c3 & ~c2 | ~c0 & c2 & c1 | c1 & c2 & c3 | c2 & ~c1 & ~c3);

endmodule

module Hex6(y, c3, c2, c1, c0);
    output y;
    input c3, c2, c1, c0;
    assign y = ~(c3 & ~c2 | c1 & ~c0 | c0 & c3 | ~c3 & c2 & ~c1 | c1 & ~c3 & ~c2);

endmodule
