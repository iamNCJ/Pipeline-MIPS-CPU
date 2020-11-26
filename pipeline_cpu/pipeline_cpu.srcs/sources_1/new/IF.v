`include "define.vh"

module IF (
    input wire clk,
	input wire rst,  // stage reset signal
	input wire en,  // stage enable signal
	input wire [1:0] pc_src_ctrl,  // how would PC change to next
	input wire [31:0] inst_addr_id,
	input wire [31:0] inst_data_id,
	input wire [31:0] data_rs_fwd,
	input wire [31:0] inst_addr_next_id,
	input wire [31:0] data_imm,
	`ifdef DEBUG
	output reg inst_ren,  // instruction read enable signal
	`endif
	output reg [31:0] pc,  // address of instruction needed
	output reg valid,  // working flag
	output wire [31:0] inst_addr_next,
	output wire [31:0] inst_data  // instruction fetched
    );
    
    `include "mips_define.vh"
	
	inst_rom INST_ROM (
		.clk(clk),
		.addr({2'b0, pc[31:2]}),
		.dout(inst_data)
		);
	
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
			case (pc_src_ctrl)
				PC_NEXT: pc <= inst_addr_next;
				PC_JUMP: pc <= {inst_addr_id[31:28], inst_data_id[25:0], 2'b0};
				PC_JR: pc <= data_rs_fwd;
				PC_BRANCH: pc <= inst_addr_next_id + {data_imm[29:0], 2'b0};
			endcase
		end
	end
		
endmodule
