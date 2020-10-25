`include "define.vh"

module WB(
    input wire clk,
    input wire rst,
    input wire en,
    input wire mem_valid,
    input wire wb_wen_mem,
    input wire [31:0] mem_data_read,
    input wire [31:0] alu_out_mem,
    input wire wb_data_src_mem,
    input wire [4:0] regw_addr_mem,
    output reg wb_wen_wb,
    output reg [4:0] regw_addr_wb,
    output reg [31:0] regw_data_wb,
    output reg valid
    );
    
    `include "mips_define.vh"
    
    reg wb_data_src_wb;
    reg [31:0] alu_out_wb, mem_din_wb;
    
    // WB stage
	always @(posedge clk) begin
		if (rst) begin
			valid <= 0;
			wb_wen_wb <= 0;
			wb_data_src_wb <= 0;
			regw_addr_wb <= 0;
			alu_out_wb <= 0;
			mem_din_wb <= 0;
		end
		else if (en) begin
			valid <= mem_valid;
			wb_wen_wb <= wb_wen_mem;
			wb_data_src_wb <= wb_data_src_mem;
			regw_addr_wb <= regw_addr_mem;
			alu_out_wb <= alu_out_mem;
			mem_din_wb <= mem_data_read;
		end
	end
	
	always @(*) begin
		regw_data_wb = alu_out_wb;
		case (wb_data_src_wb)
			WB_DATA_ALU: regw_data_wb = alu_out_wb;
			WB_DATA_MEM: regw_data_wb = mem_din_wb;
		endcase
	end
	
endmodule
