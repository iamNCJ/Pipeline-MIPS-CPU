`include "define.vh"

module MEM(
    input wire clk,
    input wire rst,
    input wire en,
    input wire exe_valid,
    input wire [31:0] inst_addr,
    input wire [31:0] inst_data,
    input wire [31:0] inst_addr_next,
    input wire [4:0] regw_addr,
    input wire [31:0] data_rs,
    input wire [31:0] data_rt,
    input wire [31:0] alu_out,
    input wire [31:0] data_rt_exe,
    input wire mem_ren, // memory read enable signal // seems useless
    input wire mem_wen, // memory write enable signal
    input wire wb_data_src,
    input wire wb_wen,
    input wire rs_rt_equal,
    input wire is_load_exe,
    input wire fwd_m_exe,  // forwarding selection for memory
    `ifdef DEBUG
    output wire [31:0] mem_data_write_out,
    output wire [31:0] mem_addr_out,
    `endif
    output reg is_branch_mem,
    output reg [31:0] branch_target_mem,
    output wire [31:0] mem_data_read_out,  // data read from memory
	output reg wb_wen_mem,
	output reg [31:0] alu_out_mem,
	output reg wb_data_src_mem,
	output reg [4:0] regw_addr_mem,
	output reg [31:0] inst_addr_mem,
	output reg [31:0] inst_data_mem,
	output reg [31:0] regw_data_wb,
	output reg is_load_mem,  // whether instruction in MEM stage is load instruction
    output reg valid
    );
    
    `include "mips_define.vh"
    
	wire [31:0] mem_addr;  // address of memory
	wire [31:0] mem_data_to_write;  // data writing to memory

	reg [31:0] inst_addr_next_mem;
	reg [31:0] data_rs_mem;
	reg [31:0] data_rt_mem;
	reg rs_rt_equal_mem;
	reg fwd_m_mem;
	
	`ifdef DEBUG
	assign
	   mem_data_write_out = mem_data_to_write,
	   mem_addr_out = mem_addr;
	`endif

	data_ram DATA_RAM (
		.clk(clk),
		.we(mem_wen),
		.addr({2'b0, mem_addr[31:2]}),
		.din(mem_data_to_write),
		.dout(mem_data_read_out)
		);
    
    // MEM stage
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			inst_addr_mem <= 0;
			inst_data_mem <= 0;
			inst_addr_next_mem <= 0;
			regw_addr_mem <= 0;
			data_rt_mem <= 0;
			alu_out_mem <= 0;
			wb_data_src_mem <= 0;
			wb_wen_mem <= 0;
			fwd_m_mem <= 0;
			is_load_mem <= 0;
			rs_rt_equal_mem <= 0;
		end
		else if (en) begin
			valid <= exe_valid;
			inst_addr_mem <= inst_addr;
			inst_data_mem <= inst_data;
			regw_addr_mem <= regw_addr;
			data_rt_mem <= data_rt_exe;
			alu_out_mem <= alu_out;
			wb_data_src_mem <= wb_data_src;
			wb_wen_mem <= wb_wen;
			fwd_m_mem <= fwd_m_exe;
			is_load_mem <= is_load_exe;
			rs_rt_equal_mem <= rs_rt_equal;
		end
	end

	assign
		mem_addr = alu_out_mem,
		mem_data_to_write = fwd_m_mem ? regw_data_wb : data_rt_mem;

endmodule
