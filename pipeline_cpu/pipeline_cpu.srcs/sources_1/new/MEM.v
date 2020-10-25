`include "define.vh"

module MEM(
    input wire clk,
    input wire rst,
    input wire en,
    input wire exe_valid,
    input wire [2:0] pc_src,
    input wire [31:0] inst_addr,
    input wire [31:0] inst_data,
    input wire [31:0] inst_addr_next,
    input wire [4:0] regw_addr,
    input wire [31:0] data_rs,
    input wire [31:0] data_rt,
    input wire [31:0] alu_out,
    input wire [31:0] mem_ren, // memory read enable signal // seems useless
    input wire [31:0] mem_wen, // memory write enable signal
    input wire wb_data_src,
    input wire wb_wen,
    input wire rs_rt_equal,
    `ifdef DEBUG
    output wire [31:0] mem_data_write_out,
    output wire [31:0] mem_addr_out,
    `endif
    output reg is_branch_mem,
    output reg [31:0] branch_target_mem,
    output wire [31:0] mem_data_read_out,  // data read from memory
    output reg valid
    );
    
    `include "mips_define.vh"
    
	wire [31:0] mem_addr;  // address of memory
	wire [31:0] mem_data_to_write;  // data writing to memory
	
	`ifdef DEBUG
	assign
	   mem_data_write_out = mem_data_to_write,
	   mem_addr_out = mem_addr;
	`endif

	reg [2:0] pc_src_mem;
	reg [31:0] inst_addr_mem;
	reg [31:0] inst_data_mem;
	reg [31:0] inst_addr_next_mem;
	reg [4:0] regw_addr_mem;
	reg [31:0] data_rs_mem;
	reg [31:0] data_rt_mem;
	reg [31:0] alu_out_mem;
	reg [31:0] mem_ren_mem;
	reg [31:0] mem_wen_mem;
	reg wb_data_src_mem;
	reg wb_wen_mem;
	reg rs_rt_equal_mem;
	
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
			pc_src_mem <= 0;
			inst_addr_mem <= 0;
			inst_data_mem <= 0;
			inst_addr_next_mem <= 0;
			regw_addr_mem <= 0;
			data_rs_mem <= 0;
			data_rt_mem <= 0;
			alu_out_mem <= 0;
			mem_ren_mem <= 0;
			mem_wen_mem <= 0;
			wb_data_src_mem <= 0;
			wb_wen_mem <= 0;
			rs_rt_equal_mem <= 0;
		end
		else if (en) begin
			valid <= exe_valid;
			pc_src_mem <= pc_src;
			inst_addr_mem <= inst_addr;
			inst_data_mem <= inst_data;
			inst_addr_next_mem <= inst_addr_next;
			regw_addr_mem <= regw_addr;
			data_rs_mem <= data_rs;
			data_rt_mem <= data_rt;
			alu_out_mem <= alu_out;
			mem_ren_mem <= mem_ren;
			mem_wen_mem <= mem_wen;
			wb_data_src_mem <= wb_data_src;
			wb_wen_mem <= wb_wen;
			rs_rt_equal_mem <= rs_rt_equal;
		end
	end
	
	always @(*) begin
		is_branch_mem <= (pc_src_mem != PC_NEXT);
	end
	
	always @(*) begin
		case (pc_src_mem)
			PC_JUMP: branch_target_mem <= {inst_addr_mem[31:28], inst_data_mem[25:0], 2'b0};
			PC_JR: branch_target_mem <= data_rs_mem;
			PC_BEQ: branch_target_mem <= rs_rt_equal_mem ? alu_out_mem : inst_addr_next_mem;
			PC_BNE: branch_target_mem <= rs_rt_equal_mem ? inst_addr_next_mem : alu_out_mem;
			default: branch_target_mem <= inst_addr_next_mem;  // will never used
		endcase
	end
	
	assign
		mem_ren = mem_ren_mem,
		mem_wen = mem_wen_mem,
		mem_addr = alu_out_mem,
		mem_data_to_write = data_rt_mem;

endmodule
