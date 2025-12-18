module spi_master
		#(
			parameter int header 	= 2,		// size of header , wr:rd 2bit
			parameter int payload 	= 8,       	// size of payload or data size
			parameter int addrsz 	= 7,        // size of SPI Address Space
			parameter int pktsz    	= header + addrsz + payload		// size of SPI packet
		)
		(
			input logic 					clk, reset,
			input logic 					start,
			input logic [1:0] 			slaveselect,
			input logic [header-1:0] 	masterHeader,
			input logic [addrsz-1:0]  	masterAddrToSend,
			input logic [payload-1:0]  	masterDataToSend,
			output [payload-1:0] 		masterDataReceived,
			
			output 	logic 			SCLK,
			output  [2:0]			CS,
			output 	logic 			MOSI,
			input 	logic 			MISO
		);

localparam int				divide = 10;

integer counter;
//integer flag;
logic [pktsz-1:0] 			MDS;
logic [payload-1:0] 		MDR;

logic [pktsz-1:0] 			MDS_next;
logic [payload-1:0] 		MDR_next;
logic [15:0]					dly_start;
logic [2:0]					s_cs;
logic 						spi_active;
logic [15:0]					dly_spi_active;

logic [7:0]					cnt_clk;
logic [7:0]					mod_cnt_clk;
logic 						cnt_clk_rst;

logic 						s_sclk;

// always @(posedge s_sclk , posedge reset)
always @(negedge s_sclk , posedge reset)
	begin
		if (reset == 1'b1)
			begin
				MDS = 0;
				// MDR = 0;
				counter = 0;
			end
		else if (start == 1'b1)
			begin
				MDS = ({masterHeader,masterAddrToSend,masterDataToSend});
				// MDR = 0;
				MOSI = 1'b1;
				counter = 0;
			end
		// else
		else if (spi_active == 1'b1)
			begin
				MDS = MDS_next;
				// MDR = MDR_next;
				counter = counter + 1;
				MOSI = MDS[pktsz-1];
			end
	end

always @(negedge s_sclk , posedge reset)
	begin
		if (reset == 1'b1)
			begin
				MDR = 0;
			end
		// else if (start == 1'b1)
		// 	begin
		// 		MDR = 0;
		// 	end
		else if (dly_spi_active[9] == 1'b1)
			begin
				MDR = MDR_next;
			end
	end

// always @(posedge s_sclk , posedge reset)
always @(negedge s_sclk , posedge reset)
		begin
			if (reset==1'b1)
				begin
					dly_start = 0;
				end
			else
				begin
					dly_start = {dly_start[14:0],start};
				end
		end

	always @(posedge clk, posedge reset)
		begin
			if (reset==1'b1)
				begin
					cnt_clk = 0;
					dly_spi_active = 0;
				end
			else if (cnt_clk_rst==1'b1)
				cnt_clk = 0;
			else
				begin
					cnt_clk = cnt_clk + 1;
					dly_spi_active = {dly_spi_active[14:0],spi_active};
				end
		end

	assign mod_cnt_clk = (cnt_clk % (divide/2));
	assign cnt_clk_rst = (cnt_clk >= (divide-1)) ? 1'b1 : 1'b0;

	always @(posedge clk, posedge reset)
		begin
			if (reset==1'b1)
				s_sclk = 1'b0;
			else if (mod_cnt_clk==0)
				s_sclk = ~s_sclk;
		end

	assign MDS_next = (dly_start[1]== 1'b0 && spi_active == 1'b1 && counter < pktsz) ? { MDS[pktsz-2:0],1'b0 } : MDS;
	// assign MDR_next = (dly_start[1]== 1'b0 && spi_active == 1'b1 && counter > (pktsz-payload)) ? {MDR[payload-2:0],MISO} : MDR;
	assign MDR_next = (dly_start[1]== 1'b0 && dly_spi_active[9] == 1'b1 && counter > (pktsz-payload)) ? {MDR[payload-2:0],MISO} : MDR;

	assign masterDataReceived = MDR;
	assign s_cs = (slaveselect == 2'b00) ? 3'b110 :
					(slaveselect == 2'b01) ? 3'b101 : 3'b011;

	assign spi_active = (dly_start > 16'h0001) ? 1'b1 :
						(counter > 0 && counter < pktsz) ? 1'b1 : 1'b0;

	// assign SCLK = (dly_spi_active[4] == 1'b1) ? s_sclk : 1'b0;
	assign SCLK = (dly_spi_active[9] == 1'b1) ? s_sclk : 1'b0;
	// assign CS = (dly_spi_active[4] == 1'b1 || dly_spi_active[9] == 1'b1 ) ? s_cs : 3'b111;
	assign CS = (dly_spi_active[0] == 1'b1 || dly_spi_active[14] == 1'b1 ) ? s_cs : 3'b111;

endmodule
