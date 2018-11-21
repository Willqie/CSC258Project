//Every port labeled as fastclock should be connect to CLOCK_50
module project
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
	assign resetn = SW[0];
	
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
    wire counter_reset, count_complete, incr_x, incr_y, load;
    
    trafficData td(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .x(x),
        .y(y),
        .colour(colour),
        .colourIn(3'b110),
        .incr_x(incr_x),
        .incr_y(~KEY[3]),
        .load(load),
        .count_complete(count_complete),
        .counter_reset(counter_reset)
    );

    trafficControl tc(
        .fastclock(CLOCK_50),
        .count_complete(count_complete),
        .counter_reset(counter_reset),
        .resetn(resetn),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .load(load),
        .writeEn(writeEn)
    );

endmodule

module frogData(fastclock, resetn, up, down, left, right, x, y, counter_reset,
count_complete, erase, colour, colourIn, load);
    input resetn, up, down, left, right, fastclock, counter_reset;
    input erase, load;
    input [2:0] colourIn;
    output count_complete;
    output [2:0] colour;
    output [7:0] x;
    output [6:0] y;
    //  and ypos are index of the grid the frog is in
    reg [3:0] xpos;
    reg [2:0] ypos;
    reg [7:0] xcoor;
    reg [6:0] ycoor;
    always @(posedge fastclock)
    begin
        if (resetn == 1'b0) begin
            ypos <= 3'd6;
            xpos <= 4'd8;
        end
		  else begin
            if (load == 1'b1) begin
                xcoor <= 10 * xpos;
                ycoor <= 15 * ypos; 
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
    end 
     
    reg [5:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn)
            counter <= 6'b0000_00;
        else begin
            if (counter_reset == 1'b1)
                counter <= 6'b0000_00;
            else
                counter <= counter + 1;
        end
    end
    assign count_complete = (counter == 6'b1111_11) ? 1 : 0;
    assign colour = erase ? 3'd0 :  colourIn;
    assign x = xcoor + counter[2:0];
    assign y = ycoor + counter[5:3];

endmodule

module frogControl(fastclock, upin, downin, leftin, rightin, left, right,
up, down, resetn, counter_reset, count_complete, erase, writeEn, load);

    input fastclock, upin, downin, leftin, rightin, resetn, count_complete;
    output reg left, right, up, down, counter_reset, erase, writeEn, load;
    wire change;

    assign change = upin || downin || leftin || rightin;

    reg [3:0] current_state, next_state;
    
    localparam s_wait            = 4'd0,
               s_inter           = 4'd1,
               s_erase           = 4'd2,
               s_move            = 4'd3,
               s_clear_counter1  = 4'd4,
               s_draw            = 4'd5,
               s_clear_counter2  = 4'd6,
               s_update          = 4'd7,
               s_plot            = 4'd8,
               s_load            = 4'd10,
               s_load2           = 4'd11;

    always @(*)
    begin
        case (current_state)
            s_wait: next_state = change ? s_load : s_wait;
            s_load: next_state = s_clear_counter1;
            s_clear_counter1: next_state = s_erase;
            s_erase: next_state = count_complete ? s_update : s_erase;
            s_update: next_state = s_load2;
            s_load2: next_state = s_clear_counter2;
            s_clear_counter2: next_state = s_draw;
            s_draw: next_state = count_complete ? s_inter : s_draw;
            s_inter: next_state = change ? s_inter : s_wait;
        endcase
    end

    always @(*)
    begin: enable_signals
        counter_reset = 0;
        left = 0;
        right = 0;
        up = 0;
        down = 0;
        erase = 0;
        writeEn = 0;
        load = 0;

        case(current_state)
            s_clear_counter1: counter_reset = 1;
            s_load: load = 1;
            s_erase: begin
					erase = 1;
					writeEn = 1;
				end
            s_update: begin
                if (upin == 1'b1) up = 1;
                if (downin == 1'b1) down = 1;
                if (leftin == 1'b1) left = 1;
                if (rightin == 1'b1) right = 1;
            end
            s_clear_counter2: counter_reset = 1;
            s_draw: writeEn = 1;
				s_load2: load = 1;
        endcase
    end

    always @(posedge fastclock)
    begin
        if (!resetn)
            current_state <= s_wait;
        else
            current_state <= next_state;
    end

endmodule

module trafficData(fastclock, resetn, x, y, colour, colourIn, incr_x, incr_y, load
, count_complete, counter_reset);
    input fastclock, resetn, load, counter_reset, incr_x, incr_y;
    input [2:0] colourIn;
    reg [3:0] xpos;
    reg [1:0] ypos;
    output [7:0] x;
    output [6:0] y;
    output reg [2:0] colour;
    output count_complete;
    wire [15:0] q0, q1, q2, q3;

    wire clock;
    halfSecond halfSecondCounter(
        .fastclock(fastclock),
        .resetn(resetn),
        .signal(clock)
    );

    shiftRegister line0(
        .clock(clock),
        .q(q0),
        .init_val(16'b0000_1111_0000_0000), // Pseudo-random
        .resetn(resetn)
    );

    shiftRegister line1(
        .clock(clock),
        .q(q1),
        .init_val(16'b1100_0011_0001_0010),
        .resetn(resetn)
    );

    shiftRegister line2(
        .clock(clock),
        .q(q2),
        .init_val(16'b0011_0011_0001_1011),
        .resetn(resetn)
    );

    shiftRegister line3(
        .clock(clock),
        .q(q3),
        .init_val(16'b0110_0011_1001_1000),
        .resetn(resetn)
    );

    reg [7:0] xcoor;
    reg [6:0] ycoor;
    reg [5:0] counter;
    always @(posedge fastclock)
    begin
        if (!resetn) begin
			xpos <= 0;
			ypos <= 0;
		end
        if (load) begin
            xcoor <= xpos * 10;
            ycoor <= ypos * 15;
            if (ypos == 2'd0) begin
                if (q0[4'd15 - xpos] == 1'b1)
                    colour <= colourIn;
                else
                    colour <= 3'b111;
            end
            if (ypos == 2'd1) begin
                if (q1[4'd15-xpos] == 1'b1)
                    colour <= colourIn;
                else
                    colour <= 3'b111;
            end
            if (ypos == 2'd2) begin
                if (q1[4'd15-xpos] == 1'b1)
                    colour <= colourIn;
                else
                    colour <= 3'b111;
            end
            if (ypos == 2'd3) begin
                if (q1[4'd15-xpos] == 1'b1)
                    colour <= colourIn;
                else
                    colour <= 3'b111;
            end
        end
        else begin
            if (incr_x) xpos <= xpos + 1;
            if (incr_y) ypos <= ypos + 1;
            if (counter_reset == 1'b1)
                counter <= 6'b0;
            else begin
                counter = counter + 1;
            end
        end
    end

    assign count_complete = (counter == 6'b1111_11) ? 1 : 0;
    assign x = xcoor + counter[2:0];
    assign y = ycoor + counter[5:3];
endmodule

module trafficControl(fastclock, count_complete, counter_reset, resetn
,incr_x, incr_y, load, writeEn);
    input fastclock, resetn, count_complete;
    output reg counter_reset, load, incr_x, incr_y, writeEn;

    localparam s_load          = 4'd0,
               s_incr_x         = 4'd1,
               s_clear_counter  = 4'd2,
               s_draw           = 4'd3;

    reg [3:0] current_state, next_state;

    always @(*)
    begin
        case (current_state)
            s_incr_x: next_state = s_load;
            s_load: next_state = s_clear_counter;
            s_clear_counter: next_state = s_draw;
            s_draw: next_state = count_complete ? s_incr_x : s_draw;
        endcase
    end

    always @(*)
    begin
        counter_reset = 0;
        incr_x = 0;
        incr_y = 0;
        load = 0;
        writeEn = 0;
        case(current_state)
            s_load: load = 1;
            s_incr_x: incr_x = 1;
            s_clear_counter: counter_reset = 1;
            s_draw: writeEn = 1;
			endcase
    end

    always @(posedge fastclock)
    begin
        if (!resetn) 
            current_state <= s_incr_x;
        else
            current_state <= next_state;

    end
endmodule


// Traffic should move every half second
module halfSecond(fastclock, resetn, signal);
    input fastclock, resetn;
    output reg signal;

    reg [25:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn)
            counter <= 26'd25_000_000;
        else begin
            if (counter == 0) begin
                counter <= 26'd25_000_000;
                signal <= 1'b1;
            end
            else begin
                counter <= counter - 1;
                signal <= 1'b0;
            end
        end
    end

    

endmodule

// 16-bit width shifter
module shiftRegister(clock, q, init_val, resetn);
    input resetn, clock; // clock should be half second clock!
    input [15:0] init_val;
    output reg [15:0] q;

    always @(posedge clock, negedge resetn)
    begin 
		if (!resetn) 
            q <= init_val;
		else
            q <= {q[14:0], q[15]};
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

// module hex_decoder(hex_digit, segments);
//     input [3:0] hex_digit;
//     output reg [6:0] segments;
   
//     always @(*)
//         case (hex_digit)
//             4'h0: segments = 7'b100_0000;
//             4'h1: segments = 7'b111_1001;
//             4'h2: segments = 7'b010_0100;
//             4'h3: segments = 7'b011_0000;
//             4'h4: segments = 7'b001_1001;
//             4'h5: segments = 7'b001_0010;
//             4'h6: segments = 7'b000_0010;
//             4'h7: segments = 7'b111_1000;
//             4'h8: segments = 7'b000_0000;
//             4'h9: segments = 7'b001_1000;
//             4'hA: segments = 7'b000_1000;
//             4'hB: segments = 7'b000_0011;
//             4'hC: segments = 7'b100_0110;
//             4'hD: segments = 7'b010_0001;
//             4'hE: segments = 7'b000_0110;
//             4'hF: segments = 7'b000_1110;   
//             default: segments = 7'h7f;
//         endcase
// endmodule