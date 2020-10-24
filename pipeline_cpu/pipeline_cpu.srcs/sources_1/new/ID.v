`include "define.vh"

module ID(
    input wire clk,
	input wire id_rst,  // stage reset signal
	input wire id_en,  // stage enable signal
	input wire if_valid,
	input wire [31:0] inst_addr,
	input wire [31:0] inst_data,
	input wire [31:0] inst_addr_next,
    `ifdef DEBUG
    input wire [4:0] debug_addr,
    output reg [31:0] debug_data_reg,
    `endif
	output reg [4:0] regw_addr_id,
	output reg [31:0] inst_addr_id,  // address of instruction needed
	output reg [31:0] inst_data_id,  // instruction fetched
	output reg 	[31:0] inst_addr_next_id,
	output reg id_valid  // working flag	
    );
    
    
    `include "mips_define.vh"
    
	wire [4:0] addr_rs, addr_rt, addr_rd;
	wire inst_data_ctrl, is_branch_exe, regw_addr_exe, wb_wen_exe, is_branch_mem,
		regw_addr_mem, wb_wen_mem, pc_src_ctrl, imm_ext_ctrl, exe_a_src_ctrl,
		exe_b_src_ctrl, exe_alu_oper_ctrl, mem_ren_ctrl, mem_wen_ctrl, wb_addr_src_ctrl,
		wb_data_src_ctrl, wb_wen_ctrl;
    
    // ID stage
	always @(posedge clk) begin
		if (id_rst) begin
			id_valid <= 0;
			inst_addr_id <= 0;
			inst_data_id <= 0;
			inst_addr_next_id <= 0;
		end
		else if (id_en) begin
			id_valid <= if_valid;
			inst_addr_id <= inst_addr;
			inst_data_id <= inst_data;
			inst_addr_next_id <= inst_addr_next;
		end
	end
	
	assign
		addr_rs = inst_data_id[25:21],
		addr_rt = inst_data_id[20:16],
		addr_rd = inst_data_id[15:11],
		data_imm = imm_ext_ctrl ? {{16{inst_data_id[15]}}, inst_data_id[15:0]} : {16'b0, inst_data_id[15:0]};
	
	always @(*) begin
		regw_addr_id = inst_data_id[15:11];
		case (wb_addr_src_ctrl)
			WB_ADDR_RD: regw_addr_id = addr_rd;
			WB_ADDR_RT: regw_addr_id = addr_rt;
			WB_ADDR_LINK: regw_addr_id = GPR_RA;
		endcase
	end

	regfile REGFILE (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_reg),
		`endif
		.addr_a(addr_rs),
		.data_a(data_rs),
		.addr_b(addr_rt),
		.data_b(data_rt),
		.en_w(wb_wen_wb),
		.addr_w(regw_addr_wb),
		.data_w(regw_data_wb)
		);
		
	// controller
	controller CONTROLLER (
		.clk(clk),
		.rst(rst),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		`endif
		.inst(inst_data_ctrl),
		.is_branch_exe(is_branch_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_branch_mem(is_branch_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src(pc_src_ctrl),
		.imm_ext(imm_ext_ctrl),
		.exe_a_src(exe_a_src_ctrl),
		.exe_b_src(exe_b_src_ctrl),
		.exe_alu_oper(exe_alu_oper_ctrl),
		.mem_ren(mem_ren_ctrl),
		.mem_wen(mem_wen_ctrl),
		.wb_addr_src(wb_addr_src_ctrl),
		.wb_data_src(wb_data_src_ctrl),
		.wb_wen(wb_wen_ctrl),
		.unrecognized()
	);

endmodule
