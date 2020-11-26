`include "define.vh"

module EXE(
    input wire clk,
    input wire rst,
    input wire en,
    input wire id_valid,
    input wire [31:0] inst_addr_next,
    input wire [4:0] regw_addr_id,
    input wire [31:0] data_rs,
    input wire [31:0] data_rt,
    input wire [31:0] data_imm,
    // 8 signals from controller in ID
    input wire [1:0] exe_a_src,
    input wire [1:0] exe_b_src,
    input wire [3:0] exe_alu_oper,
    input wire mem_ren,
    input wire mem_wen,
    input wire wb_data_src,
    input wire wb_wen,
    input wire [31:0] inst_data,
    input wire [31:0] inst_addr,
    input wire is_load_ctrl,  // whether current instruction is load instruction
    input wire [31:0] mem_data_out,
    input wire [31:0] alu_out_mem,
    input wire [31:0] regw_data_wb,
    input wire [31:0] data_rs_fwd,
    input wire [31:0] data_rt_fwd,
    input wire fwd_m_ctrl,  // forwarding selection for memory
    output reg [31:0] inst_addr_out,  // address of instruction needed
    output reg [31:0] inst_data_out,
    `ifdef DEBUG
	output wire [31:0] opa_out,
	output wire [31:0] opb_out,
    `endif
    output reg [31:0] inst_addr_next_out,
    output reg [4:0] regw_addr_exe, 
    output wire [31:0] alu_out,
    output reg [31:0] data_rs_exe,
    output reg [31:0] data_rt_exe,
    output reg mem_ren_exe,
    output reg mem_wen_exe,
    output reg wb_data_src_exe,
    output reg wb_wen_exe,
    output wire rs_rt_equal_exe,
    output reg is_branch_exe,
    output reg is_load_exe,  // whether instruction in EXE stage is load instruction
    output reg fwd_m_exe,
    output reg valid
    );
    
    `include "mips_define.vh"
    
    reg [31:0] data_imm_exe;
    reg [31:0] opa_exe, opb_exe;
    reg [1:0] fwd_a_exe, fwd_b_exe;
    
    `ifdef DEBUG
    assign opa_out = opa_exe, opb_out = opb_exe;
    `endif
    
    reg [1:0] exe_a_src_exe;
    reg [1:0] exe_b_src_exe;
    reg [3:0] exe_alu_oper_exe;
    
    // EXE stage
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			inst_addr_out <= 0;
			inst_data_out <= 0;
			inst_addr_next_out <= 0;
			regw_addr_exe <= 0;
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
			fwd_m_exe <= 0;
			is_load_exe <= 0;
		end
		else if (en) begin
			valid <= id_valid;
			inst_addr_out <= inst_addr;
			inst_data_out <= inst_data;
			inst_addr_next_out <= inst_addr_next;
			regw_addr_exe <= regw_addr_id;
			exe_a_src_exe <= exe_a_src;
			exe_b_src_exe <= exe_b_src;
			data_rs_exe <= data_rs_fwd;
			data_rt_exe <= data_rt_fwd;
			data_imm_exe <= data_imm;
			exe_alu_oper_exe <= exe_alu_oper;
			mem_ren_exe <= mem_ren;
			mem_wen_exe <= mem_wen;
			wb_data_src_exe <= wb_data_src;
			wb_wen_exe <= wb_wen;
			fwd_m_exe <= fwd_m_ctrl;
			is_load_exe <= is_load_ctrl;
		end
	end

	always @(*) begin
		opa_exe = data_rs_exe;
		opb_exe = data_rt_exe;
		case (exe_a_src_exe)
		    EXE_A_RS: opa_exe = data_rs_exe;
			EXE_A_LINK: opa_exe = inst_addr_next_out;
		endcase
		case (exe_b_src_exe)
			EXE_B_RT: opb_exe = data_rt_exe;
			EXE_B_IMM: opb_exe = data_imm_exe;
			EXE_B_LINK: opb_exe = 32'h4;  // linked address is the next one of current instruction
		endcase
	end
	
	alu ALU (
		.a(opa_exe),
		.b(opb_exe),
		.oper(exe_alu_oper_exe),
		.result(alu_out)
		);
		
endmodule
