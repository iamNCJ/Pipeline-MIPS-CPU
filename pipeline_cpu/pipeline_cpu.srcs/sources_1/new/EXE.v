`include "define.vh"

module EXE(
    input wire clk,
    input wire rst,
    input wire en,
    input wire id_valid,
    input wire [31:0] inst_addr_next,
    `ifdef DEBUG
    input wire [31:0] inst_data,
    input wire [31:0] inst_addr,
    output reg [31:0] inst_addr_out,  // address of instruction needed
	output reg [31:0] inst_data_out,
    `endif
    output reg [31:0] inst_addr_next_out,
    output reg valid
    );
    
    `include "mips_define.vh"

    // EXE stage
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			inst_addr_out <= 0;
			inst_data_out <= 0;
			inst_addr_next_out <= 0;
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
		else if (en) begin
			valid <= id_valid;
			inst_addr_out <= inst_addr;
			inst_data_out <= inst_data;
			inst_addr_next_out <= inst_addr_next;
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
			EXE_A_LINK: opa_exe = inst_addr_next_out;
			EXE_A_BRANCH: opa_exe = inst_addr_next_out;
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
