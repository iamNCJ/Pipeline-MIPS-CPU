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
		
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	wire inst_ren;
	wire [31:0] inst_addr;

	
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
	
	IF IF_PART(
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
	   
    ID ID_PART(
    );
    
    EXE EXE_PART();
    
    MEM MEM_PART();
    
    WB WB_PART();
	
endmodule
