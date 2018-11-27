module youwin
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

    wire count_complete, clear_counter, incr_x, incr_y, load;
    wire [3:0] xpos; 

    youwin_data data(
        .fastclock(CLOCK_50),
        .resetn(resetn),
        .xout(x),
        .yout(y),
        .colourOut(colour),
        .count_complete(count_complete),
        .clear_counter(clear_counter),
        .incr_x(incr_x),
        .incr_y(KEY[0]),
        .load(load),
        .xpos(xpos)
    );

    control_win control(
        .fastclock(CLOCK_50),
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
    reg [1:0] counter;

    always @(posedge fastclock)
    begin
        if (!resetn) begin
            xpos <= 4'b0;
            ypos <= 4'b0;
            counter <= 2'b0;
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
            counter <= 2'b0;
        else 
            counter <= counter + 1'b1;
    end

    assign count_complete = (counter == 2'b11) ? 1 : 0;
    assign xout = xcoor + counter[0];
    assign yout = ycoor + counter[1];
endmodule

module control_win(fastclock, xpos, resetn, incr_x, incr_y,
clear_counter, load, writeEn, count_complete);
    input fastclock, xpos, resetn, count_complete;
    output reg incr_x, incr_y, load, writeEn;
	 output reg clear_counter;
	 
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