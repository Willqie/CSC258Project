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
    wire counter_reset2, count_complete2, erase, collide, fake_change;
	 wire fake_change_bus, fake_change_counter;
    wire up, down, right, left, load2, is_draw, win;
    wire [3:0] fxpos;
    wire [2:0] fypos;
	 
	 assign fake_change_bus = fake_change || fake_change_counter;
	 
    frogData fd(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .x(x1),
        .y(y1),
        .counter_reset(counter_reset1),
        .count_complete(count_complete1),
        .erase(erase),
        .colour(colour1),
        .colourIn(3'b111),
        .load(load),
        .xpos(fxpos),
        .ypos(fypos),
		  .collide(collide),
          .win(win)
    );

    frogControl fc(
        .fastclock(CLOCK_50),
        .upin(~KEY[3]),
        .downin(~KEY[2]),
        .leftin(~KEY[1]),
        .rightin(~KEY[0]),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .resetn(resetn),
        .counter_reset(counter_reset1),
        .count_complete(count_complete1),
        .erase(erase),
        .writeEn(writeEn1),
        .load(load),
        .is_draw(is_draw),
		  .fake_change(fake_change_bus)
    );
    wire counter_reset1, count_complete1, incr_x, incr_y, load;
    wire [3:0] xpos;
    wire [7:0] x1, x2;
    wire [6:0] y1, y2;
    wire [2:0] colour1, colour2;
    wire writeEn1, writeEn2;
    wire change_pos;

    trafficData td(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .x(x2),
        .y(y2),
        .colour(colour2),
        .colourIn(3'b110),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .load(load2),
        .count_complete(count_complete2),
        .counter_reset(counter_reset2),
        .xpos(xpos),
        .fxpos(fxpos),
        .fypos(fypos),
		.collide(collide),
		.fake_change(fake_change),
        .clock(change_pos)
    );

    trafficControl tc(
        .fastclock(CLOCK_50),
        .count_complete(count_complete2),
        .counter_reset(counter_reset2),
        .resetn(resetn),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .load(load2),
        .writeEn(writeEn2),
        .xpos(xpos)
    );
    wire [7:0] x_notwin, x_win, x_clear, x_lose;
    wire [6:0] y_notwin, y_win, y_clear, y_lose;
    wire [2:0] colour_notwin, colour_win, colour_lose;
    wire writeEn_notwin, writeEn_win, clear_counter_clear, count_complete_clear;
    wire writeEn_lose;
    wire [1:0] sig_select;
    
    signalSwitch(
        .switch(is_draw),
        .x1(x1),
        .y1(y1),
        .colour1(colour1),
        .writeEn1(writeEn1),
        .x2(x2),
        .y2(y2),
        .colour2(colour2),
        .writeEn2(writeEn2),
        .x(x_notwin),
        .y(y_notwin),
        .colour(colour_notwin),
        .writeEn(writeEn_notwin)
    );
	 
	 fakechangeCounter fcCounter(
		.fastclock(CLOCK_50),
		.resetn(resetn),
		.fakechange(fake_change_counter)
	 );

    signal_selector sigselector(
        .x1(x_notwin),
        .y1(y_notwin),
        .colour1(colour_notwin),
        .writeEn1(writeEn_notwin),
        .x2(x_win),
        .y2(y_win),
        .colour2(colour_win),
        .writeEn2(writeEn_win),
        .x3(x_clear),
        .y3(y_clear),
        .colour3(3'b000),
        .writeEn3(1'b1),
        .x4(x_lose),
        .y4(y_lose),
        .colour4(colour_lose),
        .writeEn4(writeEn_lose),
        .x(x),
        .y(y),
        .writeEn(writeEn),
        .colour(colour),
        .sig_select(sig_select)
    );

    youwin youwinInstance(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .x(x_win),
        .y(y_win),
        .colourOut(colour_win),
        .writeEn(writeEn_win)
    );

    youlose youloseInstance(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .x(x_lose),
        .y(y_lose),
        .colourOut(colour_lose),
        .writeEn(writeEn_lose)
    );

    clear_screen clear_screen_instance(
        .fastclock(CLOCK_50),
        .x(x_clear),
        .y(y_clear),
        .count_complete(count_complete_clear),
        .clear_counter(clear_counter_clear)
    );

    game_control topControl(
        .fastclock(CLOCK_50),
        .sig_select(sig_select),
        .count_complete(count_complete_clear),
        .clear_counter(clear_counter_clear),
        .win(win),
        .restart(~KEY[3]),
        .is_collide(collide)
    );

    change_sig_selector change_sig_instance(
        .fastclock(CLOCK_50),
        .select(SW[9:8]),
        .change_sig(change_pos),
        .resetn(resetn)
    );
endmodule

module frogData(fastclock, resetn, up, down, left, right, x, y, counter_reset,
count_complete, erase, colour, colourIn, load, xpos, ypos, collide, win);
    input resetn, up, down, left, right, fastclock, counter_reset;
    input erase, load, collide;
    input [2:0] colourIn;
    output count_complete;
    output [2:0] colour;
    output [7:0] x;
    output [6:0] y;
    output win;
    //  and ypos are index of the grid the frog is in
    output reg [3:0] xpos;
    output reg [2:0] ypos;
    reg [7:0] xcoor;
    reg [6:0] ycoor;
    always @(posedge fastclock)
    begin
        if (collide == 1'b1) begin
            ypos <= 3'd6;
            xpos <= 4'd8;
        end else begin
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
    assign win = (ypos == 3'b0);

endmodule

module frogControl(fastclock, upin, downin, leftin, rightin, left, right,
up, down, resetn, counter_reset, count_complete, erase, writeEn, load, is_draw, fake_change);

    input fastclock, upin, downin, leftin, rightin, resetn, count_complete, fake_change;
    output reg left, right, up, down, counter_reset, erase, writeEn, load;
    wire change;
    output reg is_draw;

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
            s_wait: next_state = (change || fake_change) ? s_load : s_wait;
            s_load: next_state = s_clear_counter1;
            s_clear_counter1: next_state = s_erase;
            s_erase: next_state = count_complete ? s_update : s_erase;
            s_update: next_state = s_load2;
            s_load2: next_state = s_clear_counter2;
            s_clear_counter2: next_state = s_draw;
            s_draw: next_state = count_complete ? s_inter : s_draw;
            s_inter: next_state = (change || fake_change) ? s_inter : s_wait;
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
        is_draw = 0;
        case(current_state)
            s_clear_counter1: counter_reset = 1;
            s_load: load = 1;
            s_erase: begin
					erase = 1;
					writeEn = 1;
                    is_draw = 1;
				end
            s_update: begin
                if (upin == 1'b1) up = 1;
                if (downin == 1'b1) down = 1;
                if (leftin == 1'b1) left = 1;
                if (rightin == 1'b1) right = 1;
            end
            s_clear_counter2: counter_reset = 1;
            s_draw: begin
                writeEn = 1;
                is_draw = 1;
            end
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
, count_complete, counter_reset, xpos, fxpos, fypos, collide, fake_change, clock);
    input fastclock, resetn, load, counter_reset, incr_x, incr_y;
    input [2:0] colourIn;
    input [3:0] fxpos;
    input [2:0] fypos;
    output reg [3:0] xpos;
	 output reg fake_change;
    reg [1:0] ypos;
    output [7:0] x;
    output [6:0] y;
    output reg collide;
    output reg [2:0] colour;
    output count_complete;
    wire [15:0] q0, q1, q2, q3;
    input clock;
    
    // wire clock;
    // halfSecond halfSecondCounter(
    //     .fastclock(fastclock),
    //     .resetn(resetn),
    //     .signal(clock)
    // );

    shiftRegister line0(
        .clock(clock),
        .q(q0),
        .init_val(16'b1000_1101_1000_0000), // Pseudo-random
        .resetn(resetn)
    );

    shiftRegister line1(
        .clock(clock),
        .q(q1),
        .init_val(16'b1100_0011_0001_0011),
        .resetn(resetn)
    );

    shiftRegister line2(
        .clock(clock),
        .q(q2),
        .init_val(16'b0011_0111_0001_1001),
        .resetn(resetn)
    );

    shiftRegister line3(
        .clock(clock),
        .q(q3),
        .init_val(16'b0110_0011_1001_1100),
        .resetn(resetn)
    );

    reg [7:0] xcoor;
    reg [6:0] ycoor;
    reg [5:0] counter;
    always @(posedge fastclock)
    begin
		  if (collide == 1'b1) begin
		      collide <= 1'b0;
				fake_change <= 1'b0;
		  end
        if (!resetn) begin
			xpos <= 0;
			ypos <= 0;
			collide <= 0;
			fake_change <= 1'b0;
		end
        if (load) begin
            xcoor <= xpos * 10;
            ycoor <= (ypos + 1) * 15;
            if (fxpos == xpos && (fypos - 1'd1) == ypos) begin
                if((fypos - 1'b1) == 1'b0) begin
                    if(q0[15 - fxpos] == 1'b1) begin
                        collide <= 1'b1;
								fake_change <= 1'b1;
                    end
                end
                if((fypos - 1'b1) == 1'b1) begin
                    if((q1[15 - fxpos]) == 1'b1) begin
                        collide <= 1'b1;
								fake_change <= 1'b1;
                    end
                end
                if((fypos - 1'b1) == 2) begin
                    if(q2[15 - fxpos] == 1'b1) begin
                        collide <= 1'b1;
								fake_change <= 1'b1;
                    end
                end
                if((fypos - 1'b1) == 3) begin
                    if(q3[15 - fxpos] == 1'b1) begin
                        collide <= 1'b1;
								fake_change <= 1'b1;
                    end
                end
                colour <= 3'b111;
            end else begin
                if (ypos == 2'd0) begin
                    if (q0[4'd15 - xpos] == 1'b1)
                        colour <= colourIn;
                    else
                        colour <= 3'b000;
                end
                if (ypos == 2'd1) begin
                    if (q1[4'd15-xpos] == 1'b1)
                        colour <= colourIn;
                    else
                        colour <= 3'b000;
                end
                if (ypos == 2'd2) begin
                    if (q2[4'd15-xpos] == 1'b1)
                        colour <= colourIn;
                    else
                        colour <= 3'b000;
                end
                if (ypos == 2'd3) begin
                    if (q3[4'd15-xpos] == 1'b1)
                        colour <= colourIn;
                    else
                        colour <= 3'b000;
                end
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
,incr_x, incr_y, load, writeEn, xpos);
    input fastclock, resetn, count_complete;
    input [3:0] xpos;
    output reg counter_reset, load, incr_x, incr_y, writeEn;

    localparam s_load          = 4'd0,
               s_incr_x         = 4'd1,
               s_clear_counter  = 4'd2,
               s_draw           = 4'd3,
               s_incr_y         = 4'd4,
               s_inter          = 4'd5;

    reg [3:0] current_state, next_state;
    
    always @(*)
    begin
        case (current_state)
            s_incr_x: next_state = s_load;
            s_load: next_state = s_clear_counter;
            s_clear_counter: next_state = s_draw;
            s_draw: next_state = count_complete ? s_inter : s_draw;
            s_inter: begin
                if (xpos == 4'b1111) begin
                    next_state = s_incr_y;
                end
                else begin
                    next_state = s_incr_x;
                end
            end
            s_incr_y: next_state = s_incr_x;
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
            s_incr_y: incr_y = 1;
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

// module switchCounter(fastclock, switch, resetn);
//     input fastclock, resetn;
//     output reg switch;

//     reg [10:0] counter;

//     always @(posedge fastclock)
//     begin
//         if (!resetn) begin
//             switch <= 1'b1;
//             counter <= 11'd0;
//         end 
//         else begin
//             if (counter < 10'd1000) begin
//                 switch <= 1'b1;
//             end
//             else begin
//                 if (counter > 10'd1000 && counter)
//                 switch <= 1'b0;
//                 counter <= counter + 1'b1;
//             end
//         end
//     end
// endmodule

module signalSwitch(switch, x1, y1, colour1, writeEn1, x2, y2, colour2, writeEn2, x, y, colour, writeEn);
    input [7:0] x1, x2;
    input [6:0] y1, y2;
    input [2:0] colour1, colour2;
    input writeEn1, writeEn2;
    output [7:0] x;
    output [6:0] y;
    output [2:0] colour;
    output writeEn;
    input switch;

    assign x = switch ? x1 : x2;
    assign y = switch ? y1 : y2;
    assign colour = switch ? colour1 : colour2;
    assign writeEn = switch ? writeEn1: writeEn2;
endmodule

module fakechangeCounter(fastclock, resetn, fakechange);
	input fastclock, resetn;
	output reg fakechange;
	
	reg [26:0] counter;
	
	always @(posedge fastclock)
	begin
		if (!resetn)begin
			counter <= 27'd0;
			fakechange <= 1'b0;
		end
		if (counter == 27'd1_0000) begin
				counter <= 27'd0;
				fakechange <= 1'b1;
		end else begin
			counter <= counter + 1;
			fakechange <= 1'b0;
		end
	
	end
	
endmodule

module overwriteController(x_win, y_win, colour_win, writeEn1, x1, y1, colour1, writeEn2,
overwrite, x, y, colour, writeEn);
    input [7:0] x_win, x1;
    input [6:0] y_win, y1;
    input overwrite, writeEn1, writeEn2;
    input [2:0] colour_win, colour1;
    output [2:0] colour;
    output writeEn;
    output [7:0] x;
    output [6:0] y;

    assign colour = overwrite ? colour_win : colour1;
    assign writeEn = overwrite ? writeEn1 : writeEn2;
    assign x = overwrite ? x_win : x1;
    assign y = overwrite ? y_win : y1;

endmodule

module youwin(fastclock, resetn, x, y, colourOut, writeEn);
    input fastclock, resetn;
    output [7:0] x;
    output [6:0] y;
    output [2:0] colourOut;
    output writeEn;
    wire count_complete, clear_counter, incr_x, incr_y, load;
    wire [3:0] xpos; 

    youwin_data data(
        .fastclock(fastclock),
        .resetn(resetn),
        .xout(x),
        .yout(y),
        .colourOut(colourOut),
        .count_complete(count_complete),
        .clear_counter(clear_counter),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .load(load),
        .xpos(xpos)
    );

    control_win control(
        .fastclock(fastclock),
        .xpos(xpos),
        .resetn(resetn),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .clear_counter(clear_counter),
        .load(load),
        .writeEn(writeEn),
        .count_complete(count_complete)
    );
endmodule

module youlose(fastclock, resetn, x, y, colourOut, writeEn);
    input fastclock, resetn;
    output [7:0] x;
    output [6:0] y;
    output [2:0] colourOut;
    output writeEn;
    wire count_complete, clear_counter, incr_x, incr_y, load;
    wire [3:0] xpos; 

    youlose_data data(
        .fastclock(fastclock),
        .resetn(resetn),
        .xout(x),
        .yout(y),
        .colourOut(colourOut),
        .count_complete(count_complete),
        .clear_counter(clear_counter),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .load(load),
        .xpos(xpos)
    );

    control_win control(
        .fastclock(fastclock),
        .xpos(xpos),
        .resetn(resetn),
        .incr_x(incr_x),
        .incr_y(incr_y),
        .clear_counter(clear_counter),
        .load(load),
        .writeEn(writeEn),
        .count_complete(count_complete)
    );
endmodule
module youwin_data(fastclock, resetn, xout, yout, colourOut
, count_complete, clear_counter, incr_x, incr_y, load, xpos);
    input fastclock, incr_x, incr_y, resetn, clear_counter, load;
    output count_complete;
    output [7:0] xout;
    output [6:0] yout;
    output reg [2:0] colourOut;

    reg [15:0] q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15;

    output reg [3:0] xpos;
    reg [3:0] ypos;
    reg [7:0] xcoor;
    reg [6:0] ycoor;
    reg [5:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn) begin
            xpos <= 4'b0;
            ypos <= 4'b0;
            counter <= 6'b0;
            q0 <= 16'b1000_1000_1000_1001;
            q1 <= 16'b1000_1001_0100_1001;
            q2 <= 16'b0101_0001_0100_1001;
            q3 <= 16'b0010_0001_0100_1001;
            q4 <= 16'b0010_0001_0100_1001;
            q5 <= 16'b0010_0000_1000_0110;
            q6 <= 16'b0;
            q7 <= 16'b1001_0010_0100_1001;
            q8 <= 16'b1001_0010_0100_1001;
            q9 <= 16'b1001_0010_0100_1101;
            q10 <= 16'b1001_0010_0100_1011;
            q11 <= 16'b1001_0010_0100_1001;
            q12 <= 16'b0110_1100_0100_1001;
            q13 <= 16'b0;
            q14 <= 16'b0;
            q15 <= 16'b0;
        end
        if (load) begin
            xcoor <= xpos * 10;
            ycoor <= ypos * 7;
            if(ypos == 4'd0) begin
                if (q0[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd1) begin
                if (q1[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd2) begin
                if (q2[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd3) begin
                if (q3[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd4) begin
                if (q4[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd5) begin
                if (q5[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd6) begin
                if (q6[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd7) begin
                if (q7[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd8) begin
                if (q8[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd9) begin
                if (q9[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd10) begin
                if (q10[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd11) begin
                if (q11[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd12) begin
                if (q12[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd13) begin
                if (q13[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd14) begin
                if (q14[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd15) begin
                if (q15[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
        end
        if (incr_x)
            xpos <= xpos + 1;
        if (incr_y)
            ypos <= ypos + 1;
        if (clear_counter) 
            counter <= 6'b0;
        else 
            counter <= counter + 1'b1;
    end

    assign count_complete = (counter == 6'b1111_11) ? 1 : 0;
    assign xout = xcoor + counter[2:0];
    assign yout = ycoor + counter[5:3];
endmodule

module youlose_data(fastclock, resetn, xout, yout, colourOut
, count_complete, clear_counter, incr_x, incr_y, load, xpos);
    input fastclock, incr_x, incr_y, resetn, clear_counter, load;
    output count_complete;
    output [7:0] xout;
    output [6:0] yout;
    output reg [2:0] colourOut;

    reg [15:0] q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15;

    output reg [3:0] xpos;
    reg [3:0] ypos;
    reg [7:0] xcoor;
    reg [6:0] ycoor;
    reg [5:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn) begin
            xpos <= 4'b0;
            ypos <= 4'b0;
            counter <= 6'b0;
            q0 <= 16'b1000_1000_1000_1001;
            q1 <= 16'b1000_1001_0100_1001;
            q2 <= 16'b0101_0001_0100_1001;
            q3 <= 16'b0010_0001_0100_1001;
            q4 <= 16'b0010_0001_0100_1001;
            q5 <= 16'b0010_0000_1000_0110;
            q6 <= 16'b0;
            q7 <= 16'b1000_1000_1110_0111;
            q8 <= 16'b1001_0100_1000_0100;
            q9 <= 16'b1001_0100_1000_0100;
            q10 <= 16'b1001_0100_0110_0111;
            q11 <= 16'b1001_0100_0010_0100;
            q12 <= 16'b1000_1000_1110_0111;
            q13 <= 16'b0;
            q14 <= 16'b0;
            q15 <= 16'b0;
        end
        if (load) begin
            xcoor <= xpos * 10;
            ycoor <= ypos * 7;
            if(ypos == 4'd0) begin
                if (q0[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd1) begin
                if (q1[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd2) begin
                if (q2[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd3) begin
                if (q3[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd4) begin
                if (q4[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd5) begin
                if (q5[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd6) begin
                if (q6[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd7) begin
                if (q7[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd8) begin
                if (q8[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd9) begin
                if (q9[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd10) begin
                if (q10[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd11) begin
                if (q11[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd12) begin
                if (q12[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd13) begin
                if (q13[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd14) begin
                if (q14[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
            if(ypos == 4'd15) begin
                if (q15[4'd15 - xpos] == 1'b1)
                    colourOut <= 3'b110;
                else
                    colourOut <= 3'b000;
            end
        end
        if (incr_x)
            xpos <= xpos + 1;
        if (incr_y)
            ypos <= ypos + 1;
        if (clear_counter) 
            counter <= 6'b0;
        else 
            counter <= counter + 1'b1;
    end

    assign count_complete = (counter == 6'b1111_11) ? 1 : 0;
    assign xout = xcoor + counter[2:0];
    assign yout = ycoor + counter[5:3];
endmodule


module control_win(fastclock, xpos, resetn, incr_x, incr_y,
clear_counter, load, writeEn, count_complete);
    input fastclock, resetn, count_complete;
    output reg incr_x, incr_y, load, writeEn;
	 output reg clear_counter;
	 input [3:0] xpos;
	 
    localparam s_load          = 4'd0,
               s_incr_x         = 4'd1,
               s_clear_counter  = 4'd2,
               s_draw           = 4'd3,
               s_incr_y         = 4'd4,
               s_inter          = 4'd5;

    reg [3:0] current_state, next_state;
    
    always @(*)
    begin
        case (current_state)
            s_incr_x: next_state = s_load;
            s_load: next_state = s_clear_counter;
            s_clear_counter: next_state = s_draw;
            s_draw: next_state = count_complete ? s_inter : s_draw;
            s_inter: begin
                if (xpos == 4'b1111) begin
                    next_state = s_incr_y;
                end
                else begin
                    next_state = s_incr_x;
                end
            end
            s_incr_y: next_state = s_incr_x;
        endcase
    end

    always @(*)
    begin
        clear_counter = 0;
        incr_x = 0;
        incr_y = 0;
        load = 0;
        writeEn = 0;
        case(current_state)
            s_load: load = 1;
            s_incr_x: incr_x = 1;
            s_clear_counter: clear_counter = 1;
            s_draw: writeEn = 1;
            s_incr_y: incr_y = 1;
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

module clear_screen(fastclock, x, y, count_complete, clear_counter);
    input fastclock, clear_counter;
    output [7:0] x;
    output [6:0] y;
    output count_complete;

    reg [14:0] counter;
    always @(posedge fastclock)
    begin
        if (clear_counter == 1'b1) 
            counter <= 15'b0;
        else 
            counter <= counter + 1;
    end

    assign x = counter[7:0];
    assign y = counter[14:8];
    assign count_complete = (counter == 15'b1111_1111_1111_111) ? 1 : 0;

endmodule

//sigselect: 00 for game, 01 for win, 10 for clear_screen
module game_control(fastclock, sig_select, count_complete, clear_counter, win, restart, is_collide);
    input fastclock, count_complete, win, restart, is_collide;
    output reg clear_counter;
    output reg [1:0] sig_select;

    reg [3:0] current_state, next_state;

    localparam s_play          = 4'd0,
               s_win           = 4'd1,
               s_clear_screen  = 4'd2,
               s_clear_counter = 4'd3,
               s_lose          = 4'd4;
    
    always @(*)
    begin
        case(current_state)
            s_play: begin
                if (is_collide) begin
                    next_state = s_lose;
                end
                else if (win) begin
                    next_state = s_win;
                end
                else begin
                    next_state = s_play;
                end
            
            end
            s_win: next_state = win ? s_win: s_clear_counter;
            s_clear_counter: next_state = s_clear_screen;
            s_clear_screen: next_state = count_complete ? s_play : s_clear_screen;
            // There may be a bug?
            s_lose: next_state = restart ? s_clear_counter : s_lose;
        endcase
    end

    always @(*)
    begin enable_signals:
        clear_counter = 0;
        sig_select = 0;
        case(current_state)
            s_play: sig_select = 2'b00;
            s_win: sig_select = 2'b01;
            s_clear_counter: clear_counter = 1;
            s_clear_screen: sig_select = 2'b10;
            s_lose: sig_select = 2'b11;
        endcase
    end

    always @(posedge fastclock)
    begin
        current_state <= next_state;
    end

endmodule

// 1 for game signal, 2 for win signal, 3 for clear_screen, 4 for you lose
module signal_selector(x1, y1, colour1, writeEn1, x2, y2, colour2, writeEn2,
x3, y3, colour3, writeEn3, x4, y4, colour4, writeEn4, x, y, colour, writeEn, sig_select);
    input [7:0] x1, x2, x3, x4;
    input [6:0] y1, y2, y3, y4;
    input [2:0] colour1, colour2, colour3, colour4;
    input writeEn1, writeEn2, writeEn3, writeEn4;
    output reg [7:0] x;
    output reg [6:0] y;
    output reg [2:0] colour;
    output reg writeEn;
    input [1:0] sig_select;

    always @(*)
    begin
        case(sig_select)
            2'b00: begin
                x = x1;
                y = y1;
                colour = colour1;
                writeEn = writeEn1;
            end
            2'b01: begin
                x = x2;
                y = y2;
                colour = colour2;
                writeEn = writeEn2;
            end
            2'b10: begin
                x = x3;
                y = y3;
                colour = colour3;
                writeEn = writeEn3;
            end
            2'b11: begin
                x = x4;
                y = y4;
                colour = colour4;
                writeEn = writeEn4;
            end
		endcase
    end
    
endmodule

// Traffic should move every half second
module Second(fastclock, resetn, signal);
    input fastclock, resetn;
    output reg signal;

    reg [25:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn)
            counter <= 26'd50_000_000;
        else begin
            if (counter == 0) begin
                counter <= 26'd50_000_000;
                signal <= 1'b1;
            end
            else begin
                counter <= counter - 1;
                signal <= 1'b0;
            end
        end
    end

endmodule

module twoSecond(fastclock, resetn, signal);
    input fastclock, resetn;
    output reg signal;

    reg [25:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn)
            counter <= 26'd100_000_000;
        else begin
            if (counter == 0) begin
                counter <= 26'd100_000_000;
                signal <= 1'b1;
            end
            else begin
                counter <= counter - 1;
                signal <= 1'b0;
            end
        end
    end

endmodule

// 00 for not move, 01 for half second, 10 for one second, 11 for two second
module change_sig_selector(fastclock, select, change_sig, resetn);
    input fastclock, resetn;
    input [1:0] select;
    output reg change_sig;

    wire chage0, change1, change2, change3;

    assign change0 = 1'b0;
    
    halfSecond halfSecondInstance(
        .fastclock(fastclock),
        .resetn(resetn),
        .signal(change1)
    );

    Second secondInstance(
        .fastclock(fastclock),
        .resetn(resetn),
        .signal(change2)
    );

    twoSecond twoSecondInstance(
        .fastclock(fastclock),
        .resetn(resetn),
        .signal(change3)
    );

    always @(*)
    begin
        case(select)
            2'b00: change_sig = change0;
            2'b01: change_sig = change1;
            2'b10: change_sig = change2;
            2'b11: change_sig = change3;
        endcase
    end

endmodule











