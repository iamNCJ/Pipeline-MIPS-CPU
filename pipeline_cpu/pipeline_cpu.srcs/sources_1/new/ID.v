`include "define.vh"

module ID(
    input wire clk,
	input wire rst,  // stage reset signal
	input wire en,  // stage enable signal
	input wire if_valid,
	input wire reg_rst,
	input wire [31:0] inst_data,
	input wire [31:0] inst_addr_next,
	input wire wb_wen_wb,
	input wire [4:0] regw_addr_wb,
	input wire [31:0] regw_data_wb,
    input wire [31:0] inst_addr,
	input wire [4:0] regw_addr_exe,  // register write address from EXE stage
	input wire wb_wen_exe,  // register write enable signal feedback from EXE stage
	input wire is_branch_mem,  // whether instruction in MEM stage is jump/branch instruction
	input wire [4:0] regw_addr_mem,  // register write address from MEM stage
	input wire wb_wen_mem,  // register write enable signal feedback from MEM stage
	input wire is_load_exe,
	input wire is_load_mem,
	input wire [31:0] mem_data_out,
    input wire [31:0] alu_out_exe,
    input wire [31:0] alu_out_mem,
    `ifdef DEBUG
    input wire [6:0] debug_addr,
    output wire [31:0] debug_data_reg,
	output wire [4:0] addr_rs_out,
	output wire [4:0] addr_rt_out,
	output wire [4:0] addr_rd_out,
    `endif
    output reg [31:0] inst_addr_out,  // address of instruction needed
	output wire [31:0] inst_data_out,
	output reg [4:0] regw_addr,
	output reg 	[31:0] inst_addr_next_out,
    output reg [31:0] data_rs_fwd,
    output reg [31:0] data_rt_fwd,
    output wire [31:0] data_imm,
    output wire [1:0] pc_src,  // how would PC change to next
    output wire [1:0] exe_a_src,  // data source of operand A for ALU
	output wire [1:0] exe_b_src,  // data source of operand B for ALU
	output wire [3:0] exe_alu_oper,  // ALU operation type
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire wb_data_src,  // data source of data being written back to registers
	output wire wb_wen,  // register write enable signal
	output wire reg_stall,
	output wire [1:0] fwd_a_ctrl,
	output wire [1:0] fwd_b_ctrl,
	output wire is_load_id,
	output reg fwd_m_ctrl,
	output reg valid  // working flag
    );
    
    `include "mips_define.vh"
    
	wire imm_ext;  // whether using sign extended to immediate data
	wire [1:0] wb_addr_src;  // address source to write data back to registers
    wire [4:0] addr_rs, addr_rt, addr_rd;

    reg [31:0] inst_data_id;  // instruction fetched
    reg rs_rt_equal;  // whether data from RS and RT are equal
    assign inst_data_out = inst_data_id;

    `ifdef DEBUG
    assign addr_rs_out = addr_rs, addr_rt_out = addr_rt, addr_rd_out = addr_rd;
    `endif
    
    // ID stage
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			`ifdef DEBUG
			inst_addr_out <= 0;
			`endif
			inst_data_id <= 0;
			inst_addr_next_out <= 0;
		end
		else if (en) begin
			valid <= if_valid;
			`ifdef DEBUG
			inst_addr_out <= inst_addr;
			`endif
			inst_data_id <= inst_data;
			inst_addr_next_out <= inst_addr_next;
		end
	end
	
	assign
		addr_rs = inst_data_id[25:21],
		addr_rt = inst_data_id[20:16],
		addr_rd = inst_data_id[15:11],
		data_imm = imm_ext ? {{16{inst_data_id[15]}}, inst_data_id[15:0]} : {16'b0, inst_data_id[15:0]};
	
	always @(*) begin
		regw_addr = inst_data_id[15:11];
		case (wb_addr_src)
			WB_ADDR_RD: regw_addr = addr_rd;
			WB_ADDR_RT: regw_addr = addr_rt;
			WB_ADDR_LINK: regw_addr = GPR_RA;
		endcase
	end
	
	reg [31:0] data_rs, data_rt;
	
	always @(*) begin
		data_rs_fwd = data_rs;
		data_rt_fwd = data_rt;
		case (fwd_a_ctrl)
			FWD_RS_RT: data_rs_fwd = data_rs;
			FWD_ALU_EXE: data_rs_fwd = alu_out_exe;
			FWD_ALU_MEM: data_rs_fwd = alu_out_mem;
			FWD_MEM_OUT: data_rs_fwd = mem_data_out;
		endcase
		case (fwd_b_ctrl)
			FWD_RS_RT: data_rt_fwd = data_rt;
			FWD_ALU_EXE: data_rt_fwd = alu_out_exe;
			FWD_ALU_MEM: data_rt_fwd = alu_out_mem;
			FWD_MEM_OUT: data_rt_fwd = mem_data_out;
		endcase
		rs_rt_equal = (data_rs_fwd == data_rt_fwd);
	end

	regfile REGFILE (
		.clk(clk),
		.rst(reg_rst),
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
		.inst(inst_data_id),
		.is_load_exe(is_load_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_load_mem(is_load_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src(pc_src),
		.rs_rt_equal(rs_rt_equal),
		.imm_ext(imm_ext),
		.exe_a_src(exe_a_src),
		.exe_b_src(exe_b_src),
		.exe_alu_oper(exe_alu_oper),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.wb_addr_src(wb_addr_src),
		.wb_data_src(wb_data_src),
		.wb_wen(wb_wen),
		.fwd_a(fwd_a_ctrl),
		.fwd_b(fwd_b_ctrl),
		.is_load(is_load_id),
		.reg_stall(reg_stall),
		.fwd_m(fwd_m_ctrl),
		.unrecognized()
	);

endmodule
