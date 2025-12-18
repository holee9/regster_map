// ---------------------------------------------------------------------------------
//   Title      :  Test Bench Module
//              :  
//   Purpose    :  Writing the synthesisable verilog RTL code for
//              :  the Test bench
//              :
//   Designer   :  Kihyun Kim  (kkh@abyzr.com)
//              :
//   Company    :  H&abyz Inc.
//              :
//
// ---------------------------------------------------------------------------------
//   Modification history : 
//
//   version:   |   mod. date:  |   changes made:
//      v1.0        03/18/2022      initial release
//
// ---------------------------------------------------------------------------------
//  Descripitions   :
//
//
//
//
// ---------------------------------------------------------------------------------
`include	"../../source/hdl/p_define.sv"
`timescale 1ns/1ps

module test_bench();

	parameter mipi_lane = 4;

	wire			nRST					;
	reg				MCLK_100M_p				;
	reg				MCLK_100M_n				;
	reg				MCLK_50M_p				;
	reg				MCLK_50M_n				;
	wire			mipi_phy_if_clk_hs_p	;
	wire			mipi_phy_if_clk_hs_n	;
	wire			mipi_phy_if_clk_lp_p	;
	wire			mipi_phy_if_clk_lp_n	;
	wire	[mipi_lane-1:0]	mipi_phy_if_data_hs_p	;
	wire	[mipi_lane-1:0]	mipi_phy_if_data_hs_n	;
	wire	[mipi_lane-1:0]	mipi_phy_if_data_lp_p	;
	wire	[mipi_lane-1:0]	mipi_phy_if_data_lp_n	;
	wire			SCLK					;
	wire			SSB						;
	wire			MOSI					;
	wire			MISO					;
	wire			ROIC_RESET_R 			;
	wire			ROIC_SYNC_R  			;
	wire			ROIC_ACLK_R  			;
	wire			DCLK_R        			;
	logic			AED_TRIG				;
	wire	[11:0]	R_ROIC_DCLKo_p			;
	wire	[11:0]	R_ROIC_DCLKo_n			;
	wire	[11:0]	R_DOUTA_H				;
	wire	[11:0]	R_DOUTA_L				;
	wire	[11:0]	R_DOUTB_H				;
	wire	[11:0]	R_DOUTB_L				;
	wire			GF_STV_L   				;
	wire			GF_STV_LR2 				;
	wire			GF_STV_LR3 				;
	wire			GF_STV_LR4 				;
	wire			GF_STV_LR5 				;
	wire			GF_STV_LR6 				;
	wire			GF_STV_LR7 				;
	wire			GF_STV_LR8 				;
	wire			GF_STV_R   				;
	wire			GF_CPV    				;
	wire			GF_OE	   				;
	wire			GF_LR1					;
	wire			GF_LR2					;
	wire			GF_CS1					;
	wire			GF_CS2					;
	wire			GF_XAO_1				;
	wire			GF_XAO_2				;
	wire			GF_XAO_3				;
	wire			GF_XAO_4				;
	wire			GF_XAO_5				;
	wire			GF_XAO_6				;
	wire			GF_XAO_7				;
	wire			GF_XAO_8				;
	reg				eim_clk_in  			;
	wire			R_SW_BIAS   			;
	wire			L_SW_BIAS   			;
	wire			RF_SPI_CS_1 			;
	wire			RF_SPI_CS_2 			;
	wire			RF_SPI_SCK_1			;
	wire			RF_SPI_SDI_1			;
	wire			RF_SPI_SDO_1			;
	wire			RF_SPI_SCK_2			;
	wire			RF_SPI_SDI_2			;
	wire			RF_SPI_SDO_2			;
	wire			pwr_bbv     			;
	wire			R_SW_AVDDI				;
	wire			L_SW_AVDDI				;
	logic			prep_req         	; //= 1'b0	;
	logic			exp_req          	; //= 1'b0	;
	logic			prep_ack         		;
	logic			exp_ack          		;
	wire			cancel_req       		;
	wire			led_0            		;
	wire			led_1            		;
	wire			led_2            		;
	wire			led_3            		;
	wire			led_4            		;
	wire			led_5            		;
	wire			led_6            		;
	wire			led_7            		;

	reg					osc_clk					;

	reg					roic_data_clk			;

	// spi master task
	localparam header   = 2;		// size of header , wr:rd 2bit
	localparam payload  = 16;       // size of payload or data size
	localparam addrsz   = 14;		// size of SPI Address Space
	localparam pktsz    = header + addrsz + payload;		// size of SPI packet

		
	logic 					m_start = 1'b0;
	logic [1:0] 			slaveselect = 2'b00;
	logic [header-1:0] 		masterHeader;
	logic [addrsz-1:0]  	masterAddrToSend;
	logic [payload-1:0]  	masterDataToSend;
	logic [payload-1:0] 	masterDataReceived;

	logic		reset;
	logic 		m_sclk_in;

	logic [0:0] 	TI_FCLK_p;
	logic [0:0] 	TI_FCLK_n;
	logic [0:0] 	TI_DCLK_p;
	logic [0:0] 	TI_DCLK_n;
	logic [0:0] 	TI_DOUT_p;
	logic [0:0] 	TI_DOUT_n;

	localparam int WORD_SIZE     = 24;     // 24-bit data word width
	logic [WORD_SIZE-1:0] adc_data;
	logic adc_data_valid;
	logic mclk;

    logic [51:0]            lut_wr_data;

    // FSM State Definitions
    localparam logic [3:0] RST          = 4'd0;     // Reset state
    localparam logic [3:0] WAIT = 4'd1;     // Panel stable state
    localparam logic [3:0] BACK_BIAS    = 4'd2;     // Back bias state
    localparam logic [3:0] FLUSH        = 4'd3;     // Flush state
    localparam logic [3:0] AED_DETECT   = 4'd4;     // AED detect state
    localparam logic [3:0] EXPOSE_TIME  = 4'd5;     // Expose time state
    localparam logic [3:0] READOUT      = 4'd6;     // Readout state
    localparam logic [3:0] IDLE         = 4'd7;     // Idle state


	parameter	real	sclk_period				= (10**3)/5;	// time unit : ns
	parameter	real	clk_50M_period			= (10**3)/50;	// time unit : ns
	parameter	real	clk_100M_period			= (10**3)/100;	// time unit : ns
	parameter	real	osc_clk_period			= (10**3)/33;	// time unit : ns
	parameter	real	roic_data_clk_period	= (10**3)/100;	// time unit : ns
	parameter	real	eim_clk_period			= (10**3)/66;	// time unit : ns
	parameter	real	m_clk_period			= (10**3)/20;	// time unit : ns

	// clock signal intialization
	initial begin
		MCLK_50M_p 		= 1'b1;
		MCLK_100M_p 		= 1'b1;
		m_sclk_in 		= 1'b1;
		osc_clk 		= 1'b1;
		eim_clk_in 		= 1'b1;
		#4 roic_data_clk 	= 1'b1;
		mclk 				= 1'b1;
	end

	// clock generation
	always #(sclk_period/2)				m_sclk_in = ~m_sclk_in;
	always #(clk_50M_period/2)			MCLK_50M_p = ~MCLK_50M_p;
	always #(clk_100M_period/2)			MCLK_100M_p = ~MCLK_100M_p;
	always #(osc_clk_period/2)			osc_clk = ~osc_clk;
	always #(roic_data_clk_period/2)	roic_data_clk = ~roic_data_clk;
	always #(eim_clk_period/2)			eim_clk_in = ~eim_clk_in;
	always #(m_clk_period/2)				mclk = ~mclk;

	assign MCLK_50M_n = ~MCLK_50M_p;
	assign MCLK_100M_n = ~MCLK_100M_p;

	assign nRST = ~reset;

	// Reset
	initial begin
		// @(posedge test_bench.uut.rst);
		@(negedge test_bench.cyan_uut.nRST);
		// @(negedge nRST);
		$display("-R- %0t =>", $realtime); // dispaly * 0.001 = ns
		$display("[SYS] : System Reset de-asserted!");
		$display("\n");
	end

	//
	initial begin
		rst();
		get_aed_trig();
		
		wait(test_bench.cyan_uut.eim_rst);
		#100;

		$display("[SYS] : Wait osc clock!");
		@(posedge osc_clk);
		$display("[SYS] : OK osc clock!");

		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);
		@(posedge osc_clk);

	#1000000
		$display("[SYS] : Wait 1 sec for system stable!");
		$display("[SYS] : System stable, start test!");
		$display("\n");

	$display($time, " << spi_write >>");
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_01);

	#400
	$display($time, " << spi_read >>");
	do_mspi_read(2'b01, `ADDR_SYS_CMD_REG);

	#5000;
	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);
	#100;
	do_mspi_write(2'b10 , `ADDR_SET_GATE, 16'h00_03);
	#100;
	do_mspi_write(2'b10 , `ADDR_GATE_SIZE, 16'h00_04);
	#100;
	do_mspi_write(2'b10 , `ADDR_BACK_BIAS_SIZE, 16'h00_64);
	#100;
	do_mspi_write(2'b10 , `ADDR_EXPOSE_SIZE, 16'd20); // test pattern , bit4: row bit3: col
	$display($time, " << expose size 20 >>");


	// 10 line
	do_mspi_write(2'b10 , `ADDR_IMAGE_HEIGHT, 16'd5);
	// 1536 line
	// do_mspi_write(2'b10 , `ADDR_IMAGE_HEIGHT, 16'h06_00);
	#100;
	do_mspi_write(2'b10 , `ADDR_MAX_V_COUNT, 16'd30);
	// do_mspi_write(2'b10 , `ADDR_MAX_V_COUNT, 16'd1024);
	#100;
	do_mspi_write(2'b10 , `ADDR_MAX_H_COUNT, 16'd256);
	#100;
	do_mspi_write(2'b10 , `ADDR_READOUT_COUNT, 16'd0);
	#100;
	// do_mspi_write(2'b10 , `ADDR_CSI2_WORD_COUNT, 16'd2048);
	do_mspi_write(2'b10 , `ADDR_CSI2_WORD_COUNT, 16'd1024);
	#100;
	do_mspi_write(2'b10 , `ADDR_CYCLE_WIDTH_FLUSH, 16'd100);
	#100;
	do_mspi_write(2'b10 , `ADDR_CYCLE_WIDTH_AED, 16'd3660);
	#100;
	do_mspi_write(2'b10 , `ADDR_CYCLE_WIDTH_READ, 16'd1024);
	#100;
	do_mspi_write(2'b10 , `ADDR_REPEAT_FLUSH, 16'h00_04);
	#100;
	do_mspi_write(2'b10 , `ADDR_REPEAT_BACK_BIAS, 16'h00_01);
	#100;
	do_mspi_write(2'b10 , `ADDR_SATURATION_FLUSH_REPEAT, 16'h00_02);
	#100;
	do_mspi_write(2'b10 , `ADDR_UP_BACK_BIAS, 16'h00_02);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_BACK_BIAS, 16'h00_00);

	#100;
	do_mspi_write(2'b10 , `ADDR_UP_BACK_BIAS_OPR, 16'h00_01);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_BACK_BIAS_OPR, 16'h00_00);
	#100;

	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_0, 16'h00_14);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_1, 16'h01_A8);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_2, 16'h00_07);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_3, 16'h00_14);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_4, 16'h00_A2);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_5, 16'h00_14);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_6, 16'h00_58);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_7, 16'h00_37);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_8, 16'h00_69);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_9, 16'h00_07);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_10, 16'h00_00);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_11, 16'h00_18);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_12, 16'h00_02);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_13, 16'h00_23);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_14, 16'h00_2B);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_ROIC_REG_SET_15, 16'h00_08);

	#100;
	do_mspi_write(2'b10 , `ADDR_READY_AED_READ, 16'h00_03);
	#100;
	do_mspi_write(2'b10 , `ADDR_AED_TH, 16'h00_04);
	#100;
	// do_mspi_write(2'b10 , `ADDR_SEL_AED_ROIC, 16'h00_01);
	do_mspi_write(2'b10 , `ADDR_SEL_AED_ROIC, 16'h05_6A);
	#100;
	do_mspi_write(2'b10 , `ADDR_NUM_TRIGGER, 16'h00_01);
	#100;
	do_mspi_write(2'b10 , `ADDR_SEL_AED_TEST_ROIC, 16'h00_01);
	#100;
	do_mspi_write(2'b10 , `ADDR_NEGA_AED_TH, 16'h00_02);
	#100;
	do_mspi_write(2'b10 , `ADDR_POSI_AED_TH, 16'h00_03);
	#100;
	do_mspi_write(2'b10 , `ADDR_AED_DARK_DELAY, 16'h00_02);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_GATE_OE1_FLUSH, 16'd40);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_GATE_OE2_FLUSH, 16'd40);
	#100;

	// XAO setting
	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_0, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_0, 16'd2);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_1, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_1, 16'd2);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_2, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_2, 16'd2);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_3, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_3, 16'd2);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_4, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_4, 16'd2);
	#100;

	do_mspi_write(2'b10 , `ADDR_UP_AED_GATE_XAO_5, 16'd2030);
	#100;
	do_mspi_write(2'b10 , `ADDR_DN_AED_GATE_XAO_5, 16'd2);
	#100;



	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_01);

	// while (test_bench.cyan_uut.FSM_rst_index !== 1'b1) begin
	// 	@(test_bench.cyan_uut.FSM_rst_index); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test start >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);

	// // TI-ROIC Register setting
	do_mspi_write(2'b10 , `ADDR_TI_ROIC_STR, 16'h00_03);
	#100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_TP_SEL, 16'h00_01);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_01);
	// #200;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_00);
	// #100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_DATA, 16'h55_AA);
	// #100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h81_10);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h80_10);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h00_10);
	// #100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_TP_SEL, 16'h00_00);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_01);
	// #200;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_00);
	// #100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_DATA, 16'h5A_A5);
	// #100;

	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h81_11);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h80_11);
	// #100;
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h00_11);
	// #100;
	#5000;

		do_mspi_write(2'b10 , `ADDR_TI_ROIC_TP_SEL, 16'h00_01);
		#100;
		do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_01);
		#100;
		do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_00);
		#100;

		// roic regster setup
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_DATA, 16'h02_09);
			#100;

			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h81_40);
			#100;
			// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h80_40);
			// #100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h00_40);
			#100;
		// ---------------------

	#200000
		do_mspi_write(2'b10 , `ADDR_TI_ROIC_TP_SEL, 16'h00_00);
		#100;
		do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_01);
		#100;
		do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_00);
		#100;

		// roic regster setup
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_DATA, 16'h01_07);
			#100;

			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h81_40);
			#100;
			// do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h80_40);
			// #100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_REG_ADDR, 16'h00_40);
			#100;
		// ---------------------
	// #250000;
	// // // TI-ROIC Register setting
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_STR, 16'h00_02);
	// #100;

	// #250000;
	// // // TI-ROIC Register setting
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_STR, 16'h00_01);
	// #100;

	// #250000;
	// // // TI-ROIC Register setting
	// do_mspi_write(2'b10 , `ADDR_TI_ROIC_STR, 16'h00_00);
	// #100;

	#200000;
	do_mspi_write(2'b10 , `ADDR_TI_ROIC_TP_SEL, 16'h00_00);
	#100;
	do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_01);
	#100;
	do_mspi_write(2'b10 , `ADDR_TI_ROIC_SYNC, 16'h00_00);
	#100;



	#100;
	fsm_test_task(1, 16'h00_00);


	$display($time, " << Wait time 1msec for prep exp ack >>");
	#1000000;	// 1000 usec 

    prep_exp();
	$display($time, " << prep ack & exp ack done >>");

	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_01);	//lut write enable
	#200000;	// 200 usec


	// ===============================
	// ACQ mode 0
	// ===============================

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_00);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,   16'd1,    16'd100,  1'b0,   1'b0,   8'd1); //1
	// lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  IDLE,   16'd0,    16'd100,  1'b0,   1'b0,   8'd6); //1

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_01);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  BACK_BIAS,   16'd2,  16'd2047,  1'b1,   1'b0,   8'd2); //1

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_02);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat, length,  sof,   eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  WAIT,   16'd1,  16'd2047, 1'b1, 1'b1,   8'd3); //2

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_03);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  FLUSH,    16'd5,   16'd2047,  1'b0,   1'b0,   8'd4); //3

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_04);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,   repeat,  length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  WAIT,    16'd1,   16'd2047, 1'b1,   1'b0,   8'd5); //4

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_05);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	// lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  BACK_BIAS,   16'd3,      16'd100, 1'b0,   1'b0,   8'd6);
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b1, 1'b1,  READOUT,   16'd3,    16'd2047, 1'b0,   1'b1,   8'd6);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_06);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  WAIT,   16'd1,    16'd200, 1'b0,   1'b0,   8'd1);
	// lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  BACK_BIAS,  16'd1,      16'd1, 1'b0,   1'b0,   8'd5);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_08);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  BACK_BIAS,   16'd0,  16'd2047, 1'b1,   1'b0,   8'd9);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_09);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,   16'd5,    16'd100, 1'b0,   1'b0,   8'd10);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0A);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b1, 1'b1,  READOUT,     16'd5,  16'd2047, 1'b0,   1'b1,   8'd11); //10

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0B);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,  length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,   16'd0,   16'd1,   1'b0,   1'b0,   8'd8); // 11

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0C);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0, EXPOSE_TIME,  16'd3,   16'd32,  1'b1,   1'b0,   8'd13); // 12

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 32x8 = 256
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 Expose
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0D);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b1,  READOUT,     16'd7,  16'd2047, 1'b0,   1'b0,   8'd14); // 13

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0E);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,      16'd2,  16'd2047, 1'b0,   1'b0,   8'd15); // 14

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'd31);	//lut addr 0
	#100;
    //     //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	// lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b1, 1'b0, 1'b0,  WAIT,        16'd0,  16'd1,    1'b0,   1'b0,   8'd8); // 11

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, 16'h40_03);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, 16'h05_00);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, 16'h00_60);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, 16'h00_00);	//lut data 2 
	#100;



	// ===============================
	// ACQ mode 4
	// ===============================
	
	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_80);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd1,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,   16'd1,    16'd100,  1'b0,   1'b0,   8'd129); //1

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_81);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  BACK_BIAS,   16'd2,  16'd2047,  1'b1,   1'b0,   8'd130); //1

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_82);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  FLUSH,     16'd5,    16'd2047, 1'b0,   1'b1,   8'd131); //2

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_83);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,  repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b1, 1'b1, 1'b0, 1'b0,  WAIT,    16'd0,   16'd0,  1'b0,   1'b0,   8'd129); //3

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_84);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b1, 1'b0, 1'b0,  WAIT,      16'd1,   16'd10, 1'b0,   1'b0,   8'd136); //4

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_85);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,       repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  BACK_BIAS,   16'd3,   16'd2047, 1'b0,   1'b0,   8'd134);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_86);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  FLUSH,     16'd5,    16'd2047, 1'b0,   1'b0,   8'd135);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_88);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,   repeat, length,    sof,   eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  WAIT,    16'd0,  16'd2047,  1'b1,  1'b0,   8'd137);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_89);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b1, 1'b1,  READOUT,   16'd1,    16'd2047,  1'b1,   1'b0,   8'd138);

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_8A);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,       repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,  AED_DETECT,  16'd100,  16'd2047, 1'b0,   1'b1,   8'd139); //10

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_8B);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b1, 1'b0, 1'b0,  WAIT,      16'd0,    16'd1,    1'b0,   1'b0,   8'd136); // 11

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;

	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_8C);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,  sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0, EXPOSE_TIME,  16'd3,   16'd32,  1'b1,   1'b0,   8'd141); // 12

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 32x8 = 256
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 Expose
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_8D);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b1,  READOUT,     16'd7,  16'd2047, 1'b0,   1'b0,   8'd142); // 13

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_8E);	//lut addr 0
	#100;
        //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b0, 1'b0, 1'b0,    WAIT,      16'd2,  16'd2047, 1'b0,   1'b0,   8'd143); // 14

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, lut_wr_data[15:0]);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, lut_wr_data[31:16]);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, lut_wr_data[47:32]);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, {12'd0,lut_wr_data[51:48]});	//lut data 2 
	#100;


	// lut ram address
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'd31);	//lut addr 0
	#100;
    //     //            Format: iter_index, iter , PS , CSI , STV ,  state,     repeat,   length,   sof,    eof,   next_addr
	// lut_wr_data = pack_lut_entry(  2'd0,  1'b0, 1'b1, 1'b0, 1'b0,  WAIT,        16'd0,  16'd1,    1'b0,   1'b0,   8'd8); // 11

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_0, 16'h40_03);	//lut data 0 2048
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_1, 16'h05_00);	//lut data 1
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_2, 16'h00_60);	//lut data 2 
	#100;
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_DATA_3, 16'h00_00);	//lut data 2 
	#100;


	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_00);	//lut write disable
	#200000;	// 200 usec

	// ===============================

	#1000000;	// 1000 usec


	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_01);	//lut write enable
	#200000;	// 200 usec

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_ADDR, 16'h00_0A);	//lut addr 0
	#400;

	do_mspi_read(2'b01 , `ADDR_SEQ_LUT_DATA_0);
	#100;
	do_mspi_read(2'b01 , `ADDR_SEQ_LUT_DATA_1);
	#100;
	do_mspi_read(2'b01 , `ADDR_SEQ_LUT_DATA_2);
	#100;
	do_mspi_read(2'b01 , `ADDR_SEQ_LUT_DATA_3);
	#100;

	do_mspi_read(2'b01 , `ADDR_SEQ_LUT_ADDR);	//lut addr 0
	$display($time, " << spi_read >> : %h", masterDataReceived);
	#400;

	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_00);	//lut write disable
	#200000;	// 200 usec

	#1000000;	// 1000 usec


	do_mspi_write(2'b10 , `ADDR_OP_MODE_REG, 16'h00_1A); 
	#100;

	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_01);	//lut write enable
	#200000;	// 200 usec

	$display($time, " << Sequencer FSM Start >>");
	do_mspi_write(2'b10 , `ADDR_ACQ_MODE, 16'h00_00);	//ACQ mode 0
	#100;


	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_00);	//lut write enable
	#200000;	// 200 usec


// #################################
//  Test 0
//  Line mode test , 
//	BackBias on , 
//	Flush on
//  PANEL Stable on 
// #################################
	$display($time, " << Test 0 , Line , BB on , Flush on , Panel stable on >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_AED_CMD, 16'h00_00);
	$display($time, " << Test 0 AED CMD Off>>");

	#100;
	do_mspi_write(2'b10 , `ADDR_READOUT_COUNT, 16'h00_01);
	$display($time, " << Test 0 Read out Repeat  1 >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_READY_AED_READ, 16'h00_02);
	$display($time, " << Test 0 READY AED READ 2 >>");
	#100;
	do_mspi_write(2'b10 , `ADDR_REPEAT_BACK_BIAS, 16'h00_01);
	$display($time, " << Test 0 Back Bias 1 >>");
	#100;
	do_mspi_write(2'b10 , `ADDR_REPEAT_FLUSH, 16'h00_02);
	$display($time, " << Test 0 FLUSH 2 >>");
	#100;
	do_mspi_write(2'b10 , `ADDR_SATURATION_FLUSH_REPEAT, 16'h00_02);
	
	$display($time, " << Test 0 Saturation Repeat  2 >>");
	#100;
	// burst_get[8] , test pattern row[4] col[3], en_panel_stable[1] , en_full_flush[0]
	do_mspi_write(2'b10 , `ADDR_OP_MODE_REG, 16'h00_02); // test pattern , bit4: row bit3: col
	$display($time, " << Test 0 enable panel stable >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_IMAGE_HEIGHT, 16'd5);
	$display($time, " << Test 0 MAGE_HEIGHT 10 >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_01);	//fsm reset
	$display($time, " << Test 0 FSM reset >>");

	// while (test_bench.cyan_uut.FSM_rst_index !== 1'b1) begin
	// 	@(test_bench.cyan_uut.FSM_rst_index); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// @(posedge test_bench.uut.FSM_rst_index);
	$display($time, " << Test 0 FSM rst start >>");
	#100000;	//100usec
	
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);
	$display($time, " << Test 0 SYS CMD 0 >>");

	$display($time, " << Test 0 Wait time 1msec start >>");
	// #1000000;	// 1msec 
	#985000;	// 985usec 

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end

	while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
		@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_02);
	$display($time, " << Test 0 get dark 0 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b0) begin
	// 	@(test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 0 Sequence done 0 >>");

	while (test_bench.cyan_uut.expose_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.expose_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 0 Espose start 0 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 0 Readout start 0 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b1) begin
		@(!test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 0 Readout close 0 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 0 Sequence done 0 >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);


	// burst_get[8] , test pattern row[4] col[3], en_panel_stable[1] , en_full_flush[0]
	#100;
	// do_mspi_write(2'b10 , `ADDR_OP_MODE_REG, 16'h00_1A); 
	do_mspi_write(2'b10 , `ADDR_OP_MODE_REG, 16'h00_02); 
	$display($time, " << Test 0 set test pattern 0 >>");

	$display($time, " << Test 0 wait time 3msec start >>");
	#3000000;	//5msec

	// while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// // @(negedge test_bench.uut.ctrl_FSM_inst.panel_stable_o);
	// $display($time, " << Test 0 panel stable close >>");
	// while (test_bench.cyan_uut.s_exp_read_exist == 1'b1) begin
	// 	@(!test_bench.cyan_uut.s_exp_read_exist); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// // @(negedge test_bench.uut.ctrl_FSM_inst.s_exp_read_exist);
	// $display($time, " << Test 0 expose , readout close >>");
	
	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end

	while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
		@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_04);  // get bright
	$display($time, " << Test Bright 0 get bright 1 >>");


	// while (test_bench.cyan_uut.sequence_done_o == 1'b0) begin
	// 	@(test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Bright 0 Sequence done 0 >>");

	while (test_bench.cyan_uut.expose_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.expose_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Bright 0 Espose start 0 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Bright 0 Readout start 0 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b1) begin
		@(!test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Bright 0 Readout close 0 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end

	$display($time, " << Test 0 panel stable start >>");
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);

	$display($time, " << Test 0 1.5msec Wait start >>");
	#1500000;	// 3msec

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end

	while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
		@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end

	// #5000;
	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_02);
	$display($time, " << Test 1 get dark 1 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b0) begin
	// 	@(test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 1 Sequence done 1 >>");

	while (test_bench.cyan_uut.expose_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.expose_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 1 Espose start 1 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 1 Readout start 1 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b1) begin
		@(!test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 01 Readout close 1 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 1 Sequence done 1 >>");

	#100;
	do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);
	$display($time, " << Test 0 complete >>");

	$display($time, " << Test 0 2msec Wait start >>");
	#2000000;	// 2msec

	do_mspi_write(2'b10 , `ADDR_EXPOSE_SIZE, 16'd1); // test pattern , bit4: row bit3: col
	$display($time, " << expose size 2 >>");
	#100;

	do_mspi_write(2'b10 , `ADDR_PRE_DELAY, 16'd1); // test pattern , bit4: row bit3: col
	$display($time, " << PRE_DELAY size 1 >>");
	#100;

	do_mspi_write(2'b10 , `ADDR_POST_DELAY, 16'd1); // test pattern , bit4: row bit3: col
	$display($time, " << POST_DELAY size 1 >>");
	#100;


	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_01);	//lut write enable
	#200000;	// 200 usec

	$display($time, " << Sequencer FSM Start >>");
	do_mspi_write(2'b10 , `ADDR_ACQ_MODE, 16'h00_04);	//ACQ mode 0
	#100;

	$display($time, " << Sequence lut table set >>");
	do_mspi_write(2'b10 , `ADDR_SEQ_LUT_CONTROL, 16'h00_00);	//lut write enable
	#200000;	// 200 usec

	while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
		@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test 0 panel stable start >>");
	#1000000;	// 1msec

	get_aed_trig();
	$display($time, " << AED trig done >>");
	#200000;	// 200usec

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end

	// // #5000;
	// #100;
	// do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_02);
	// $display($time, " << Test 1 get dark 1 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b0) begin
	// 	@(test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 1 Sequence done 1 >>");

	while (test_bench.cyan_uut.expose_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.expose_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 1 Espose start 1 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b0) begin
		@(test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 1 Readout start 1 >>");

	while (test_bench.cyan_uut.readout_enable_o == 1'b1) begin
		@(!test_bench.cyan_uut.readout_enable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test Dark 01 Readout close 1 >>");

	// while (test_bench.cyan_uut.sequence_done_o == 1'b1) begin
	// 	@(!test_bench.cyan_uut.sequence_done_o); // fsm_rst_index?�� �?? �???���?? 감�?
	// end
	// $display($time, " << Test Dark 1 Sequence done 1 >>");

	// #100;
	// do_mspi_write(2'b10 , `ADDR_SYS_CMD_REG, 16'h00_00);
	// $display($time, " << Test 0 complete >>");

	$display($time, " << Test 0 2msec Wait start >>");
	#2000000;	// 2msec

	while (test_bench.cyan_uut.panel_stable_o == 1'b1) begin
		@(!test_bench.cyan_uut.panel_stable_o); // fsm_rst_index?�� �?? �???���?? 감�?
	end
	$display($time, " << Test 0 panel stable start >>");
	#2000000;	// 2msec


	get_aed_trig();
	$display($time, " << AED trig done >>");
	#200000;	// 200usec

// ============================================================
	$display($time, " << Wait time 15msec start >>");
	#15000000;	// 15msec
	$display($time, " << simulation stop >>");

	$stop;

	end

	logic 					m_SCLK;
	logic 					m_MOSI;
	logic 					m_MISO;
	logic [2:0]				m_CS;


//	top uut(
//		.nRST						(nRST					),
//		.MCLK_50M_p					(MCLK_50M_p				),
//		.MCLK_50M_n					(MCLK_50M_n				),
//		.mipi_phy_if_clk_hs_p		(mipi_phy_if_clk_hs_p	),
//		.mipi_phy_if_clk_hs_n		(mipi_phy_if_clk_hs_n	),
//		.mipi_phy_if_clk_lp_p		(mipi_phy_if_clk_lp_p	),
//		.mipi_phy_if_clk_lp_n		(mipi_phy_if_clk_lp_n	),
//		.mipi_phy_if_data_hs_p		(mipi_phy_if_data_hs_p	),
//		.mipi_phy_if_data_hs_n		(mipi_phy_if_data_hs_n	),
//		.mipi_phy_if_data_lp_p		(mipi_phy_if_data_lp_p	),
//		.mipi_phy_if_data_lp_n		(mipi_phy_if_data_lp_n	),
//		.SCLK						(m_SCLK					),
//		.SSB						(m_CS[0]				),
//		.MOSI						(m_MOSI					),
//		.MISO						(m_MISO					),
//		.ROIC_RESET_R 				(ROIC_RESET_R 			),
//		.ROIC_SYNC_R  				(ROIC_SYNC_R  			),
//		.ROIC_ACLK_R  				(ROIC_ACLK_R  			),
//		.DCLK_R        				(DCLK_R        			),
//		.R_ROIC_DCLKo_p				(R_ROIC_DCLKo_p			),
//		.R_ROIC_DCLKo_n				(R_ROIC_DCLKo_n			),
//		.R_DOUTA_H					(R_DOUTA_H				),
//		.R_DOUTA_L					(R_DOUTA_L				),
//		.R_DOUTB_H					(R_DOUTB_H				),
//		.R_DOUTB_L					(R_DOUTB_L				),
//		.GF_STV_L   				(GF_STV_L   			),
//		.GF_STV_LR2 				(GF_STV_LR2 			),
//		.GF_STV_LR3 				(GF_STV_LR3 			),
//		.GF_STV_LR4 				(GF_STV_LR4 			),
//		.GF_STV_LR5 				(GF_STV_LR5 			),
//		.GF_STV_LR6 				(GF_STV_LR6 			),
//		.GF_STV_LR7 				(GF_STV_LR7 			),
//		.GF_STV_LR8 				(GF_STV_LR8 			),
//		.GF_STV_R   				(GF_STV_R   			),
//		.GF_CPV    					(GF_CPV    				),
//		.GF_OE	   					(GF_OE	   				),
//		.GF_XAO_1					(GF_XAO_1				),
//		.GF_XAO_2					(GF_XAO_2				),
//		.GF_XAO_3					(GF_XAO_3				),
//		.GF_XAO_4					(GF_XAO_4				),
//		.GF_XAO_5					(GF_XAO_5				),
//		.GF_XAO_6					(GF_XAO_6				),
//		.GF_XAO_7					(GF_XAO_7				),
//		.GF_XAO_8					(GF_XAO_8				),
//		.R_SW_BIAS   				(R_SW_BIAS   			),
//		.RF_SPI_CS_1 				(RF_SPI_CS_1 			),
//		.RF_SPI_SCK_1				(RF_SPI_SCK_1			),
//		.RF_SPI_SDI_1				(RF_SPI_SDI_1			),
//		.RF_SPI_SDO_1				(RF_SPI_SDO_1			),
//		.R_SW_AVDDI					(R_SW_AVDDI				),
//		.prep_req         			(prep_req         		),
//		.exp_req          			(exp_req          		),
//		.prep_ack         			(prep_ack         		),
//		.exp_ack          			(exp_ack          		),
//		.STATE_LED1       			(            			),
//		.STATE_LED2       			(led_7            		)
//	);

	assign		R_DOUTA_L =  ~R_DOUTA_H;
	assign		R_DOUTB_L =  ~R_DOUTB_H;
	
	assign		R_ROIC_DCLKo_n =  ~R_ROIC_DCLKo_p;

	wire			sv_mipi_phy_if_clk_hs_p	;
	wire			sv_mipi_phy_if_clk_hs_n	;
	wire			sv_mipi_phy_if_clk_lp_p	;
	wire			sv_mipi_phy_if_clk_lp_n	;
	wire	[mipi_lane-1:0]	sv_mipi_phy_if_data_hs_p	;
	wire	[mipi_lane-1:0]	sv_mipi_phy_if_data_hs_n	;
	wire	[mipi_lane-1:0]	sv_mipi_phy_if_data_lp_p	;
	wire	[mipi_lane-1:0]	sv_mipi_phy_if_data_lp_n	;

	cyan_top cyan_uut(
		.nRST						(nRST					),
		.MCLK_50M_p					(MCLK_50M_p				),
		.MCLK_50M_n					(MCLK_50M_n				),
		.mipi_phy_if_clk_hs_p		(sv_mipi_phy_if_clk_hs_p	),
		.mipi_phy_if_clk_hs_n		(sv_mipi_phy_if_clk_hs_n	),
		.mipi_phy_if_clk_lp_p		(sv_mipi_phy_if_clk_lp_p	),
		.mipi_phy_if_clk_lp_n		(sv_mipi_phy_if_clk_lp_n	),
		.mipi_phy_if_data_hs_p		(sv_mipi_phy_if_data_hs_p	),
		.mipi_phy_if_data_hs_n		(sv_mipi_phy_if_data_hs_n	),
		.mipi_phy_if_data_lp_p		(sv_mipi_phy_if_data_lp_p	),
		.mipi_phy_if_data_lp_n		(sv_mipi_phy_if_data_lp_n	),
		.SCLK						(m_SCLK					),
		.SSB						(m_CS[0]				),
		.MOSI						(m_MOSI					),
		.MISO						(m_MISO					),
		.ROIC_TP_SEL 				( 			),
		.ROIC_SYNC  				(  			),
		.ROIC_MCLK0  				(  			),
		.ROIC_MCLK1  				(  			),
		.SWITCH_SYNC        		(), // (DCLK_R        			),
		.AED_TRIG 	 				(AED_TRIG       			),
		.R_ROIC_DCLKo_p				({12{TI_DCLK_p}}			),
		.R_ROIC_DCLKo_n				({12{TI_DCLK_n}}			),
		.R_ROIC_FCLKo_p				({12{TI_FCLK_p}}			),
		.R_ROIC_FCLKo_n				({12{TI_FCLK_n}}			),
		.R_DOUTA_H					({12{TI_DOUT_p}}				),
		.R_DOUTA_L					({12{TI_DOUT_n}}				),
		// .R_DOUTB_H					(R_DOUTB_H				),
		// .R_DOUTB_L					(R_DOUTB_L				),
		// // TI ROIC interface
		// .TI_FCLK_p					({12{TI_FCLK_p}}	),
		// .TI_FCLK_n					({12{TI_FCLK_n}}	),
		// .TI_DCLK_p					({12{TI_DCLK_p}}	),
		// .TI_DCLK_n					({12{TI_DCLK_n}}	),
		// .TI_DOUT_p					({12{TI_DOUT_p}}	),
		// .TI_DOUT_n					({12{TI_DOUT_n}}	),
		// Gate Driving Signals
		.GF_STV_L   				(), // (GF_STV_L   			),
		.GF_STV_R   				(), // (GF_STV_R   			),
		.GF_CPV    					(), // (GF_CPV    				),
		.GF_OE	   					(), // (GF_OE	   				),
		// .GF_OE1	   					(), // (GF_OE	   				),
		// .GF_OE2	   					(), // (GF_OE	   				),
		// .GF_CS1	   					(), // (GF_OE	   				),
		// .GF_CS2	   					(), // (GF_OE	   				),
		.GF_LR   					(), // (GF_OE	   				),
		.GF_XAO						(), // (GF_XAO_1				),
		.RF_SPI_SEN 				(), // (RF_SPI_CS_1 			),
		.RF_SPI_SCK					(), // (RF_SPI_SCK_1			),
		.RF_SPI_SDI					(RF_SPI_SDO_1), // (RF_SPI_SDI_1			),
		.RF_SPI_SDO					({12{RF_SPI_SDO_1}}			),
		.ROIC_VBIAS   				(), // (R_SW_BIAS   			),
		.ROIC_AVDD1   				(), // (R_SW_BIAS   			),
		.ROIC_AVDD2					(), // (R_SW_AVDDI				),
		.PREP_REQ         			(prep_req         		),
		.EXP_REQ          			(exp_req          		),
		.PREP_ACK         			(prep_ack), // (prep_ack         		),
		.EXP_ACK          			(exp_ack), // (exp_ack          		),
		.STATE_LED1       			(            		)
	);


//	roic_model u_roic_model_R
//		(
//			.roic_sync				(ROIC_SYNC_R			),
//			.roic_data_clk			(roic_data_clk			),
//			.dclk					(DCLK_R					),
//			.led_4					(test_bench.uut.FSM_aed_read_index					),
//			.led_5					(test_bench.uut.FSM_read_index),

//			.dclk_out0				(R_ROIC_DCLKo_p[0] 	),
//			.dclk_out1				(R_ROIC_DCLKo_p[1] 	),
//			.dclk_out2				(R_ROIC_DCLKo_p[2] 	),
//			.dclk_out3				(R_ROIC_DCLKo_p[3] 	),
//			.dclk_out4				(R_ROIC_DCLKo_p[4] 	),
//			.dclk_out5				(R_ROIC_DCLKo_p[5] 	),
//			.dclk_out6				(R_ROIC_DCLKo_p[6] 	),
//			.dclk_out7				(R_ROIC_DCLKo_p[7] 	),
//			.dclk_out8				(R_ROIC_DCLKo_p[8] 	),
//			.dclk_out9				(R_ROIC_DCLKo_p[9] 	),
//			.dclk_out10				(R_ROIC_DCLKo_p[10]	),
//			.dclk_out11				(R_ROIC_DCLKo_p[11]	),

//			.douta0					(R_DOUTA_H[0]      	),
//			.douta1					(R_DOUTA_H[1]      	),
//			.douta2					(R_DOUTA_H[2]      	),
//			.douta3					(R_DOUTA_H[3]      	),
//			.douta4					(R_DOUTA_H[4]      	),
//			.douta5					(R_DOUTA_H[5]      	),
//			.douta6					(R_DOUTA_H[6]      	),
//			.douta7					(R_DOUTA_H[7]      	),
//			.douta8					(R_DOUTA_H[8]      	),
//			.douta9					(R_DOUTA_H[9]      	),
//			.douta10				(R_DOUTA_H[10]     	),
//			.douta11				(R_DOUTA_H[11]     	),

//			.doutb0					(R_DOUTB_H[0]      	),
//			.doutb1					(R_DOUTB_H[1]      	),
//			.doutb2					(R_DOUTB_H[2]      	),
//			.doutb3					(R_DOUTB_H[3]      	),
//			.doutb4					(R_DOUTB_H[4]      	),
//			.doutb5					(R_DOUTB_H[5]      	),
//			.doutb6					(R_DOUTB_H[6]      	),
//			.doutb7					(R_DOUTB_H[7]      	),
//			.doutb8					(R_DOUTB_H[8]      	),
//			.doutb9					(R_DOUTB_H[9]      	),
//			.doutb10				(R_DOUTB_H[10]     	),
//			.doutb11				(R_DOUTB_H[11]     	)
//		);



// mipi csi2 Rx module
	reg					clk_100MHz			;
	assign clk_100MHz = roic_data_clk;

mipi_csi2_rx_wrapper ex_mipi_csi2_rx
  (
    .clk_100MHz                 (clk_100MHz),
    .done                       (),
    .done_1                     (),
    .mipi_phy_if_0_clk_hs_p     (mipi_phy_if_clk_hs_p),
    .mipi_phy_if_0_clk_hs_n     (mipi_phy_if_clk_hs_n),
    .mipi_phy_if_0_clk_lp_p     (mipi_phy_if_clk_lp_p),
    .mipi_phy_if_0_clk_lp_n     (mipi_phy_if_clk_lp_n),
    .mipi_phy_if_0_data_hs_p    (mipi_phy_if_data_hs_p),
    .mipi_phy_if_0_data_hs_n    (mipi_phy_if_data_hs_n),
    .mipi_phy_if_0_data_lp_p    (mipi_phy_if_data_lp_p),
    .mipi_phy_if_0_data_lp_n    (mipi_phy_if_data_lp_n),
    .reset_rtl_0                (reset),
    .rxbyteclkhs                (),
    .status                     (),
    .status_1                   (),
    .video_out_tdata            (),
    .video_out_tdest            (),
    .video_out_tlast            (),
    .video_out_tvalid           ()
    );
    
mipi_csi2_rx_wrapper sv_mipi_csi2_rx
  (
    .clk_100MHz                 (clk_100MHz),
    .done                       (),
    .done_1                     (),
    .mipi_phy_if_0_clk_hs_p     (sv_mipi_phy_if_clk_hs_p),
    .mipi_phy_if_0_clk_hs_n     (sv_mipi_phy_if_clk_hs_n),
    .mipi_phy_if_0_clk_lp_p     (sv_mipi_phy_if_clk_lp_p),
    .mipi_phy_if_0_clk_lp_n     (sv_mipi_phy_if_clk_lp_n),
    .mipi_phy_if_0_data_hs_p    (sv_mipi_phy_if_data_hs_p),
    .mipi_phy_if_0_data_hs_n    (sv_mipi_phy_if_data_hs_n),
    .mipi_phy_if_0_data_lp_p    (sv_mipi_phy_if_data_lp_p),
    .mipi_phy_if_0_data_lp_n    (sv_mipi_phy_if_data_lp_n),
    .reset_rtl_0                (reset),
    .rxbyteclkhs                (),
    .status                     (),
    .status_1                   (),
    .video_out_tdata            (),
    .video_out_tdest            (),
    .video_out_tlast            (),
    .video_out_tvalid           ()
    );
    


	spi_master #(
		.pktsz   		( pktsz ),
		.header  		( header ),
		.payload 		( payload ),
		.addrsz  		( addrsz )
		)
	spi_master_inst  (
		.clk     			(MCLK_50M_p),
		.reset 				(reset),
		.start				(m_start),
		.slaveselect		(slaveselect),
		.masterHeader 		(masterHeader),
		.masterAddrToSend	(masterAddrToSend),
		.masterDataToSend	(masterDataToSend),

		.masterDataReceived	(masterDataReceived),
		.SCLK	   			(m_SCLK),
		.CS					(m_CS),
		.MOSI				(m_MOSI),
		.MISO				(m_MISO)
		);


// task module
    task rst();
        begin
            reset = 1'b1;
            #50;
            reset = 1'b0;
        end
    endtask

    task prep_exp();
        begin
            exp_req = 1'b1;
            prep_req = 1'b1;
            #100;
            wait (exp_ack == 1'b0);
            #100;
			exp_req = 1'b0;
			prep_req = 1'b0;
			#100;
			wait (exp_ack == 1'b1);
			#100;
        end
    endtask
                
	task get_aed_trig();
		begin
			AED_TRIG = 1'b1;
			#100000;
			AED_TRIG = 1'b0;
		end
	endtask


// spi task

	task do_mspi_write;
		input [header-1:0] 	from_header;
		// input [addrsz-1:0] 	from_addr;
		input [16-1:0] 	from_addr;
		input [payload-1:0] from_data;

		int i;

		begin
			@(posedge m_sclk_in);
				// #(sclk_period) m_start =1'b0;
				masterHeader = from_header;
				masterAddrToSend = from_addr[addrsz-1:0];
				masterDataToSend = from_data;
				#1;
				#(sclk_period) m_start =1'b1;
				#(sclk_period) m_start =1'b0;
		end

		for (i=0;i<pktsz;i++)
			begin
				#(sclk_period);
			end
		#400;
		$display($time, " # MSPI Write Addr : %h , Data : %h", from_addr, from_data);

	endtask

	task do_mspi_read;
		input [header-1:0] 	from_header;
		// input [addrsz-1:0] 	from_addr;
		input [16-1:0] 	from_addr;
		
		int i;
		
		begin
			@(posedge m_sclk_in);
				// #(sclk_period) m_start =1'b0;
				masterHeader = from_header;
				masterAddrToSend = from_addr[addrsz-1:0];
				#1;
				#(sclk_period) m_start =1'b1;
				#(sclk_period) m_start =1'b0;
		end

		for (i=0;i<pktsz;i++)
			begin
				#(sclk_period);
			end
		#600;
		$display($time, " # MSPI Read Addr : %h , Data : %h", from_addr, masterDataReceived);

	endtask

	// FSM test task
	task fsm_test_task;
		input test_no;	
		input [15:0] aed_cmd;

		begin
			$display($time, " << Test %d Start >>" , test_no);
			
			#100;
			do_mspi_write(2'b10 , `ADDR_AED_CMD, aed_cmd);
			$display($time, " << Test %d AED CMD Off>>" , test_no);

		end
	endtask


	// TI ROIC test case 

    string roic_data_file_path = "/home/holee/fpga/git_work/CYAN-FPGA/xdaq_top/source/hdl/ti-roic/tb_src/roic_sim_data_522.txt"; // Path to ROIC simulation data file
    string roic_256_data_file_path = "/home/holee/fpga/git_work/CYAN-FPGA/xdaq_top/source/hdl/ti-roic/tb_src/roic_sim_data_256.txt"; // Path to ROIC simulation data file
    
    logic deser_reset;               // Deserializer reset
    // Test validation signals
    int test_pass_count;             // Counter for successful test cases
    int test_fail_count;             // Counter for failed test cases
    logic [23:0] expected_data;      // Expected data for validation

    logic fclk_p;
	logic mclk_sim;
	logic dclk_sim;

    assign fclk_p = TI_FCLK_p;
    
    // Generate simulated AFE master clock - 4.167MHz (240ns period)
    initial begin
        mclk_sim = 1'b0;
        // forever #120 mclk_sim = ~mclk_sim;
        forever #25 mclk_sim = ~mclk_sim;	// 20Mhz , 50ns period
    end

    // Generate simulated data clock - 100MHz (10ns period)
    initial begin
        dclk_sim = 1'b0;
        // forever #5 dclk_sim = ~dclk_sim;
        // forever #1.04 dclk_sim = ~dclk_sim;	// 480Mhz , TI ROIC STR 0 240Mhz
        forever #8.334 dclk_sim = ~dclk_sim;	// 30Mhz , TI ROIC STR 3 fclk 2.5Mhz
        // forever #4.15 dclk_sim = ~dclk_sim;	// 60Mhz , TI ROIC STR 2 , mclk 20Mhz fclk 5Mhz
    end

    // AFE2256 emulator to generate test patterns
    afe2256_emulator #(
        .DATA_WIDTH(WORD_SIZE),
        .SIM_MODE(1),               // Enable simulation mode
        .DCLK_ALIGN(1)              // Enable DCLK alignment for better synchronization
    ) afe2256_inst (
        .mclk          (mclk),
        .mclk_sim      (mclk_sim),
        .dclk_sim      (dclk_sim),
        .reset         (test_bench.cyan_uut.init_rst),
        .adc_data_valid(adc_data_valid),
        .adc_data      (adc_data),
        .dclk_p        (TI_DCLK_p),
        .dclk_n        (TI_DCLK_n),
        .fclk_p        (TI_FCLK_p),
        .fclk_n        (TI_FCLK_n),
        .dout_p        (TI_DOUT_p),
        .dout_n        (TI_DOUT_n)
    );

	// assign test_bench.cyan_uut.deser_reset = deser_reset;

    //--------------------------------------------------------------------------
    // Main Test Sequence
    //--------------------------------------------------------------------------
    initial begin
        // Initialize signals
        initialize_signals();
        // Setup and release reset
        setup_and_release_deser_reset();

        wait(!test_bench.cyan_uut.init_rst); // Wait for initialization reset to complete
		$display("[%0t ns] Initialization complete, starting test sequence", $time);

        // // Setup and release reset
        // setup_and_release_clk_reset();
        
        // Setup and release reset
        setup_and_release_deser_reset();
       // Configure delay settings
        configure_delay_settings();
        
        // // Start bit alignment in AUTO mode
        // start_auto_alignment();
        
        // Send alignment patterns
        enable_data_transmission();
        #100 // Wait for data to stabilize

        set_alignment_mode(0); // Set to auto-detection mode
        #100; // Wait for data to stabilize
        // Setup and release reset
        setup_and_release_deser_reset();
        // Send alignment patterns
        detect_and_save_shift_value(24'hFFF000);
        // Test data valid toggling
        test_data_valid_toggling();

        // set_alignment_mode(1); // Set to auto-detection mode
        // #100; // Wait for data to stabilize
        // // Setup and release reset
        // setup_and_release_deser_reset();
        // // Send alignment patterns
        // detect_and_save_shift_value(24'hFF0000);
        // // Test data valid toggling
        // test_data_valid_toggling();

        // set_alignment_mode(0); // Set to auto-detection mode
        // #100; // Wait for data to stabilize
        // // Setup and release reset
        // setup_and_release_deser_reset();
        // // Send alignment patterns
        // detect_and_save_shift_value(24'hFF0000);
        
        // // Read and apply data from roic_sim_data.txt file with explicit file path
        // read_and_apply_roic_data_file(roic_data_file_path, 1);
	// 125us point
	$display($time, " << 125us point >>");

	// // #830000;
	// #310000;

	// wait(test_bench.cyan_uut.gen_sync_start);
	// $display($time, " << Test STR sync pattern Start >>");
    // // Read and apply data from roic_sim_data.txt file with explicit file path
    // read_and_apply_roic_data_file(roic_256_data_file_path, 256);


        // // Generate final test report
        // report_test_summary();
        
        // End simulation
        // #1000;
        // $display("[%0t ns] Simulation completed successfully", $time);
//        $finish;
    end
    
    //--------------------------------------------------------------------------
    // Test Initialization
    //--------------------------------------------------------------------------    // Initialize all control signals to default values
    task initialize_signals();
        begin
            // Reset control signals
//            clk_reset = 1'b1;           // Assert system reset
        	// deser_reset = 1'b1;         // Assert deserializer reset
            adc_data_valid = 1'b0;      // Disable ADC data transmission
            adc_data = 24'h000000;      // Initialize ADC data to zeros
            
            // // Delay control signals
            // test_bench.cyan_uut.ld_dly_tap = 1'b0;          // Don't load delay taps yet
            // test_bench.cyan_uut.in_delay_tap_in = 5'h00;    // Initial delay value = 0
            // test_bench.cyan_uut.in_delay_data_ce = 1'b0;    // Disable delay control
            // test_bench.cyan_uut.in_delay_data_inc = 1'b0;   // Set delay direction (not used)
            // // Alignment control signals
            // test_bench.cyan_uut.extra_shift[0] = 5'h00;        // No additional bit shifting
            // test_bench.cyan_uut.align_to_fclk = 1'b0;       // Use auto-detection mode initially
            // test_bench.cyan_uut.align_start = 1'b0;         // Don't start alignment yet

			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_TAP_LD, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_TAP_IN, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_DATA_CE, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_DATA_INC, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_SHIFT_SET_0, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_MODE, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_00);
			#100;


            // Test validation counters
            test_pass_count = 0;        // Initialize pass counter
            test_fail_count = 0;        // Initialize fail counter
            expected_data = 24'h0;      // Initialize expected data
            
        end
    endtask
    
    // // Release system reset in controlled sequence
    // task setup_and_release_clk_reset();
    //     begin
    //         // Hold in reset for stable initialization
    //         clk_reset = 1'b1;           // Ensure reset is asserted
    //         #200;                       // Hold reset for 200ns
            
    //         // Release system reset but keep deserializer in reset
    //         clk_reset = 1'b0;           // Release system reset
    //         #200;                       // Wait for system to stabilize
    //     end
    // endtask

    // Release deserializer reset at appropriate time
    task setup_and_release_deser_reset();
        begin
            // // Hold in reset for stable initialization
            // deser_reset = 1'b1;         // Ensure deserializer reset is asserted
            // #200;                       // Hold reset for 200ns
            
            // // Release deserializer reset
            // deser_reset = 1'b0;         // Release deserializer reset
            // #200;                       // Wait for deserializer to stabilize
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_RESET, 16'h00_01);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_RESET, 16'h00_00);
			#100;
			$display("[%0t ns] Deserializer reset released", $time);
        end
    endtask

    // Start data transmission from the AFE2256 emulator
    task enable_data_transmission();
        begin
            @(posedge fclk_p);
            adc_data_valid = 1'b0;      // Disable data transmission initially
            $display("[%0t ns] Starting data transmission from AFE2256 emulator", $time);
            // Begin data pattern testing with focus on alignment patterns
            @(posedge fclk_p);         // Wait for frame clock edge
            adc_data_valid = 1'b1;     // Enable data transmission
            set_adc_data(24'h000000);  // Initial pattern (all zeros)
            
            // Starting alignment pattern test sequence
            display_test_section("ALIGNMENT all zeros");
            
            #100;                      // Allow time for stabilization
        end
    endtask
    
    // Configure input delay tap settings for optimal timing
    task configure_delay_settings();
        begin
			// test_bench.cyan_uut.in_delay_data_ce = 1'b0;
			// test_bench.cyan_uut.in_delay_data_inc = 1'b0;
            // // Configure delay taps for signal timing alignment
            // test_bench.cyan_uut.ld_dly_tap = 1'b1;          // Enable loading of tap value
            // test_bench.cyan_uut.in_delay_tap_in = 5'h00;    // Optimal tap value (determined empirically)
            // #100;
            // test_bench.cyan_uut.ld_dly_tap = 1'b0;          // Disable loading (value is latched)
            // #100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_DATA_CE, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_DATA_INC, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_TAP_LD, 16'h00_01);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_TAP_IN, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_DLY_TAP_LD, 16'h00_00);
			#100;
        end
    endtask
    
    // Set alignment mode: auto-detection (0) or manual (1)
    task set_alignment_mode(input logic mode);
        begin
            // Set alignment mode based on input parameter
            if (mode) begin
                // test_bench.cyan_uut.align_to_fclk = 1'b1;   // Manual alignment mode with extra_shift value
				do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_MODE, 16'h00_01);
				#100;
				$display("[%0t ns] Manual alignment mode enabled", $time);
            end else begin
                // test_bench.cyan_uut.align_to_fclk = 1'b0;   // Auto-detection mode using pattern recognition
				do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_MODE, 16'h00_00);
				#100;
				$display("[%0t ns] Auto-detection alignment mode enabled", $time);
            end
        end
    endtask

    // Start automatic bit alignment process in auto-detection mode
    task start_auto_alignment();
        begin
            // Start bit alignment in AUTO mode (align_to_fclk = 0)
            display_test_section("STARTING ALIGNMENT IN AUTO-DETECTION MODE");
            // test_bench.cyan_uut.align_start = 1'b0;        // Reset alignment trigger first
            // #20;
            // test_bench.cyan_uut.align_start = 1'b1;        // Trigger alignment process
            // #200;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_01);
			#100;
        end
    endtask      
    
    // Send alignment pattern and detect bit position
    task detect_and_save_shift_value(input logic [WORD_SIZE-1:0] new_adc_data = 24'hFFF000);
        begin
            // Alignment pattern tests
            display_test_section("ALIGNMENT PATTERN TEST (PATTERN_1: 0xFFF000)");
            
            @(posedge fclk_p);
            adc_data_valid = 1'b0;      // Disable data transmission initially
            $display("[%0t ns] Starting data transmission from AFE2256 emulator", $time);
            // Begin data pattern testing with focus on alignment patterns
            @(posedge fclk_p);         // Wait for frame clock edge
            adc_data_valid = 1'b1;     // Enable data transmission

            // Set expected data for validation
            // expected_data = 24'hFFF000;
            
            // First alignment pattern - critical for align_done signal
            set_data_at_fclk(new_adc_data);  // Send alignment pattern for detection
            
            // test_bench.cyan_uut.align_start = 1'b1;        // Reset alignment trigger
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_01);
			#100;

            // Wait for alignment to complete and capture shift_out value
            while(test_bench.cyan_uut.align_done[0] == 1'b0) begin
				if (test_bench.cyan_uut.align_to_fclk) begin
					// If in manual mode, set the shift value to the detected value
					// test_bench.cyan_uut.extra_shift[0] = test_bench.cyan_uut.shift_out[0];    // Store the detected shift value
					do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_SHIFT_SET_0, {11'd0, test_bench.cyan_uut.shift_out[0]});
				end else begin
					// In auto-detection mode, log the detected shift value
					$display("[%0t ns] Detected shift value: %0d", $time, test_bench.cyan_uut.shift_out[0]);
					$display("[%0t ns] Detected extra value: %0d", $time, test_bench.cyan_uut.extra_shift[0]);
				end
				@(posedge fclk_p); // Wait for alignment done signal
			end

            #100; // Allow time for alignment to stabilize

			#200; // Allow time for shift value to be applied
            // test_bench.cyan_uut.align_start = 1'b0;        // Reset alignment trigger
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_00);
			#100; 

        end
    endtask
    
    // Switch from auto to manual mode using detected shift value
    task switch_to_manual_mode();
        begin
            // Switch to manual alignment mode with the detected shift value
            display_test_section("SWITCHING TO MANUAL ALIGNMENT MODE");
            // test_bench.cyan_uut.align_start = 1'b0;         // First deassert alignment trigger
            // #200;                       // Wait for signal to stabilize
            // test_bench.cyan_uut.align_start = 1'b1;         // Restart alignment with new settings
            // #200;                       // Allow time for the new setting to take effect
            do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_00);
			#100;
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_01);
			#100;

            @(posedge fclk_p);
            adc_data_valid = 1'b0;      // Disable data transmission initially
            $display("[%0t ns] Starting data transmission from AFE2256 emulator", $time);
            // Begin data pattern testing with focus on alignment patterns
            @(posedge fclk_p);         // Wait for frame clock edge
            adc_data_valid = 1'b1;     // Enable data transmission

            // Verify manual mode with second pattern and set expected value
            expected_data = 24'hFF0000;
            set_data_at_fclk(expected_data);   // Second alignment pattern (PATTERN_2)

            // Wait for alignment to complete and verify shift value
            wait(test_bench.cyan_uut.align_done[0]);
            #200; // Allow time for alignment to stabilize
            // Log confirmed shift value for manual mode
            $display("[%0t ns] Manual mode confirmed with shift value: %0d", $time, test_bench.cyan_uut.shift_out[0]);
            test_bench.cyan_uut.extra_shift[0] = test_bench.cyan_uut.shift_out[0];    // Store the detected shift value            wait(fclk_p); // Wait for frame clock to stabilize
            // test_bench.cyan_uut.align_start = ({12{1'b0}});        // Reset alignment trigger
			do_mspi_write(2'b10 , `ADDR_TI_ROIC_DESER_ALIGN_START, 16'h00_00);
			#100; // Allow time for alignment to stabilize

            wait(fclk_p); // Wait for frame clock to stabilize
            
        end
    endtask
    
    // Test data valid signal toggling and pattern transmission with continuous streaming
    task test_data_valid_toggling();
        // Define continuous test patterns array
        logic [WORD_SIZE-1:0] test_patterns[];
        begin
            
            @(posedge fclk_p);
            // Initialize test patterns array with test values
            test_patterns = new[8];
            test_patterns[0] = 24'hFFF0B8;  // First alignment pattern
            test_patterns[1] = 24'hFF00B8;  // Second alignment pattern
            test_patterns[2] = 24'h1234B8;  // Random data pattern 1
            test_patterns[3] = 24'hABCDB8;  // Random data pattern 2
            test_patterns[4] = 24'hFFF000;  // First alignment pattern
            test_patterns[5] = 24'hFF0000;  // Second alignment pattern
            test_patterns[6] = 24'h123456;  // Random data pattern 1
            test_patterns[7] = 24'hABCDEF;  // Random data pattern 2
            
            // Queue each pattern twice to ensure we can detect repeated patterns
            repeat(3) begin  // Queue patterns 3 times for verification
                foreach (test_patterns[i]) begin
                    queue_expected_data(test_patterns[i]);
                end
            end
            
            // Start verification process in the background
            fork
                // Process 1: Send continuous data stream (repeat patterns 5 times)
                continuous_data_stream(test_patterns, 0, 1);  // 5 cycles delay, 5 repetitions
                
            join_any  // Only wait for one process to complete
              // Allow the verification to continue a bit longer to check for changes
            repeat(3) @(posedge fclk_p);
            $display("[%0t ns] Data valid toggling test completed", $time);
        end
    endtask
    
    // Read and apply data from a specified data file with continuous processing
    task read_and_apply_roic_data_file(input string file_path = "", input int repeat_count = 1);
        integer file, r, data_count, max_samples;
        logic [WORD_SIZE-1:0] file_data;
        logic [WORD_SIZE-1:0] data_array[];
        string path_to_use;
        begin
            // Determine which path to use
            if (file_path == "") begin
                path_to_use = roic_data_file_path; // Use global path setting
                $display("[%0t ns] Using default ROIC data file path: %s", $time, path_to_use);
            end else begin
                path_to_use = file_path; // Use explicitly provided path
                $display("[%0t ns] Using provided ROIC data file path: %s", $time, path_to_use);
            end
            
            // Open the specified file for reading
            file = $fopen(path_to_use, "r");
            if (file == 0) begin
                $display("Error: Could not open file: %s", path_to_use);
                test_fail_count++;
                $finish;
            end
            
            $display("[%0t ns] Successfully opened file: %s", $time, path_to_use);
            
            // First pass: Count number of valid data lines in file
            data_count = 0;
            
            while (!$feof(file)) begin
                r = $fscanf(file, "%h\n", file_data);
                if (r == 1) data_count++;
            end
            
            // Reset file pointer to beginning
            $rewind(file);
            
            $display("[%0t ns] Found %0d data values in file", $time, data_count);
            
            // Limit number of samples if file is too large
            max_samples = (data_count > 1000) ? 1000 : data_count;
            
            // Allocate array for continuous data streaming
            data_array = new[max_samples];
            
            // Second pass: Load data into array
            data_count = 0;
            display_test_section("TESTING CONTINUOUS DATA STREAM FROM FILE");
            
            while (!$feof(file) && data_count < max_samples) begin
                r = $fscanf(file, "%h\n", file_data);
                if (r == 1) begin
                    data_array[data_count] = file_data;
                    // Queue for verification
                    queue_expected_data(file_data);
                    data_count++;
                end
            end
            
            // Close file after reading all data
            $fclose(file);
              // Start continuous data streaming and verification in parallel
            fork
                // Process 1: Send continuous data stream
                begin
					@(posedge fclk_p);
                    continuous_data_stream(data_array, 0, repeat_count);  // Small delay for stability, repeat twice
                end
                
            join_any  // Only wait for one process to complete
            
            
            $display("[%0t ns] Finished processing continuous data stream from file: %s", 
                     $time, path_to_use);
        end
    endtask

    //--------------------------------------------------------------------------
    // Test Helper Tasks
    //--------------------------------------------------------------------------
    // Set ADC data pattern with logging
    task automatic set_adc_data(input logic [WORD_SIZE-1:0] new_adc_data);
        begin
            adc_data = new_adc_data;
            // $display("[%0t ns] Setting ADC data to: 0x%h", $time, new_adc_data);
        end
    endtask

      // Task to wait for frame clock and set data
    task automatic set_data_at_fclk(input logic [WORD_SIZE-1:0] data_pattern);
        begin
            set_adc_data(data_pattern);
            // $display("[%0t ns] SET_DATA_AT_FCLK: Updated data to 0x%h on FCLK edge", 
            //          $time, data_pattern);
            @(posedge fclk_p);
        end
    endtask

      // Task to continuously set data at each frame clock for verification
    task automatic continuous_data_stream(input logic [WORD_SIZE-1:0] data_array[], input int delay_cycles = 0, input int repeat_count = 1);
        begin
            $display("[%0t ns] Starting continuous data stream with %0d values, repeating %0d times", 
                    $time, data_array.size(), repeat_count);
            
            for (int r = 0; r < repeat_count; r++) begin
                foreach (data_array[i]) begin
                    set_data_at_fclk(data_array[i]);
                    // Additional delay between data points if specified
                    if (delay_cycles > 0) begin
                        repeat(delay_cycles) @(posedge dclk_sim);
                    end
                end
                
                // $display("[%0t ns] Finished setting continuous data stream iteration %0d of %0d", 
//                        $time, r+1, repeat_count);
            end
        end
    endtask
    
    // Queue for expected data values for verification
    logic [WORD_SIZE-1:0] expected_data_queue[$];
    
    // Add expected data to queue for later verification
    task automatic queue_expected_data(input logic [WORD_SIZE-1:0] expected);
        begin
            expected_data_queue.push_back(expected);
            // $display("[%0t ns] Queued expected data: 0x%h (Queue size: %0d)", 
            //         $time, expected, expected_data_queue.size());
        end
    endtask

    
    // Task to display test section header
    task automatic display_test_section(input string section_name);
        begin
            $display("\n=== %s ===", section_name);
        end
    endtask
    

	// Sync counter to track how many times sync has occurred
	int sync_counter = 0;
	
	initial begin
		// Infinite loop to continuously monitor sync signal and react to it
		forever begin
			// Wait for sync start signal to be asserted
			// wait(test_bench.cyan_uut.FSM_read_index);
			wait(test_bench.cyan_uut.align_done[0]);
			sync_counter++;
			$display($time, " << Test STR sync pattern Start - Detected sync signal #%0d >>", sync_counter);
			
			// // Wait for sync signal to be deasserted before detecting next assertion
			// @(negedge test_bench.cyan_uut.gen_sync_start);
			// $display($time, " << Sync signal #%0d deasserted - Ready for next sync detection >>", sync_counter);
			
			wait(test_bench.cyan_uut.ti_roic_sync);	
			
			// Read and apply data from roic_sim_data.txt file with explicit file path
			read_and_apply_roic_data_file(roic_256_data_file_path, 100000);
			$display($time, " << 1 line of roic data file processed Completed #%0d >>", sync_counter);
			
		end
	end

    // Helper function to pack LUT entry data
    function automatic logic [51:0] pack_lut_entry(
        input logic [1:0] iterate_index_in,
		input logic [0:0] iterate_in,
		input logic [0:0] panel_stable_in,
		input logic [0:0] csi_mask_in,
		input logic [0:0] stv_mask_in,
        input logic [3:0] next_state_in,
        input logic [15:0] repeat_count_in,
        input logic [15:0] data_length_in,
        input logic [0:0] sof_in,
        input logic [0:0] eof_in,
        input logic [7:0] next_address_in
    );
        pack_lut_entry = 
                        (iterate_index_in      << 50) |
						(iterate_in      << 49) |
						(panel_stable_in << 48) |
						(csi_mask_in     << 47) |
						(stv_mask_in     << 46) |
                        (sof_in          << 45) |
                        (eof_in          << 44) |
                        (next_state_in   << 40) |
                        (next_address_in << 32) |
                        (repeat_count_in << 16) |
                        (data_length_in  << 0);
        $display("Packed LUT Entry: %h", pack_lut_entry);
        return pack_lut_entry;

    endfunction

endmodule

