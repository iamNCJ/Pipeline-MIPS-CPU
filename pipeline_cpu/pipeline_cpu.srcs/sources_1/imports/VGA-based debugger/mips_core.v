`include "define.vh"


/**
 * MIPS 5-stage pipeline CPU Core
 */
module mips_core (
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [6:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire interrupter  // interrupt source, for future use
	);
	
	`include "mips_define.vh"
	
	wire [4:0] regw_addr, regw_addr_exe;
    wire [31:0] inst_addr_next, inst_addr_next_id, inst_addr_next_exe;
    wire [31:0] data_rs, data_rt, data_imm;
    wire [1:0] pc_src;  // how would PC change to next
    wire [1:0] exe_a_src;  // data source of operand A for ALU
    wire [1:0] exe_b_src;  // data source of operand B for ALU
    wire [3:0] exe_alu_oper;  // ALU operation type
    wire mem_ren, mem_ren_exe;  // memory read enable signal
    wire mem_wen, mem_wen_exe;  // memory write enable signal
    wire wb_data_src;  // data source of data being written back to registers
    wire wb_wen;  // register write enable signal
    wire [1:0] pc_src_exe;
    wire [31:0] alu_out_exe;
    wire [31:0] inst_addr, inst_addr_id, inst_addr_exe, inst_addr_mem;
    wire [31:0] inst_data, inst_data_id, inst_data_exe, inst_data_mem;
    wire [31:0] data_rs_exe, data_rt_exe;
    wire wb_data_src_exe;
    wire rs_rt_equal_exe;
    wire [31:0] branch_target_mem;
    wire wb_wen_wb;
    wire [31:0] regw_data_wb;
    wire [4:0] regw_addr_wb;
    wire [31:0] alu_out_mem;
    wire wb_data_src_mem;
	wire [1:0] fwd_a_ctrl;  // forwarding selection for channel A
    wire [1:0] fwd_b_ctrl;  // forwarding selection for channel B
    wire fwd_m_exe;

	// debugger
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	wire inst_ren; // instruction read enable signal
	wire [4:0] addr_rs, addr_rt, addr_rd;
	wire [31:0] opa_exe, opb_exe;
	wire [31:0] mem_addr_out, mem_data_write, mem_data_read;
	wire is_load_exe, is_load_mem;
	
	always @(posedge clk) begin
		case (debug_addr[4:0])
			0: debug_data_signal <= inst_addr;
			1: debug_data_signal <= inst_data;
			2: debug_data_signal <= inst_addr_id;
			3: debug_data_signal <= inst_data_id;
			4: debug_data_signal <= inst_addr_exe;
			5: debug_data_signal <= inst_data_exe;
			6: debug_data_signal <= inst_addr_mem;
			7: debug_data_signal <= inst_data_mem;
			8: debug_data_signal <= {27'b0, addr_rs};
			9: debug_data_signal <= data_rs;
			10: debug_data_signal <= {27'b0, addr_rt};
			11: debug_data_signal <= data_rt;
			12: debug_data_signal <= data_imm;
			13: debug_data_signal <= opa_exe;
			14: debug_data_signal <= opb_exe;
			15: debug_data_signal <= alu_out_exe;
			16: debug_data_signal <= 0;
			17: debug_data_signal <= {16'b0, 2'b0, fwd_a_ctrl, 2'b0, fwd_b_ctrl, 8'b0};
			18: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
			19: debug_data_signal <= mem_addr_out;
			20: debug_data_signal <= mem_data_read; // data read from memory
			21: debug_data_signal <= mem_data_write;
			22: debug_data_signal <= {27'b0, regw_addr_wb};
			23: debug_data_signal <= regw_data_wb;
			default: debug_data_signal <= 32'hFFFF_FFFF;
		endcase
	end
	
	assign debug_data = debug_addr[5] ? debug_data_signal : debug_data_reg;
	
	reg debug_step_prev;
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	`endif
	
	// pipeline
	wire reg_stall, branch_stall;
	reg if_rst, id_rst, exe_rst, mem_rst, wb_rst;  // stage reset signal
	reg if_en, id_en, exe_en, mem_en, wb_en;  // stage enable signal
	wire if_valid, id_valid, exe_valid, mem_valid, wb_valid;  // stage valid flag
	wire is_branch_exe;  // whether instruction in EXE stage is jump/branch instruction
	wire wb_wen_exe;  // register write enable signal feedback from EXE stage
	wire is_branch_mem;  // whether instruction in MEM stage is jump/branch instruction
	wire [4:0] regw_addr_mem;  // register write address from MEM stage
	wire wb_wen_mem;  // register write enable signal feedback from MEM stage
	reg reg_rst; // reset regfile
    wire is_load_ctrl;
    wire fwd_m_ctrl;
	
	always @(*) begin
		if_rst = 0;
		if_en = 1;
		id_rst = 0;
		id_en = 1;
		exe_rst = 0;
		exe_en = 1;
		mem_rst = 0;
		mem_en = 1;
		wb_rst = 0;
		wb_en = 1;
		reg_rst = 0;
		if (rst) begin
			if_rst = 1;
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			wb_rst = 1;
			reg_rst = 1;
		end
		`ifdef DEBUG
		// suspend and step execution
		else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 0;
		end
		`endif
		// this stall indicate that ID is waiting for previous LW instruction, should insert one NOP between ID and EXE.
		else if (reg_stall) begin
			if_en = 0;
			id_en = 0;
			exe_rst = 1;
		end
		// this stall indicate that a jump/branch instruction is running, so that 3 NOP should be inserted between IF and ID
		else if (branch_stall) begin
			id_rst = 1;
		end
	end
	
	IF IF_STAGE (
	   .clk(clk),
	   .rst(if_rst),
	   .en(if_en),
	   .pc_src_ctrl(pc_src),
	   .inst_addr_id(inst_addr_id),
	   .inst_data_id(inst_data_id),
	   .data_rs_fwd(data_rs),
	   .inst_addr_next_id(inst_addr_next_id),
	   .data_imm(data_imm),
	   `ifdef DEBUG
	   .inst_ren(inst_ren),
	   `endif
	   .pc(inst_addr),
	   .valid(if_valid),
	   .inst_addr_next(inst_addr_next),
	   .inst_data(inst_data)
	   );
	   
    ID ID_STAGE (
        .clk(clk),
        .rst(id_rst),
        .en(id_en),
        .reg_rst(reg_rst),
        .if_valid(if_valid),
        .inst_data(inst_data),
        .inst_addr_next(inst_addr_next),
        .wb_wen_wb(wb_wen_wb),
        .regw_addr_wb(regw_addr_wb),
        .regw_data_wb(regw_data_wb),
        .inst_addr(inst_addr),
        .inst_addr_out(inst_addr_id),
        .inst_data_out(inst_data_id),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_branch_mem(is_branch_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.is_load_exe(is_load_exe),
		.is_load_mem(is_load_mem),
		.mem_data_out(mem_data_read),
		.alu_out_exe(alu_out_exe),
		.alu_out_mem(alu_out_mem),
        `ifdef DEBUG
        .debug_addr(debug_addr),
        .debug_data_reg(debug_data_reg),
        .addr_rs_out(addr_rs),
        .addr_rt_out(addr_rt),
        .addr_rd_out(addr_rd),
        `endif
        .regw_addr(regw_addr),
        .inst_addr_next_out(inst_addr_next_id),
        .data_rs_fwd(data_rs),
        .data_rt_fwd(data_rt),
        .data_imm(data_imm),
        .pc_src(pc_src),  // how would PC change to next
        .exe_a_src(exe_a_src),  // data source of operand A for ALU
        .exe_b_src(exe_b_src),  // data source of operand B for ALU
        .exe_alu_oper(exe_alu_oper),  // ALU operation type
        .mem_ren(mem_ren),  // memory read enable signal
        .mem_wen(mem_wen),  // memory write enable signal
        .wb_data_src(wb_data_src),  // data source of data being written back to registers
        .wb_wen(wb_wen),  // register write enable signal
        .reg_stall(reg_stall),
        .branch_stall(branch_stall),
        .fwd_a_ctrl(fwd_a_ctrl),
        .fwd_b_ctrl(fwd_b_ctrl),
        .is_load_id(is_load_ctrl),
        .fwd_m_ctrl(fwd_m_ctrl),
        .valid(id_valid)  // working flag
    );

    EXE EXE_STAGE (
        .clk(clk),
        .en(exe_en),
        .rst(exe_rst),
        .id_valid(id_valid),
        .inst_addr_next(inst_addr_next_id),
        .regw_addr_id(regw_addr),
        .data_imm(data_imm),
        .exe_a_src(exe_a_src),
        .exe_b_src(exe_b_src),
        .exe_alu_oper(exe_alu_oper),
        .mem_ren(mem_ren),
        .mem_wen(mem_wen),
        .wb_data_src(wb_data_src),
        .wb_wen(wb_wen),
        .inst_data(inst_data_id),
        .inst_addr(inst_addr_id),
        .is_load_ctrl(is_load_ctrl),
        .data_rs_fwd(data_rs),
        .data_rt_fwd(data_rt),
        .fwd_m_ctrl(fwd_m_ctrl),
        .inst_addr_out(inst_addr_exe),
        .inst_data_out(inst_data_exe),
        `ifdef DEBUG
        .opa_out(opa_exe),
        .opb_out(opb_exe),
        `endif
        .inst_addr_next_out(inst_addr_next_exe),
        .regw_addr_exe(regw_addr_exe),
        .alu_out(alu_out_exe),
        .data_rs_exe(data_rs_exe),
        .data_rt_exe(data_rt_exe),
        .mem_ren_exe(mem_ren_exe),
        .mem_wen_exe(mem_wen_exe),
        .wb_data_src_exe(wb_data_src_exe),
        .wb_wen_exe(wb_wen_exe),
        .is_load_exe(is_load_exe),
        .fwd_m_exe(fwd_m_exe),
        .valid(exe_valid)
    );
    
    MEM MEM_STAGE (
        .clk(clk),
        .en(mem_en),
        .rst(mem_rst),
        .exe_valid(exe_valid),
        .inst_addr(inst_addr_exe),
        .inst_data(inst_data_exe),
        .regw_addr(regw_addr_exe),
        .data_rt_exe(data_rt_exe),
        .mem_wen(mem_wen_exe),
        .wb_data_src(wb_data_src_exe),
        .wb_wen(wb_wen_exe),
        .is_load_exe(is_load_exe),
        .fwd_m_exe(fwd_m_exe),
        `ifdef DEBUG
        .mem_data_write_out(mem_data_write),
        .mem_addr_out(mem_addr_out),
        `endif
        .mem_data_read_out(mem_data_read),
        .wb_wen_mem(wb_wen_mem),
        .alu_out_mem(alu_out_mem),
        .wb_data_src_mem(wb_data_src_mem),
        .regw_addr_mem(regw_addr_mem),
        .inst_addr_mem(inst_addr_mem),
        .inst_data_mem(inst_data_mem),
        .is_load_mem(is_load_mem),
        .valid(mem_valid)
    );
    
    WB WB_STAGE(
        .clk(clk),
        .rst(wb_rst),
        .en(wb_en),
        .mem_valid(mem_valid),
        .wb_wen_mem(wb_wen_mem),
        .mem_data_read(mem_data_read),
        .alu_out_mem(alu_out_mem),
        .wb_data_src_mem(wb_data_src_mem),
        .regw_addr_mem(regw_addr_mem),
        .wb_wen_wb(wb_wen_wb),
        .regw_addr_wb(regw_addr_wb),
        .regw_data_wb(regw_data_wb),
        .valid(wb_valid)
    );
	
endmodule
