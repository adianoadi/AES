`timescale 1ns / 1ps
module AES_TOP(output done, output [127:0] Dout, input [127:0] plain_text_in, key_in, input encrypt, clock, reset);
	wire init, isRound0, en_round_out, inc_count, en_reg_sub_out, en_reg_row_out, en_reg_col_out, en_Dout, count_lt_10;
	
	controlpath cp(done, init, isRound0, en_round_out, inc_count, en_reg_sub_out,
	en_reg_row_out, en_reg_col_out, en_Dout, count_lt_10, encrypt, clock, reset);
	
	datapath dp(Dout, count_lt_10, key_in, plain_text_in, init, isRound0, en_round_out, inc_count,
	en_reg_sub_out, en_reg_row_out, en_reg_col_out, en_Dout, reset, clock);
	
endmodule




module datapath(
	output [127:0] Dout, output count_lt_10,
	input [127:0] key_in, plain_text_in, 
	input init, isRound0, en_round_out, inc_count, en_reg_sub_out, en_reg_row_out, en_reg_col_out, en_Dout, reset, clock
);
	wire [127:0] round_in, sub_out, row_out, col_out, mux_out, Din;
	wire [127:0] plain_text, key, round_out, reg_sub_out, reg_row_out, reg_col_out;
	wire [127:0] key_r_out;
	wire [127:0] key_r[0:10];
	wire [3:0] count;
	
	Register Reg_key(key, key_in, init, clock, reset);
	Register Reg_plain_text(plain_text, plain_text_in, init, clock, reset);
	Register Reg_round_out(round_out, round_in, en_round_out, clock, reset);
	Register Reg_sub_out(reg_sub_out, sub_out, en_reg_sub_out, clock, reset);
	Register Reg_row_out(reg_row_out, row_out, en_reg_row_out, clock, reset);
	Register Reg_col_out(reg_col_out, col_out, en_reg_col_out, clock, reset);
	Register Reg_Dout(Dout, Din, en_Dout, clock, reset);
	
	Counter up(count, 4'd0, 1'b0, inc_count, 1'b0, clock, reset);
	assign count_lt_10 = count < 10;
	
	Key_expansion ke(key_r[0], key_r[1], key_r[2], key_r[3], key_r[4], key_r[5], key_r[6], key_r[7], key_r[8], key_r[9], key_r[10], key);
	Sub_Bytes sb0(sub_out, round_out);
	shift_rows sr0(row_out, reg_sub_out);
	mix_cols mc(col_out, reg_row_out);
	assign key_r_out = key_r[count];
	assign round_in = ((isRound0) ? plain_text : reg_col_out) ^ key_r_out;
	assign Din = reg_row_out ^ key_r_out;
endmodule




module controlpath(
	output reg done, init, isRound0, en_round_out, inc_count, en_reg_sub_out, en_reg_row_out, en_reg_col_out, en_Dout, 
	input count_lt_10, encrypt, clock, reset
);
	parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6;
	reg [2:0] current, next;
	
	always @(posedge clock, posedge reset)
	begin
		if (reset)
			current <= S0;
		else
			current <= next;
	end
	always @(*) begin
		done = 0;
		init = 0;
		en_round_out = 0;
		inc_count = 0;
		en_reg_sub_out = 0;
		en_reg_row_out = 0;
		en_reg_col_out = 0;
		en_Dout = 0;
		isRound0 = 0;
		case (current)
			S0: begin
				if (encrypt)
				begin
					init = 1;
					next = S1;
				end
			end
			S1: begin
				isRound0 = 1;
				en_round_out = 1;
				inc_count = 1;
				next = S2;
			end
			S2: begin 
				en_reg_sub_out = 1;
				next = S3;
			end
			S3: begin
				en_reg_row_out = 1;
				if (count_lt_10)
				begin
					next = S4;
				end
				else
				begin
					next = S5;
				end
			end
			S4: begin
				en_reg_col_out = 1;
				next = S5;
			end
			S5: begin
				if (count_lt_10)
				begin
					en_round_out = 1;
					inc_count = 1;
					next = S2;
				end
				else begin
					en_Dout = 1;
			      next = S6;
				end
			end
			S6: begin
				done = 1;
			   if (encrypt)
			   begin
			      init = 1;
				   next = S1;
			   end
			end
		endcase
	end
endmodule



module Sub_Bytes(output[127:0] D_out,input [127:0]D_in);

	wire[127:0] S_out;
		S_BOX S1(S_out[7:0],D_in[7:0]);
		S_BOX S2(S_out[15:8],D_in[15:8]);
		S_BOX S3(S_out[23:16],D_in[23:16]);
		S_BOX S4(S_out[31:24],D_in[31:24]);
		S_BOX S5(S_out[39:32],D_in[39:32]);
		S_BOX S6(S_out[47:40],D_in[47:40]);
		S_BOX S7(S_out[55:48],D_in[55:48]);
		S_BOX S8(S_out[63:56],D_in[63:56]);
		S_BOX S9(S_out[71:64],D_in[71:64]);
		S_BOX S10(S_out[79:72],D_in[79:72]);
		S_BOX S11(S_out[87:80],D_in[87:80]);
		S_BOX S12(S_out[95:88],D_in[95:88]);
		S_BOX S13(S_out[103:96],D_in[103:96]);
		S_BOX S14(S_out[111:104],D_in[111:104]);
		S_BOX S15(S_out[119:112],D_in[119:112]);
		S_BOX S16(S_out[127:120],D_in[127:120]);
	assign D_out=S_out;
	
endmodule



module S_BOX(output reg [7:0] D_out, input [7:0]D_in);
always@(D_in)
	 begin
	 case (D_in) 
			8'h00: D_out = 8'h63;
			8'h01: D_out = 8'h7C;
			8'h02: D_out = 8'h77;
			8'h03: D_out = 8'h7B;
			8'h04: D_out = 8'hF2;
			8'h05: D_out = 8'h6B;
			8'h06: D_out = 8'h6F;
			8'h07: D_out = 8'hC5;
			8'h08: D_out = 8'h30;
			8'h09: D_out = 8'h01;
			8'h0A: D_out = 8'h67;
			8'h0B: D_out = 8'h2B;
			8'h0C: D_out = 8'hFE;
			8'h0D: D_out = 8'hD7;
			8'h0E: D_out = 8'hAB;
			8'h0F: D_out = 8'h76;
			8'h10: D_out = 8'hCA;
			8'h11: D_out = 8'h82;
			8'h12: D_out = 8'hC9;
			8'h13: D_out = 8'h7D;
			8'h14: D_out = 8'hFA;
			8'h15: D_out = 8'h59;
			8'h16: D_out = 8'h47;
			8'h17: D_out = 8'hF0;
			8'h18: D_out = 8'hAD;
			8'h19: D_out = 8'hD4;
			8'h1A: D_out = 8'hA2;
			8'h1B: D_out = 8'hAF;
			8'h1C: D_out = 8'h9C;
			8'h1D: D_out = 8'hA4;
			8'h1E: D_out = 8'h72;
			8'h1F: D_out = 8'hC0;
			8'h20: D_out = 8'hB7;
			8'h21: D_out = 8'hFD;
			8'h22: D_out = 8'h93;
			8'h23: D_out = 8'h26;
			8'h24: D_out = 8'h36;
			8'h25: D_out = 8'h3F;
			8'h26: D_out = 8'hF7;
			8'h27: D_out = 8'hCC;
			8'h28: D_out = 8'h34;
			8'h29: D_out = 8'hA5;
			8'h2A: D_out = 8'hE5;
			8'h2B: D_out = 8'hF1;
			8'h2C: D_out = 8'h71;
			8'h2D: D_out = 8'hD8;
			8'h2E: D_out = 8'h31;
			8'h2F: D_out = 8'h15;
			8'h30: D_out = 8'h04;
			8'h31: D_out = 8'hC7;
			8'h32: D_out = 8'h23;
			8'h33: D_out = 8'hC3;
			8'h34: D_out = 8'h18;
			8'h35: D_out = 8'h96;
			8'h36: D_out = 8'h05;
			8'h37: D_out = 8'h9A;
			8'h38: D_out = 8'h07;
			8'h39: D_out = 8'h12;
			8'h3A: D_out = 8'h80;
			8'h3B: D_out = 8'hE2;
			8'h3C: D_out = 8'hEB;
			8'h3D: D_out = 8'h27;
			8'h3E: D_out = 8'hB2;
			8'h3F: D_out = 8'h75;
			8'h40: D_out = 8'h09;
			8'h41: D_out = 8'h83;
			8'h42: D_out = 8'h2C;
			8'h43: D_out = 8'h1A;
			8'h44: D_out = 8'h1B;
			8'h45: D_out = 8'h6E;
			8'h46: D_out = 8'h5A;
			8'h47: D_out = 8'hA0;
			8'h48: D_out = 8'h52;
			8'h49: D_out = 8'h3B;
			8'h4A: D_out = 8'hD6;
			8'h4B: D_out = 8'hB3;
			8'h4C: D_out = 8'h29;
			8'h4D: D_out = 8'hE3;
			8'h4E: D_out = 8'h2F;
			8'h4F: D_out = 8'h84;
			8'h50: D_out = 8'h53;
			8'h51: D_out = 8'hD1;
			8'h52: D_out = 8'h00;
			8'h53: D_out = 8'hED;
			8'h54: D_out = 8'h20;
			8'h55: D_out = 8'hFC;
			8'h56: D_out = 8'hB1;
			8'h57: D_out = 8'h5B;
			8'h58: D_out = 8'h6A;
			8'h59: D_out = 8'hCB;
			8'h5A: D_out = 8'hBE;
			8'h5B: D_out = 8'h39;
			8'h5C: D_out = 8'h4A;
			8'h5D: D_out = 8'h4C;
			8'h5E: D_out = 8'h58;
			8'h5F: D_out = 8'hCF;
			8'h60: D_out = 8'hD0;
			8'h61: D_out = 8'hEF;
			8'h62: D_out = 8'hAA;
			8'h63: D_out = 8'hFB;
			8'h64: D_out = 8'h43;
			8'h65: D_out = 8'h4D;
			8'h66: D_out = 8'h33;
			8'h67: D_out = 8'h85;
			8'h68: D_out = 8'h45;
			8'h69: D_out = 8'hF9;
			8'h6A: D_out = 8'h02;
			8'h6B: D_out = 8'h7F;
			8'h6C: D_out = 8'h50;
			8'h6D: D_out = 8'h3C;
			8'h6E: D_out = 8'h9F;
			8'h6F: D_out = 8'hA8;
			8'h70: D_out = 8'h51;
			8'h71: D_out = 8'hA3;
			8'h72: D_out = 8'h40;
			8'h73: D_out = 8'h8F;
			8'h74: D_out = 8'h92;
			8'h75: D_out = 8'h9D;
			8'h76: D_out = 8'h38;
			8'h77: D_out = 8'hF5;
			8'h78: D_out = 8'hBC;
			8'h79: D_out = 8'hB6;
			8'h7A: D_out = 8'hDA;
			8'h7B: D_out = 8'h21;
			8'h7C: D_out = 8'h10;
			8'h7D: D_out = 8'hFF;
			8'h7E: D_out = 8'hF3;
			8'h7F: D_out = 8'hD2;
			8'h80: D_out = 8'hCD;
			8'h81: D_out = 8'h0C;
			8'h82: D_out = 8'h13;
			8'h83: D_out = 8'hEC;
			8'h84: D_out = 8'h5F;
			8'h85: D_out = 8'h97;
			8'h86: D_out = 8'h44;
			8'h87: D_out = 8'h17;
			8'h88: D_out = 8'hC4;
			8'h89: D_out = 8'hA7;
			8'h8A: D_out = 8'h7E;
			8'h8B: D_out = 8'h3D;
			8'h8C: D_out = 8'h64;
			8'h8D: D_out = 8'h5D;
			8'h8E: D_out = 8'h19;
			8'h8F: D_out = 8'h73;
			8'h90: D_out = 8'h60;
			8'h91: D_out = 8'h81;
			8'h92: D_out = 8'h4F;
			8'h93: D_out = 8'hDC;
			8'h94: D_out = 8'h22;
			8'h95: D_out = 8'h2A;
			8'h96: D_out = 8'h90;
			8'h97: D_out = 8'h88;
			8'h98: D_out = 8'h46;
			8'h99: D_out = 8'hEE;
			8'h9A: D_out = 8'hB8;
			8'h9B: D_out = 8'h14;
			8'h9C: D_out = 8'hDE;
			8'h9D: D_out = 8'h5E;
			8'h9E: D_out = 8'h0B;
			8'h9F: D_out = 8'hDB;
			8'hA0: D_out = 8'hE0;
			8'hA1: D_out = 8'h32;
			8'hA2: D_out = 8'h3A;
			8'hA3: D_out = 8'h0A;
			8'hA4: D_out = 8'h49;
			8'hA5: D_out = 8'h06;
			8'hA6: D_out = 8'h24;
			8'hA7: D_out = 8'h5C;
			8'hA8: D_out = 8'hC2;
			8'hA9: D_out = 8'hD3;
			8'hAA: D_out = 8'hAC;
			8'hAB: D_out = 8'h62;
			8'hAC: D_out = 8'h91;
			8'hAD: D_out = 8'h95;
			8'hAE: D_out = 8'hE4;
			8'hAF: D_out = 8'h79;
			8'hB0: D_out = 8'hE7;
			8'hB1: D_out = 8'hC8;
			8'hB2: D_out = 8'h37;
			8'hB3: D_out = 8'h6D;
			8'hB4: D_out = 8'h8D;
			8'hB5: D_out = 8'hD5;
			8'hB6: D_out = 8'h4E;
			8'hB7: D_out = 8'hA9;
			8'hB8: D_out = 8'h6C;
			8'hB9: D_out = 8'h56;
			8'hBA: D_out = 8'hF4;
			8'hBB: D_out = 8'hEA;
			8'hBC: D_out = 8'h65;
			8'hBD: D_out = 8'h7A;
			8'hBE: D_out = 8'hAE;
			8'hBF: D_out = 8'h08;
			8'hC0: D_out = 8'hBA;
			8'hC1: D_out = 8'h78;
			8'hC2: D_out = 8'h25;
			8'hC3: D_out = 8'h2E;
			8'hC4: D_out = 8'h1C;
			8'hC5: D_out = 8'hA6;
			8'hC6: D_out = 8'hB4;
			8'hC7: D_out = 8'hC6;
			8'hC8: D_out = 8'hE8;
			8'hC9: D_out = 8'hDD;
			8'hCA: D_out = 8'h74;
			8'hCB: D_out = 8'h1F;
			8'hCC: D_out = 8'h4B;
			8'hCD: D_out = 8'hBD;
			8'hCE: D_out = 8'h8B;
			8'hCF: D_out = 8'h8A;
			8'hD0: D_out = 8'h70;
			8'hD1: D_out = 8'h3E;
			8'hD2: D_out = 8'hB5;
			8'hD3: D_out = 8'h66;
			8'hD4: D_out = 8'h48;
			8'hD5: D_out = 8'h03;
			8'hD6: D_out = 8'hF6;
			8'hD7: D_out = 8'h0E;
			8'hD8: D_out = 8'h61;
			8'hD9: D_out = 8'h35;
			8'hDA: D_out = 8'h57;
			8'hDB: D_out = 8'hB9;
			8'hDC: D_out = 8'h86;
			8'hDD: D_out = 8'hC1;
			8'hDE: D_out = 8'h1D;
			8'hDF: D_out = 8'h9E;
			8'hE0: D_out = 8'hE1;
			8'hE1: D_out = 8'hF8;
			8'hE2: D_out = 8'h98;
			8'hE3: D_out = 8'h11;
			8'hE4: D_out = 8'h69;
			8'hE5: D_out = 8'hD9;
			8'hE6: D_out = 8'h8E;
			8'hE7: D_out = 8'h94;
			8'hE8: D_out = 8'h9B;
			8'hE9: D_out = 8'h1E;
			8'hEA: D_out = 8'h87;
			8'hEB: D_out = 8'hE9;
			8'hEC: D_out = 8'hCE;
			8'hED: D_out = 8'h55;
			8'hEE: D_out = 8'h28;
			8'hEF: D_out = 8'hDF;
			8'hF0: D_out = 8'h8C;
			8'hF1: D_out = 8'hA1;
			8'hF2: D_out = 8'h89;
			8'hF3: D_out = 8'h0D;
			8'hF4: D_out = 8'hBF;
			8'hF5: D_out = 8'hE6;
			8'hF6: D_out = 8'h42;
			8'hF7: D_out = 8'h68;
			8'hF8: D_out = 8'h41;
			8'hF9: D_out = 8'h99;
			8'hFA: D_out = 8'h2D;
			8'hFB: D_out = 8'h0F;
			8'hFC: D_out = 8'hB0;
			8'hFD: D_out = 8'h54;
			8'hFE: D_out = 8'hBB;
			8'hFF: D_out = 8'h16;
			default:
					D_out = 8'h16;

		endcase
	end
endmodule


module shift_rows(output reg [127:0] data_out, input [127:0] data_in);
always @(*)
begin
	      data_out[127:120] = data_in[127:120];
	      data_out[119:112] = data_in[87:80];
	      data_out[111:104] = data_in[47:40];
	      data_out[103:96] =  data_in[7:0];
	 
	      data_out[95:88] = data_in[95:88];
	      data_out[87:80] = data_in[55:48];
	      data_out[79:72] = data_in[15:8];
	      data_out[71:64] = data_in[103:96];
	 
	      data_out[63:56] = data_in[63:56];
	      data_out[55:48] = data_in[23:16];
	      data_out[47:40] = data_in[111:104];
	      data_out[39:32] = data_in[71:64];
			
	      data_out[31:24] = data_in[31:24];
	      data_out[23:16] = data_in[119:112];
	      data_out[15:8] =  data_in[79:72];
	      data_out[7:0] = data_in[39:32];
end
endmodule


module Key_expansion(output [127:0] key_r0,key_r1,key_r2,key_r3,key_r4,key_r5,key_r6,key_r7,key_r8,key_r9,key_r10,input [127:0]key);

		wire [31:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17,w18,w19,w20,w21,w22,w23,w24,w25,w26,w27,w28,w29,w30,w31,w32,w33,w34,w35,w36,w37,w38,w39,w40,w41,w42,w43;

		wire [31:0] out_g1,out_g2,out_g3,out_g4,out_g5,out_g6,out_g7,out_g8,out_g9,out_g10;
		
		
		assign 	w0=key[127:96];
		assign	w1=key[95:64];
		assign	w2=key[63:32];
		assign	w3=key[31:0];
		
		function_g G1(w3,4'd1,out_g1);
		
		assign	w4=w0^out_g1;
		assign	w5=w1^w0^out_g1;
		assign	w6=w2^w0^out_g1^w1;
		assign   w7=w3^w0^out_g1^w1^w2;
		
		function_g G2(w7,4'd2,out_g2);
		
		assign	w8=w4^out_g2;
		assign	w9=w4^w5^out_g2;
		assign	w10=w4^w5^w6^out_g2;
		assign	w11=w4^w5^w6^w7^out_g2;
		
		function_g G3(w11,4'd3,out_g3);
		
		assign	w12=w8^out_g3;
		assign	w13=w8^w9^out_g3;
		assign	w14=w8^w9^w10^out_g3;
		assign	w15=w8^w9^w10^w11^out_g3;
		
		function_g G4(w15,4'd4,out_g4);
		
		assign	w16=w12^out_g4;
		assign	w17=w12^w13^out_g4;
		assign	w18=w12^w13^w14^out_g4;
		assign	w19=w12^w13^w14^w15^out_g4;
		
		function_g G5(w19,4'd5,out_g5);
		
		assign	w20=w16^out_g5;
		assign	w21=w16^w17^out_g5;
		assign	w22=w16^w17^w18^out_g5;
		assign	w23=w16^w17^w18^w19^out_g5;
		
		function_g G6(w23,4'd6,out_g6);
		
		assign	w24=w20^out_g6;
		assign	w25=w20^w21^out_g6;
		assign	w26=w20^w21^w22^out_g6;
		assign	w27=w20^w21^w22^w23^out_g6;
		
		function_g G7(w27,4'd7,out_g7);
		
		assign	w28=w24^out_g7;
		assign	w29=w24^w25^out_g7;
		assign	w30=w24^w25^w26^out_g7;
		assign	w31=w24^w25^w26^w27^out_g7;
		
		function_g G8(w31,4'd8,out_g8);
		
		assign	w32=w28^out_g8;
		assign	w33=w28^w29^out_g8;
		assign	w34=w28^w29^w30^out_g8;
		assign	w35=w28^w29^w30^w31^out_g8;
		
		function_g G9(w35,4'd9,out_g9);
		
	assign	w36=w32^out_g9;
	assign	w37=w32^w33^out_g9;
	assign	w38=w32^w33^w34^out_g9;
	assign	w39=w32^w33^w34^w35^out_g9;
		
		function_g G10(w39,4'd10,out_g10);
		
	assign	w40=w36^out_g10;
	assign	w41=w36^w37^out_g10;
	assign	w42=w36^w37^w38^out_g10;
	assign	w43=w36^w37^w38^w39^out_g10;
		
		
		assign key_r0={w0,w1,w2,w3};
		assign key_r1={w4,w5,w6,w7};
		assign key_r2={w8,w9,w10,w11};
		assign key_r3={w12,w13,w14,w15};
		assign key_r4={w16,w17,w18,w19};
		assign key_r5={w20,w21,w22,w23};
		assign key_r6={w24,w25,w26,w27};		
		assign key_r7={w28,w29,w30,w31};
		assign key_r8={w32,w33,w34,w35};
		assign key_r9={w36,w37,w38,w39};
		assign key_r10={w40,w41,w42,w43};


endmodule



module function_g(input [31:0] w,input [3:0] i,output [31:0] D_out);
	
	wire [31:0] shift_w ;
	wire [7:0] S_wire;
	reg [7:0] RC;

	assign shift_w[31:24] = w[23:16];//w0
	assign shift_w[23:16] = w[15:8];//w1
	assign shift_w[15:8] = w[7:0];//w2
	assign shift_w[7:0] = w[31:24];//w3
	
	S_BOX S3( D_out[7:0], shift_w[7:0]);
	S_BOX S2( D_out[15:8], shift_w[15:8]);
	S_BOX S1( D_out[23:16], shift_w[23:16]);
	S_BOX S0( S_wire, shift_w[31:24]);
	
	always@(*)
		begin
		case (i)
		 4'd01: RC = 8'h01;
		 4'd02: RC = 8'h02;
		 4'd03: RC = 8'h04;
		 4'd04: RC = 8'h08;
		 4'd05: RC = 8'h10;
		 4'd06: RC = 8'h20;
		 4'd07: RC = 8'h40;
		 4'd08: RC = 8'h80;
		 4'd09: RC = 8'h1B;
		 4'd10: RC = 8'h36;
		 default:
			RC = 8'h01;
			endcase
			end
		
		assign D_out[31:24]=S_wire^RC;
		
endmodule




module mix_cols(output [127:0] Dout, input [127:0] Din);
wire [7:0] b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15;
reg [7:0] C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15;

	assign b0 = Din[7:0];
	assign b1 = Din[15:8];
	assign b2 = Din[23:16];
	assign b3 = Din[31:24];
	assign b4 = Din[39:32];
	assign b5 = Din[47:40];
	assign b6 = Din[55:48];
	assign b7 = Din[63:56];
	assign b8 = Din[71:64];
	assign b9 = Din[79:72];
	assign b10 = Din[87:80];
	assign b11 = Din[95:88];
	assign b12 = Din[103:96];
	assign b13 = Din[111:104];
	assign b14 = Din[119:112];
	assign b15 = Din[127:120];
	
	assign Dout[7:0] = C0;
	assign Dout[15:8] = C1;
	assign Dout[23:16] = C2;
	assign Dout[31:24] = C3;
	assign Dout[39:32] = C4;
	assign Dout[47:40] = C5;
	assign Dout[55:48] = C6;
	assign Dout[63:56] = C7;
	assign Dout[71:64] = C8;
	assign Dout[79:72] = C9;
	assign Dout[87:80] = C10;
	assign Dout[95:88] = C11;
	assign Dout[103:96] = C12;
	assign Dout[111:104] = C13;
	assign Dout[119:112] = C14;
	assign Dout[127:120] = C15;
	
	
	always @(*) begin
		C15 = multiply(b15, 2) ^ multiply(b14, 3) ^ multiply(b13, 1) ^ multiply(b12, 1);
		C14 = multiply(b15, 1) ^ multiply(b14, 2) ^ multiply(b13, 3) ^ multiply(b12, 1);
		C13 = multiply(b15, 1) ^ multiply(b14, 1) ^ multiply(b13, 2) ^ multiply(b12, 3);
		C12 = multiply(b15, 3) ^ multiply(b14, 1) ^ multiply(b13, 1) ^ multiply(b12, 2);		

		C11 = multiply(b11, 2) ^ multiply(b10, 3) ^ multiply(b9, 1) ^ multiply(b8, 1);
		C10 = multiply(b11, 1) ^ multiply(b10, 2) ^ multiply(b9, 3) ^ multiply(b8, 1);
		C9 = multiply(b11, 1) ^ multiply(b10, 1) ^ multiply(b9, 2) ^ multiply(b8, 3);
		C8 = multiply(b11, 3) ^ multiply(b10, 1) ^ multiply(b9, 1) ^ multiply(b8, 2);

		C7 = multiply(b7, 2) ^ multiply(b6, 3) ^ multiply(b5, 1) ^ multiply(b4, 1);
		C6 = multiply(b7, 1) ^ multiply(b6, 2) ^ multiply(b5, 3) ^ multiply(b4, 1);
		C5 = multiply(b7, 1) ^ multiply(b6, 1) ^ multiply(b5, 2) ^ multiply(b4, 3);
		C4 = multiply(b7, 3) ^ multiply(b6, 1) ^ multiply(b5, 1) ^ multiply(b4, 2);

		C3 = multiply(b3, 2) ^ multiply(b2, 3) ^ multiply(b1, 1) ^ multiply(b0, 1);
		C2 = multiply(b3, 1) ^ multiply(b2, 2) ^ multiply(b1, 3) ^ multiply(b0, 1);
		C1 = multiply(b3, 1) ^ multiply(b2, 1) ^ multiply(b1, 2) ^ multiply(b0, 3);
		C0 = multiply(b3, 3) ^ multiply(b2, 1) ^ multiply(b1, 1) ^ multiply(b0, 2);
	end
	
	function integer multiply (input integer a, input integer b);
			if (b == 1)
			begin
				multiply = a;
			end
			else if (b == 2)
			begin
				multiply = (a < 8'h80) ? a << 1 : (a << 1) & 8'hFF ^ 8'h1B;
			end
			else if (b == 3)
				multiply = (a < 8'h80) ? a << 1 ^ a : ((a << 1) & 8'hFF) ^ 8'h1B ^ a;
	endfunction
endmodule




module Register (output reg [127:0] Q, input [127:0] D, input enable, clock, reset);
	always @(posedge clock, posedge reset) begin
		if (reset)
			Q <= 128'd0;
		else if (enable)
			Q <= D;
	end
endmodule

module Counter(output reg [3:0] count, input [3:0] loadValue, input load, increment, decrement, clock, reset);
	always @(posedge clock, posedge reset) begin
		if (reset)
			count <= 0;
		else if (load)
			count <= loadValue;
		else if (increment)
			count <= count + 1;
		else if (decrement)
			count <= count - 1;
	end

endmodule



