`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/15/2019 08:48:15 AM
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define stop 3'd0
`define forward 3'd1
`define left_forward 3'd2
`define right_forward 3'd3
`define backward 3'd4
`define left_backward 3'd5
`define right_backward 3'd6
`define hhg 32'd2959
`define sil 32'd50000000

module main(
    input clk, // clock from crystal
    input rst, // active high reset: BTNC
    input SW0, // forward
    input SW1, // backward
    input SW2, // turn left
    input SW3, // turn right
    input SW15, // if SW15==1 seven_segment shows the value of dis    if SW15==0 seven_segment shows the value of RxData
    input RxD, // bluetooth input signal
    input Echo,
    output wire IN1,
    output wire IN2,
    output wire IN3,
    output wire IN4,
    output wire audio_mclk, 
    output wire audio_lrck, 
    output wire audio_sck,
    output wire audio_sdin,
	output wire Trig,
    output wire [3:0] _led, //  _led[3:0] = {turn right , turn left , backward , forward}
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY
    );
   
    wire clkDiv13, clkDiv16, clkDiv22;
    wire [7:0] RxData;
    wire [3:0] BCD0, BCD1, BCD2, BCD3;
    reg [2:0] direction , next_direction;
    wire [15:0] audio_in_left, audio_in_right;
    wire [11:0] ibeatNum; // Beat counter
    wire [31:0] freqL, freqR; // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR; // Processed Frequency, adapted to the clock rate of Basys3
    wire [32:0] dis;
    wire play;
	
	assign play = (dis>=2 && dis<=4) ? 1 : 0;
	assign _led = (direction==`stop) ? 4'b0000 :
                  (direction==`forward) ? 4'b0001 :
                  (direction==`left_forward) ? 4'b0101 :
                  (direction==`right_forward) ? 4'b1001 :
                  (direction==`backward) ? 4'b0010 :
                  (direction==`left_backward) ? 4'b0110 :
                  (direction==`right_backward) ? 4'b1010 : 4'b0000;
    assign BCD0 = (SW15==0) ? RxData%10 : dis%10;
    assign BCD1 = (SW15==0) ? (RxData/10)%10 : (dis/10)%10;
    assign BCD2 = (SW15==0) ? (RxData/100)%10 : (dis/100)%10;
    assign BCD3 = (SW15==0) ? (RxData/1000)%10 : (dis/100)%10;
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;
    
    clock_divider #(.n(13)) clock_13(
        .clk(clk),
        .clk_div(clkDiv13)
    );
    
    clock_divider #(.n(16)) clock_16(
        .clk(clk),
        .clk_div(clkDiv16)
    );
    
    clock_divider #(.n(22)) clock_22(
        .clk(clk),
        .clk_div(clkDiv22)
    );

    _player_control playerCtrl_0(
        .clk(clkDiv22),
        .reset(rst),
        .play(play),
        .ibeat(ibeatNum)
    );
    
    music_example Music_0(
        .ibeatNum(ibeatNum),
        .toneL(freqL),
        .toneR(freqR)
    );
    
    note_gen noteGen_0(
        .clk(clk), // clock from crystal
        .rst(rst), // active high reset
        .note_div_left(freq_outL),
        .note_div_right(freq_outR),
        .audio_left(audio_in_left), // left sound audio
        .audio_right(audio_in_right)
    );
    
    speaker_control speakerCtrl_0(
        .clk(clk),  // clock from the crystal
        .rst(rst),  // active high reset
        .audio_in_left(audio_in_left), // left channel audio data input
        .audio_in_right(audio_in_right), // right channel audio data input
        .audio_mclk(audio_mclk), // master clock
        .audio_lrck(audio_lrck), // left-right clock
        .audio_sck(audio_sck), // serial clock
        .audio_sdin(audio_sdin) // serial audio data input
    );
    
    sonic Sonic_0(
        .clock(clk),
        .trig(Trig),
        .echo(Echo),
        .distance(dis)
    );

    bluetooth_RX Bluetooth_0(
        .clk(clk), //input clock
        .reset(rst), //input reset 
        .RxD(RxD), //input receving data line
        .RxData(RxData)
	);
    
    motor_control motorCtrl_0(
        .direction(direction),
        .IN1(IN1),
        .IN2(IN2),
        .IN3(IN3),
        .IN4(IN4)
    );
    
    seven_segment SSD_0(
        .rst(rst),
        .clk(clkDiv13),
        .BCD3(BCD3),
        .BCD2(BCD2),
        .BCD1(BCD1),
        .BCD0(BCD0),
        .DIGIT(DIGIT),
        .DISPLAY(DISPLAY)
    ); // show the value of RxData or dis
    
    always@(posedge clk , posedge rst) begin
        if(rst)begin
            direction = `stop;
        end else begin
            direction = next_direction;
        end
    end
    
    always@* begin
        case(RxData)
            8'd71: next_direction=`left_forward;
            8'd70: next_direction=`forward;
            8'd73: next_direction=`right_forward;
            8'd72: next_direction=`left_backward;
            8'd66: next_direction=`backward;
            8'd74: next_direction=`right_backward;
            default:begin
                if(SW0==1 && SW1==0)begin
                    if(SW2==1 && SW3==0) next_direction=`left_forward;
                    else if(SW2==0 && SW3==1) next_direction=`right_forward;
                    else next_direction=`forward;
                end else if(SW0==0 && SW1==1)begin
                    if(SW2==1 && SW3==0) next_direction=`left_backward;
                    else if(SW2==0 && SW3==1) next_direction=`right_backward;
                    else next_direction=`backward;
                end else
                    next_direction=`stop;
            end
        endcase
    end
endmodule

module motor_control(
    input [2:0] direction,
    output reg IN1,
    output reg IN2,
    output reg IN3,
    output reg IN4
    );
    always@*begin
        case(direction)
            `stop: {IN1,IN2,IN3,IN4} = 4'b0000;
            `forward: {IN1,IN2,IN3,IN4} = 4'b1010;
            `left_forward: {IN1,IN2,IN3,IN4} = 4'b1000;
            `right_forward: {IN1,IN2,IN3,IN4} = 4'b0010;
            `backward: {IN1,IN2,IN3,IN4} = 4'b0101;
            `left_backward: {IN1,IN2,IN3,IN4} = 4'b0100;
            `right_backward: {IN1,IN2,IN3,IN4} = 4'b0001;
            default: {IN1,IN2,IN3,IN4} = 4'b0000;
        endcase
    end
endmodule

module bluetooth_RX(
	input clk, //input clock
	input reset, //input reset 
	input RxD, //input receving data line
	output [7:0] RxData // output for 8 bits data
	// output [7:0]LED // output 8 LEDs
    );
	//internal variables
	reg shift; // shift signal to trigger shifting data
	reg state, nextstate; // initial state and next state variable
	reg [3:0] bitcounter; // 4 bits counter to count up to 9 for UART receiving
	reg [1:0] samplecounter; // 2 bits sample counter to count up to 4 for oversampling
	reg [13:0] counter; // 14 bits counter to count the baud rate
	reg [9:0] rxshiftreg; //bit shifting register
	reg clear_bitcounter,inc_bitcounter,inc_samplecounter,clear_samplecounter; //clear or increment the counter

	// constants
	parameter clk_freq = 100_000_000;  // system clock frequency
	parameter baud_rate = 9_600; //baud rate
	parameter div_sample = 4; //oversampling
	parameter div_counter = clk_freq/(baud_rate*div_sample);  // this is the number we have to divide the system clock frequency to get a frequency (div_sample) time higher than (baud_rate)
	parameter mid_sample = (div_sample/2);  // this is the middle point of a bit where you want to sample it
	parameter div_bit = 10; // 1 start, 8 data, 1 stop


	assign RxData = rxshiftreg [8:1]; // assign the RxData from the shiftregister

	//UART receiver logic
	always @ (posedge clk)begin 
		if (reset)begin // if reset is asserted
			state <=0; // set state to idle 
			bitcounter <=0; // reset the bit counter
			counter <=0; // reset the counter
			samplecounter <=0; // reset the sample counter
		end else begin // if reset is not asserted
			counter <= counter +1; // start count in the counter
			if (counter >= div_counter-1) begin // if counter reach the baud rate with sampling 
				counter <=0; //reset the counter
				state <= nextstate; // assign the state to nextstate
				if (shift)rxshiftreg <= {RxD,rxshiftreg[9:1]}; //if shift asserted, load the receiving data
				if (clear_samplecounter) samplecounter <=0; // if clear sampl counter asserted, reset sample counter
				if (inc_samplecounter) samplecounter <= samplecounter +1; //if increment counter asserted, start sample count
				if (clear_bitcounter) bitcounter <=0; // if clear bit counter asserted, reset bit counter
				if (inc_bitcounter)bitcounter <= bitcounter +1; // if increment bit counter asserted, start count bit counter
			end
		end
	end
	   
	//state machine

	always @ (posedge clk) begin //trigger by clock
		shift <= 0; // set shift to 0 to avoid any shifting 
		clear_samplecounter <=0; // set clear sample counter to 0 to avoid reset
		inc_samplecounter <=0; // set increment sample counter to 0 to avoid any increment
		clear_bitcounter <=0; // set clear bit counter to 0 to avoid claring
		inc_bitcounter <=0; // set increment bit counter to avoid any count
		nextstate <=0; // set next state to be idle state
		case (state)
			0: begin // idle state
				if (RxD) begin// if input RxD data line asserted 
				    nextstate <=0; // back to idle state because RxD needs to be low to start transmission 
				end else begin // if input RxD data line is not asserted
					nextstate <=1; //jump to receiving state 
					clear_bitcounter <=1; // trigger to clear bit counter
					clear_samplecounter <=1; // trigger to clear sample counter
				end
			end
			1: begin // receiving state
				nextstate <= 1; // DEFAULT 
				if (samplecounter== mid_sample - 1) 
				    shift <= 1; // if sample counter is 1, trigger shift 
				if (samplecounter== div_sample - 1) begin // if sample counter is 3 as the sample rate used is 3
					if (bitcounter == div_bit - 1) begin // check if bit counter if 9 or not
					    nextstate <= 0; // back to idle state if bit counter is 9 as receving is complete
					end 
					inc_bitcounter <=1; // trigger the increment bit counter if bit counter is not 9
					clear_samplecounter <=1; //trigger the sample counter to reset the sample counter
				end else 
				    inc_samplecounter <=1; // if sample is not equal to 3, keep counting
		        end
		    default: nextstate <=0; //default idle state
		endcase
	end         
endmodule

module clock_divider(
    input clk,
    output wire clk_div
    );   
    parameter n = 26;
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num<=next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];  
endmodule

module seven_segment(
    input rst,
    input clk,
    input [3:0] BCD3,
    input [3:0] BCD2,
    input [3:0] BCD1,
    input [3:0] BCD0,
    output reg [3:0] DIGIT,
    output wire [6:0] DISPLAY
    );
    reg [3:0] value;

	always @ (posedge clk) begin	
		case(DIGIT) 
			4'b0111: begin
			    if(rst) value=0;
			    else value = BCD2;
				DIGIT <= 4'b1011;
			end
			4'b1011: begin
			    if(rst) value=0;
			    else value = BCD1;
				DIGIT <= 4'b1101;
			end
			4'b1101: begin
			    if(rst) value=0;
				else value = BCD0;
				DIGIT <= 4'b1110;
			end
			4'b1110: begin
			    if(rst) value=0;
				else value = BCD3;
				DIGIT <= 4'b0111;
			end
			default begin
				DIGIT <= 4'b1110;
			end
		endcase	
	end

	assign DISPLAY = (value==4'd0) ? 7'b0000001 :
					 (value==4'd1) ? 7'b1001111 :
					 (value==4'd2) ? 7'b0010010 :
					 (value==4'd3) ? 7'b0000110 :
					 (value==4'd4) ? 7'b1001100 :
					 (value==4'd5) ? 7'b0100100 :
					 (value==4'd6) ? 7'b0100000 :
					 (value==4'd7) ? 7'b0001111 :
					 (value==4'd8) ? 7'b0000000 : 
					 (value==4'd9) ? 7'b0000100 : 7'b1111111;
	
endmodule

module _player_control (
	input clk,
	input reset,
	input play,
	output reg [11:0] ibeat
);
    always @* begin
        if(reset)
            ibeat = 1;
        else begin
            if(play==1)
                ibeat = 0;
            else
                ibeat = 1;
        end
    end
endmodule

module music_example (
	input [11:0] ibeatNum,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        case(ibeatNum)
            12'd0: toneR = `hhg;
            default: toneR = `sil;
        endcase
    end
    always @* begin
        case(ibeatNum)
            12'd0: toneL = `hhg;
            default : toneL = `sil;
        endcase
    end
endmodule

module speaker_control(
    input clk,  // clock from the crystal
    input rst,  // active high reset
    input [15:0] audio_in_left, // left channel audio data input
    input [15:0] audio_in_right, // right channel audio data input
    output wire audio_mclk, // master clock
    output wire audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    output wire audio_sck, // serial clock
    output reg audio_sdin // serial audio data input
);
    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase
endmodule

module note_gen(
    input clk, // clock from crystal
    input rst, // active high reset
    input [21:0] note_div_left, // div for note generation
    input [21:0] note_div_right,
    output wire [15:0] audio_left,
    output wire [15:0] audio_right
);
    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;
    
    // Note frequency generation
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
        
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : (b_clk == 1'b0) ? 16'h8001 : 16'h7FFF;
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : (c_clk == 1'b0) ? 16'h8001 : 16'h7FFF;
endmodule

module sonic(
    input clock,
    input echo,
    output wire trig,
    output reg [32:0] distance
    );
    reg [32:0] distance_temp = 0;
    wire clkDiv25;
    clock_divider #(.n(25)) clock_25(
        .clk(clock),
        .clk_div(clkDiv25)
    );
    reg [32:0] us_counter = 0;
    reg _trig = 1'b0;
    reg [9:0] one_us_cnt = 0;
    wire one_us = (one_us_cnt == 0);
    reg [9:0] ten_us_cnt = 0;
    wire ten_us = (ten_us_cnt == 0);
    reg [21:0] forty_ms_cnt = 0;
    wire forty_ms = (forty_ms_cnt == 0);
    
    assign trig = _trig;
    
    always @(posedge clock) begin
        one_us_cnt <= (one_us ? 100 : one_us_cnt) - 1;
        ten_us_cnt <= (ten_us ? 1000 : ten_us_cnt) - 1;
        forty_ms_cnt <= (forty_ms ? 4000000 : forty_ms_cnt) - 1;
        if (ten_us && _trig)
            _trig <= 1'b0;
        if (one_us) begin	
            if (echo)
                us_counter <= us_counter + 1;
            else if (us_counter) begin
                distance_temp <= us_counter / 58;
                us_counter <= 0;
            end
        end
        if (forty_ms)
            _trig <= 1'b1;
    end
    always@(posedge clkDiv25) begin
        distance = distance_temp;
    end
endmodule