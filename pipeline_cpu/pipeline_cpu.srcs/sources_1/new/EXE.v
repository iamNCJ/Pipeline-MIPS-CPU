`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2020 03:43:24 PM
// Design Name: 
// Module Name: EXE
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


module EXE(
    input wire clk,
    input wire exe_rst,  // stage reset signal
	input wire exe_en,  // stage enable signal
	input wire [31:0] regw_addr_id,
	input wire id_valid,
	input wire [31:0] inst_addr_id,
	input wire [2:0] pc_src_ctrl,
	input wire [31:0] inst_data_id,
	input wire [31:0] inst_addr_next_id,
	input wire [31:0] data_rs,
	input wire [31:0] data_rt,
	input wire [31:0] data_imm,
	input wire wb_data_src_ctrl, // data source of data being written back to registers
	input wire wb_wen_ctrl, // register write enable signal
	output reg [1:0] exe_a_src_exe,
	output reg exe_valid,
	output reg [31:0] regw_addr_exe,
	output reg [2:0] pc_src_exe,
	output reg [1:0] exe_b_src_exe,
	output reg [31:0] data_rs_exe,
	output reg [31:0] data_rt_exe,
	output reg [31:0] data_imm_exe,
	output reg [31:0] inst_addr_exe,
	output reg [31:0] inst_data_exe,
	output reg [31:0] inst_addr_next_exe,
	output reg [3:0] exe_alu_oper_exe,
	output reg mem_ren_exe,
	output reg mem_wen_exe,
	output reg wb_data_src_exe,
	output reg wb_wen_exe,
	output reg is_branch_exe,
	output reg [31:0] opa_exe,
	output reg [31:0] opb_exe
    );
	
	wire [1:0] exe_a_src_ctrl;  // data source of operand A for ALU
	wire [1:0] exe_b_src_ctrl;  // data source of operand B for ALU
	wire [3:0] exe_alu_oper_ctrl;  // ALU operation type
	wire mem_ren_ctrl;  // memory read enable signal
	wire mem_wen_ctrl;  // memory write enable signal


    `include "mips_define.vh"

    
    // EXE stage
	always @(posedge clk) begin
		if (exe_rst) begin
			exe_valid <= 0;
			inst_addr_exe <= 0;
			inst_data_exe <= 0;
			inst_addr_next_exe <= 0;
			regw_addr_exe <= 0;
			pc_src_exe <= 0;
			exe_a_src_exe <= 0;
			exe_b_src_exe <= 0;
			data_rs_exe <= 0;
			data_rt_exe <= 0;
			data_imm_exe <= 0;
			exe_alu_oper_exe <= 0;
			mem_ren_exe <= 0;
			mem_wen_exe <= 0;
			wb_data_src_exe <= 0;
			wb_wen_exe <= 0;
		end
		else if (exe_en) begin
			exe_valid <= id_valid;
			inst_addr_exe <= inst_addr_id;
			inst_data_exe <= inst_data_id;
			inst_addr_next_exe <= inst_addr_next_id;
			regw_addr_exe <= regw_addr_id;
			pc_src_exe <= pc_src_ctrl;
			exe_a_src_exe <= exe_a_src_ctrl;
			exe_b_src_exe <= exe_b_src_ctrl;
			data_rs_exe <= data_rs;
			data_rt_exe <= data_rt;
			data_imm_exe <= data_imm;
			exe_alu_oper_exe <= exe_alu_oper_ctrl;
			mem_ren_exe <= mem_ren_ctrl;
			mem_wen_exe <= mem_wen_ctrl;
			wb_data_src_exe <= wb_data_src_ctrl;
			wb_wen_exe <= wb_wen_ctrl;
		end
	end
	
	always @(*) begin
		is_branch_exe <= (pc_src_exe != PC_NEXT);
	end
	
	assign
		rs_rt_equal_exe = (data_rs_exe == data_rt_exe);
	
	always @(*) begin
		opa_exe = data_rs_exe;
		opb_exe = data_rt_exe;
		case (exe_a_src_exe)
			EXE_A_RS: opa_exe = data_rs_exe;
			EXE_A_LINK: opa_exe = inst_addr_next_exe;
			EXE_A_BRANCH: opa_exe = inst_addr_next_exe;
		endcase
		case (exe_b_src_exe)
			EXE_B_RT: opb_exe = data_rt_exe;
			EXE_B_IMM: opb_exe = data_imm_exe;
			EXE_B_LINK: opb_exe = 32'h0;  // linked address is the next one of current instruction
			EXE_B_BRANCH: opb_exe = {data_imm_exe[29:0], 2'b0};
		endcase
	end
	
	alu ALU (
		.a(opa_exe),
		.b(opb_exe),
		.oper(exe_alu_oper_exe),
		.result(alu_out_exe)
		);
		
endmodule
