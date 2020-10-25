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
	
	wire [31:0] inst_data;
	
	reg [4:0] regw_addr;
    wire [31:0] inst_addr_next, inst_addr_next_id, inst_addr_next_exe;
    wire [31:0] data_rs, data_rt, data_imm;
    wire [2:0] pc_src;  // how would PC change to next
    wire [1:0] exe_a_src;  // data source of operand A for ALU
    wire [1:0] exe_b_src;  // data source of operand B for ALU
    wire [3:0] exe_alu_oper;  // ALU operation type
    wire mem_ren;  // memory read enable signal
    wire mem_wen;  // memory write enable signal
    wire wb_data_src;  // data source of data being written back to registers
    wire wb_wen;  // register write enable signal
		
	// debugger
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	wire inst_ren; // instruction read enable signal
	wire [31:0] inst_addr;
	wire [31:0] inst_data_id;
	wire [31:0] inst_addr_id;
	wire [4:0] addr_rs, addr_rt, addr_rd;
	wire [31:0] inst_data_exe, inst_addr_exe;

	
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
			17: debug_data_signal <= 0;
			18: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
			19: debug_data_signal <= mem_addr;
			20: debug_data_signal <= mem_din;
			21: debug_data_signal <= mem_dout;
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
	reg if_rst, id_rst, exe_rst, mem_rst, wb_rst;  // stage reset signal
	reg if_en, id_en, exe_en, mem_en, wb_en;  // stage enable signal
	wire if_valid, id_valid, exe_valid, mem_valid, wb_valid;  // stage valid flag
	
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
		if (rst) begin
			if_rst = 1;
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			wb_rst = 1;
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
		// this stall indicate that ID is waiting for previous instruction, should insert NOPs between ID and EXE.
//		else if (reg_stall) begin
//			if_en = 0;
//			id_en = 0;
//			exe_rst = 1;
//		end
//		// this stall indicate that a jump/branch instruction is running, so that 3 NOP should be inserted between IF and ID
//		else if (branch_stall) begin
//			id_rst = 1;
//		end
	end
	
	IF IF_STAGE (
	   .clk(clk),
	   .rst(if_rst),
	   .en(if_en),
	   .is_branch_mem(is_branch_mem),
	   .branch_target_mem(branch_target_mem),
	   `ifdef DEBUG
	   .inst_addr(inst_addr),
	   .inst_ren(inst_ren),
	   `endif
	   .valid(if_valid),
	   .inst_addr_next(inst_addr_next),
	   .inst_data(inst_data)
	   );
	   
    ID ID_STAGE (
        .clk(clk),
        .rst(id_rst),
        .en(id_en),
        .if_valid(if_valid),
        .inst_data(inst_data),
        .inst_addr_next(inst_addr_next),
        .wb_wen_wb(wb_wen_wb), // FIXME
        .regw_addr_wb(regw_addr_wb), // FIXME
        .regw_data_wb(regw_data_wb), // FIXME
        `ifdef DEBUG
        .inst_addr(inst_addr),
        .debug_addr(debug_addr),
        .debug_data_reg(debug_data_reg),
        .inst_addr_out(inst_addr_id),
        .inst_data_out(inst_data_id),
        .addr_rs_out(addr_rs),
        .addr_rt_out(addr_rt),
        .addr_rd_out(addr_rd),
        `endif
        .regw_addr(regw_addr),
        .inst_addr_next_out(inst_addr_next_id),
        .data_rs(data_rs),
        .data_rt(data_rt),
        .data_imm(data_imm),
        .pc_src(pc_src),  // how would PC change to next
        .exe_a_src(exe_a_src),  // data source of operand A for ALU
        .exe_b_src(exe_b_src),  // data source of operand B for ALU
        .exe_alu_oper(exe_alu_oper),  // ALU operation type
        .mem_ren(mem_ren),  // memory read enable signal
        .mem_wen(mem_wen),  // memory write enable signal
        .wb_data_src(wb_data_src),  // data source of data being written back to registers
        .wb_wen(wb_wen),  // register write enable signal
        .valid(id_valid)  // working flag
    );
    
    EXE EXE_STAGE (
        .clk(clk),
        .en(exe_en),
        .rst(exe_rst),
        .id_valid(id_valid),
        .inst_addr_next(inst_addr_next_id),
        `ifdef DEBUG
        .inst_data(inst_data_id),
        .inst_addr(inst_addr_id),
        .inst_addr_out(inst_data_exe),
        .inst_data_out(inst_data_exe),
        `endif
        .inst_addr_next_out(inst_addr_next_exe),
        .valid(exe_valid)
    );
    
    MEM MEM_STAGE ();
    
    WB WB_STAGE();
	
endmodule
