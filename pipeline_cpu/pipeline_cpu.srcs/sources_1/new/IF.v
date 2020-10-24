`include "define.vh"

module IF (
    input wire clk,
	input wire rst,  // stage reset signal
	input wire en,  // stage enable signal
	input wire is_branch_mem,  // whether instruction in MEM stage is jump/branch instruction
	input wire [31:0] branch_target_mem,
	`ifdef DEBUG
	output wire [31:0] inst_addr,  // address of instruction needed
	output reg inst_ren,  // instruction read enable signal
	`endif
	output reg valid,  // working flag
	output wire [31:0] inst_addr_next,
	output wire [31:0] inst_data  // instruction fetched
    );
    
    reg [31:0] pc;
	
	inst_rom INST_ROM (
		.clk(clk),
		.addr({2'b0, pc[31:2]}),
		.dout(inst_data)
		);
	
	`ifdef debug
	assign inst_addr = pc;
	`endif
	assign inst_addr_next = pc + 4;
	
	always @(*) begin
		valid = ~rst & en;
		`ifdef DEBUG
		inst_ren = ~rst;
		`endif
	end
	
	always @(posedge clk) begin
		if (rst) begin
			pc <= 0;
		end
		else if (en) begin
			if (is_branch_mem)
				pc <= branch_target_mem;
			else
				pc <= inst_addr_next;
		end
	end
		
endmodule
