module project(CLOCK_50, HEX0, SW);
    output [6:0] HEX0;
    input CLOCK_50;
    input [9:0] SW;

    wire increment;
    wire [3:0] hex_wire;
    second secondInstance(
        .fastclock(CLOCK_50),
        .resetn(SW[0]),
        .signal(increment)
    );

    decimal_digit dg(
        .clear(SW[0]),
        .increment(increment),
        .x(hex_wire)
    );
    
    hex hex0(
        .HEX(HEX0),
        .x(hex_wire)
    );




endmodule

module decimal_digit(clear, increment, x, carry);
    input clear, increment;
    output reg [3:0] x;
    output carry;

    localparam zero  = 4'd0,
               one   = 4'd1,
               two   = 4'd2,
               three = 4'd3,
               four  = 4'd4,
               five  = 4'd5,
               six   = 4'd6,
               seven = 4'd7,
               eigth = 4'd8,
               nine  = 4'd9;
    
    reg [3:0] current_state, next_state;

    always @(*)
    begin
        case(current_state)
            zero:  next_state = one;
            one:   next_stete = two;
            two:   next_state = three;
            three: next_state = four;
            four:  next_state = five;
            five:  next_state = six;
            six:   next_state = seven;
            seven: next_state = eight;
            eight: next_state = nine;
            nine:  next_state = zero;
        endcase
    end

    always @(posedge increment, negedge clear)
    begin
        if (!clear) 
            current_state = zero;
        else
            current_state = next_state;
    end

    always @(*)
    begin
        case(current_state)
            zero:  x = 4'b0000;
            one:   x = 4'b0001;
            two:   x = 4'b0002;
            three: x = 4'b0003;
            four:  x = 4'b0004;
            five:  x = 4'b0005;
            six:   x = 4'b0006;
            seven: x = 4'b0007;
            eight: x = 4'b0008;
            nine:  x = 4'b0009;

    end

    assign carry = (current_state == nine) ? 1 : 0;
endmodule

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

