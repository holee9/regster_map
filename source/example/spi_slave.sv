//`include	"./p_define.sv"
`timescale 1ns / 1ps

module spi_slave
		#(
			parameter int header 	= 2,		// size of header , wr:rd 2bit
			parameter int payload 	= 8,       	// size of payload or data size
			parameter int addrsz 	= 7,        // size of SPI Address Space
			parameter int pktsz    	= header + addrsz + payload		// size of SPI packet
		)
		(
            input logic clk,                		// system clock
		    input logic reset,              		// system reset
		  	// SPI I/O
			input logic SCLK,
			input logic SSB,
			input logic MOSI,
			output logic MISO,
		
			output logic spi_start_flag,

			input  logic [payload-1:0] read_data, 		// data to transmit to the master on MISO
			input  logic read_en,				    	// read enable, when

			output logic [addrsz-1:0] reg_addr,  		// address to slave from master on MOSI
			output logic addr_valid,					// address valid
			output logic [payload-1:0] wr_data, 	    // data rx from master on MOSI
			output logic wr_data_valid,           		    // rx data valid
			output logic rw_out			            /* read/write out (1st bit of transaction): 
														0 == send data from master to the slave
										               	1 == request data from slave */
		);
		

	// synchronization , delay
	logic [2:0] dly_sclk;
	logic [2:0] dly_ss;
	// logic [1:0] dly_mosi;
	logic [10:0] dly_mosi;
	logic [3:0] dly_read_en;
	// count of bits in SPI transaction
	logic [$clog2(pktsz):0] bitcnt;
	// readwrite bit
	logic flag_rd;
	logic flag_wr;

	logic s_mosi;
	logic s_sclk;
	logic s_ssb;

	logic [addrsz-1:0] s_reg_addr;

	logic s_addr_valid;
	logic [5:0] dly_addr_valid;

	assign s_mosi = MOSI;
	assign s_sclk = SCLK;

    assign s_ssb = SSB;

	always_ff @ (posedge clk or posedge reset)
		begin
			if (reset)
				begin
					dly_sclk 	<= 3'b000;
					dly_ss   	<= 3'b111;
					// dly_mosi 	<= 2'b00;
					dly_mosi 	<= 0;
					dly_read_en 	<= 4'b0000;
					dly_addr_valid <= 0;
				end
			else
				begin
					dly_sclk 	<= {dly_sclk[1:0], s_sclk};
					dly_ss   	<= {dly_ss[1:0], s_ssb};
					dly_mosi 	<= {dly_mosi[9:0], s_mosi};
					dly_read_en 	<= {dly_read_en[2:0], read_en};
					dly_addr_valid <= {dly_addr_valid[4:0], s_addr_valid};
				end
		end

	`define RISING_EDGE
	// `define FALLING_EDGE

	logic sclk_edge;
	logic sclk_rising_edge;
	logic sclk_falling_edge;
	logic spi_start;
	logic spi_end;
	logic spi_active;
	logic read_en_rising_edge;
	logic mosi_d;
	logic miso_d;
	logic [payload-1:0] s_miso;

	assign sclk_falling_edge = (dly_sclk[2:0]== 3'b110) ? 1'b1 : 1'b0;	// falling edge of sclk
	// assign sclk_rising_edge = (dly_sclk[2:0]== 3'b011) ? 1'b1 : 1'b0;	// rising edge of sclk
	assign sclk_rising_edge = (dly_sclk[2:0]== 3'b001) ? 1'b1 : 1'b0;	// rising edge of sclk

	`ifdef RISING_EDGE
		assign sclk_edge = sclk_falling_edge;
	`endif

	`ifdef FALLING_EDGE
		assign sclk_edge = sclk_rising_edge;
	`endif

	
	assign spi_start = (dly_ss[2:0]== 3'b100) ? 1'b1 : 1'b0;         // ss -- active low
	assign spi_end   = (dly_ss[2:0]== 3'b001) ? 1'b1 : 1'b0;       	// transaction ends
	assign spi_active = ~dly_ss[1];

	assign read_en_rising_edge = (dly_addr_valid== 6'b001111) ? 1'b1 : 1'b0;			// read_en rising edge

	assign mosi_d = dly_mosi[9];

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			bitcnt <= 0;
		else if (spi_start)
			bitcnt <= 0;
		// else if (spi_active && sclk_edge)
		else if (spi_active && sclk_falling_edge)
			bitcnt <= bitcnt + 1;
	end

	// Capture 1st bit from host.  If flag_wr==1, a write from host to slave.
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			flag_wr <= 1'b0;
		else if (spi_start || spi_end)
			flag_wr <= 1'b0;
		else if (spi_active && sclk_edge && bitcnt == 2'b00)
			flag_wr <= mosi_d;
			// if (mosi_d == 1'b1)
			// 	flag_wr <= 1'b1;
	end

	// // Capture 1st bit from host.  If flag_wr==1, a write from host to slave.
	// always_ff @(posedge clk, posedge reset)
	// begin
	// 	if (reset)
	// 		flag_rd <= 1'b0;
	// 	else if (spi_start || spi_end)
	// 		flag_rd <= 1'b0;
	// 	else if (spi_active && sclk_edge && bitcnt == 2'b00)
	// 		if (mosi_d == 1'b0)
	// 			flag_rd <= 1'b1;
	// end

	// Capture 1st bit from host.  If flag_rd==1, a write from slave to host.
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			flag_rd <= 1'b0;
		else if (spi_start || spi_end)
			flag_rd <= 1'b0;
		else if (spi_active && sclk_edge && bitcnt == 2'b01)
			flag_rd <= mosi_d;
	end

	// capture next addrsz bits for register address
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset )
			s_reg_addr <= 0;
		else if (spi_start)
			s_reg_addr <= 0;
			// reg_addr <= {reg_addr[addrsz-2:0], mosi_d };
		else if (spi_active && sclk_rising_edge && bitcnt > 1 && bitcnt < (header+addrsz))
			s_reg_addr <= {s_reg_addr[addrsz-2:0], mosi_d };
	end

	assign reg_addr = (s_addr_valid==1'b1) ? s_reg_addr : 0;

	// capture next payload bits for register data
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			wr_data <= 0;
		else if (spi_start)
			wr_data <= 0;
		else if (spi_active && sclk_edge && bitcnt > payload - 1 && flag_wr)
			wr_data <= {wr_data[payload-2:0], mosi_d};
	end

	// next payload bits to host data
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			begin
				s_miso <= 0;
			end
		else if (read_en_rising_edge)
			begin
				s_miso <= read_data;
			end
		else if (spi_active && sclk_edge && bitcnt > (header+addrsz)-1 && dly_read_en[2])
			begin
				s_miso <= {s_miso[payload-2:0], 1'b0};
			end
		else if (dly_read_en== 3'b000)
				s_miso <= 0;
	end


	// assign MISO = (bitcnt > (header+addrsz)-1  && flag_rd) ? s_miso[payload-1] : 1'b0;
	assign miso_d = (bitcnt > (header+addrsz)-1  && flag_rd) ? s_miso[payload-1] : 1'b0;
	assign MISO = miso_d;

	// address data valid
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset )
			s_addr_valid <= 1'b0;
		else if (spi_start || spi_end)
			s_addr_valid <= 1'b0;
		else if ((bitcnt >= (header+addrsz) - 1) && sclk_rising_edge)
			s_addr_valid <= 1'b1;
	end
	assign addr_valid = s_addr_valid;

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset )
			wr_data_valid <= 1'b0;
		else if (spi_start || spi_end)
			wr_data_valid <= 1'b0;
		else if (bitcnt == pktsz -1 && sclk_edge && flag_wr)
			wr_data_valid <= 1'b1;
	end

	assign txdv = (bitcnt == pktsz -1 && flag_rd == 1) ? 1'b1 : 1'b0;

assign rw_out = (flag_rd) ? 1'b1 : 1'b0;
assign spi_start_flag = spi_start;

logic [15:0]	ila_addr;
assign ila_addr = ({spi_start,spi_end,reg_addr});

endmodule
