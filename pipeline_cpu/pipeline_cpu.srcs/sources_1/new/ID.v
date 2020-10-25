`include "define.vh"

module ID(
    input wire clk,
	input wire rst,  // stage reset signal
	input wire en,  // stage enable signal
	input wire if_valid,
	input wire [31:0] inst_data,
	input wire [31:0] inst_addr_next,
	input wire wb_wen_wb,
	input wire [4:0] regw_addr_wb,
	input wire [31:0] regw_data_wb,
    input wire [31:0] inst_addr,
    `ifdef DEBUG
    input wire [4:0] debug_addr,
    output wire [31:0] debug_data_reg,
	output wire [4:0] addr_rs_out,
	output wire [4:0] addr_rt_out,
	output wire [4:0] addr_rd_out,
    `endif
    output reg [31:0] inst_addr_out,  // address of instruction needed
	output wire [31:0] inst_data_out,
	output reg [4:0] regw_addr,
	output reg 	[31:0] inst_addr_next_out,
    output wire [31:0] data_rs, 
    output wire [31:0] data_rt, 
    output wire [31:0] data_imm,
    output wire [2:0] pc_src,  // how would PC change to next
    output wire [1:0] exe_a_src,  // data source of operand A for ALU
	output wire [1:0] exe_b_src,  // data source of operand B for ALU
	output wire [3:0] exe_alu_oper,  // ALU operation type
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire wb_data_src,  // data source of data being written back to registers
	output wire wb_wen,  // register write enable signal
	output reg valid  // working flag
    );
    
    `include "mips_define.vh"
    
	wire imm_ext;  // whether using sign extended to immediate data
	wire [1:0] wb_addr_src;  // address source to write data back to registers
    wire [4:0] addr_rs, addr_rt, addr_rd;

    reg [31:0] inst_data_id;  // instruction fetched
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
		.inst(inst_data),
//		.is_branch_exe(is_branch_exe),
//		.regw_addr_exe(regw_addr_exe),
//		.wb_wen_exe(wb_wen_exe),
//		.is_branch_mem(is_branch_mem),
//		.regw_addr_mem(regw_addr_mem),
//		.wb_wen_mem(wb_wen_mem),
		.pc_src(pc_src),
		.imm_ext(imm_ext),
		.exe_a_src(exe_a_src),
		.exe_b_src(exe_b_src),
		.exe_alu_oper(exe_alu_oper),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.wb_addr_src(wb_addr_src),
		.wb_data_src(wb_data_src),
		.wb_wen(wb_wen),
		.unrecognized()
	);

endmodule
