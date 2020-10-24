`include "define.vh"


/**
 * Data Path for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module datapath (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [5:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// control signals
	output reg [31:0] inst_data_id,  // instruction
	output reg is_branch_exe,  // whether instruction in EXE stage is jump/branch instruction
	output reg [4:0] regw_addr_exe,  // register write address from EXE stage
	output reg wb_wen_exe,  // register write enable signal feedback from EXE stage
	output reg is_branch_mem,  // whether instruction in MEM stage is jump/branch instruction
	output reg [4:0] regw_addr_mem,  // register write address from MEM stage
	output reg wb_wen_mem,  // register write enable signal feedback from MEM stage
	input wire [2:0] pc_src_ctrl,  // how would PC change to next
	input wire imm_ext_ctrl,  // whether using sign extended to immediate data
	input wire [1:0] wb_addr_src_ctrl,  // address source to write data back to registers
	input wire wb_data_src_ctrl,  // data source of data being written back to registers
	input wire wb_wen_ctrl  // register write enable signal
	);
	
	// IF signals
	wire if_rst;  // stage reset signal
	wire if_en;  // stage enable signal
	wire if_valid;  // working flag
	// ID signals
	wire id_rst;
	wire id_en;
	wire id_valid;
	// EXE signals
	wire exe_rst;
	wire exe_en;
	wire exe_valid;
	// MEM signals
	wire mem_rst;
	wire mem_en;
	wire mem_valid;
	// WB signals
	wire wb_rst;
	wire wb_en;
	wire wb_valid;
	
	`include "mips_define.vh"
	
//	reg inst_ren;  // instruction read enable signal
    wire inst_ren;
	
	// control signals
	reg [2:0] pc_src_exe, pc_src_mem;
	reg [1:0] exe_a_src_exe, exe_b_src_exe;
	reg [3:0] exe_alu_oper_exe;
	reg mem_ren_exe, mem_ren_mem;
	reg mem_wen_exe, mem_wen_mem;
	reg wb_data_src_exe, wb_data_src_mem, wb_data_src_wb;
	
	// IF signals
	wire [31:0] inst_addr_next;
	
	// ID signals
	reg [31:0] inst_addr_id;
	reg [4:0] regw_addr_id;
	wire [31:0] data_rs, data_rt, data_imm;
	
	// EXE signals
	reg [31:0] inst_addr_exe;
	reg [31:0] inst_addr_next_exe;
	reg [31:0] inst_data_exe;
	reg [31:0] data_rs_exe, data_rt_exe, data_imm_exe;
	wire [31:0] opa_exe, opb_exe;
	wire [31:0] alu_out_exe;
	wire rs_rt_equal_exe;
	
	// MEM signals
	reg [31:0] inst_addr_mem;
	reg [31:0] inst_addr_next_mem;
	reg [31:0] inst_data_mem;
	reg [4:0] data_rs_mem;
	reg [31:0] data_rt_mem;
	reg [31:0] alu_out_mem;
	reg [31:0] branch_target_mem;
	reg rs_rt_equal_mem;
	
	// WB signals
	reg wb_wen_wb;
	reg [31:0] alu_out_wb;
	reg [31:0] mem_din_wb;
	reg [4:0] regw_addr_wb;
	reg [31:0] regw_data_wb;
	
    wire [31:0] inst_addr;  // address of instruction needed
	wire [31:0] inst_data;  // instruction fetched
	
//	// debug
//	`ifdef DEBUG
//	wire [31:0] debug_data_reg;
//	reg [31:0] debug_data_signal;
	
//	always @(posedge clk) begin
//		case (debug_addr[4:0])
//			0: debug_data_signal <= inst_addr;
//			1: debug_data_signal <= inst_data;
//			2: debug_data_signal <= inst_addr_id;
//			3: debug_data_signal <= inst_data_id;
//			4: debug_data_signal <= inst_addr_exe;
//			5: debug_data_signal <= inst_data_exe;
//			6: debug_data_signal <= inst_addr_mem;
//			7: debug_data_signal <= inst_data_mem;
//			8: debug_data_signal <= {27'b0, addr_rs};
//			9: debug_data_signal <= data_rs;
//			10: debug_data_signal <= {27'b0, addr_rt};
//			11: debug_data_signal <= data_rt;
//			12: debug_data_signal <= data_imm;
//			13: debug_data_signal <= opa_exe;
//			14: debug_data_signal <= opb_exe;
//			15: debug_data_signal <= alu_out_exe;
//			16: debug_data_signal <= 0;
//			17: debug_data_signal <= 0;
//			18: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
//			19: debug_data_signal <= mem_addr;
//			20: debug_data_signal <= mem_din;
//			21: debug_data_signal <= mem_dout;
//			22: debug_data_signal <= {27'b0, regw_addr_wb};
//			23: debug_data_signal <= regw_data_wb;
//			default: debug_data_signal <= 32'hFFFF_FFFF;
//		endcase
//	end
	
//	assign
//		debug_data = debug_addr[5] ? debug_data_signal : debug_data_reg;
//	`endif
	
//	IF IF_PART(
//	   .clk(clk),
//	   .inst_addr(inst_addr), 
//	   .inst_data(inst_data), 
//	   .if_rst(if_rst), 
//	   .if_en(if_en), 
//	   .if_valid(if_valid),
//	   .inst_ren(inst_ren),
//	   .is_branch_mem(is_branch_mem),
//	   .inst_addr_next(inst_addr_next),
//	   .branch_target_mem(branch_target_mem)
//	   );
	   
//    ID ID_PART(
//        .clk(clk),
//        .id_rst(id_rst),  // stage reset signal
//        .id_en(id_en),  // stage enable signal
//        .if_valid(if_valid),
//        .inst_addr(inst_addr),
//        .inst_data(inst_data),
//        .inst_addr_next(inst_addr_next),
//        `ifdef DEBUG
//        .debug_addr(debug_addr),
//        .debug_data_reg(debug_data_reg),
//        `endif
//        .regw_addr_id(regw_addr_id),
//        .inst_addr_id(inst_addr_id),  // address of instruction needed
//        .inst_data_id(inst_data_id),  // instruction fetched
//        .inst_addr_next_id(inst_addr_next_id),
//        .id_valid(id_valid)  // working flag	
//    );
    
//    EXE EXE_PART();
    
//    MEM MEM_PART();
    
//    WB WB_PART();
	
//	// pipeline
//	always @(*) begin
//		if_rst = 0;
//		if_en = 1;
//		id_rst = 0;
//		id_en = 1;
//		exe_rst = 0;
//		exe_en = 1;
//		mem_rst = 0;
//		mem_en = 1;
//		wb_rst = 0;
//		wb_en = 1;
//		if (rst) begin
//			if_rst = 1;
//			id_rst = 1;
//			exe_rst = 1;
//			mem_rst = 1;
//			wb_rst = 1;
//		end
//		`ifdef DEBUG
//		// suspend and step execution
//		else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
//			if_en = 0;
//			id_en = 0;
//			exe_en = 0;
//			mem_en = 0;
//			wb_en = 0;
//		end
//		`endif
//		// this stall indicate that ID is waiting for previous instruction, should insert NOPs between ID and EXE.
//		else if (reg_stall) begin
//			if_en = 0;
//			id_en = 0;
//			exe_rst = 1;
//		end
//		// this stall indicate that a jump/branch instruction is running, so that 3 NOP should be inserted between IF and ID
//		else if (branch_stall) begin
//			id_rst = 1;
//		end
//	end
	
endmodule
