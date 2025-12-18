// ---------------------------------------------------------------------------------
//   Title      :  Parameter Define File
//              :
//   Purpose    :  Global parameter value setting
//              :
//   Designer   :  drake.lee  (holee9@gmail.com)
//              :
//   Company    :  H&abyz Inc.
//              :
// ---------------------------------------------------------------------------------
//   Modification history :
//
//   version:   |   mod. date:  |   changes made:
//      v0.0        01/10/2024      initial release
//		v0.1		03/20/2024		RAON project release
//		v0.2		06/20/2024		BLUE project release
//
// ---------------------------------------------------------------------------------
//  Descripitions   :
//  BLUE platform project 
//  Single readout (ROIC ADI) 
//  CSI2 interface 2pixel , 4 lane
//
// ---------------------------------------------------------------------------------

//  `define TB_SIM

//----------------------------------------
//----------------------------------------
//--------------------------------------------------------------------------------
// Initialization 
//--------------------------------------------------------------------------------

`ifdef TB_SIM
	`define INIT_DELAY					25'd25  // 25 x 40ns, 1us
	`define MORE_DELAY					25'd500	// 500 x 40ns, 20us
`else
	// `define INIT_DELAY					25'd2500000 // 2,500,000 x 40ns, 100ms
	// `define MORE_DELAY					25'd2500000 // 2,500,000 x 40ns, 100ms
	`define INIT_DELAY					25'd2500000 // 2,500,000 x 40ns, 100ms
	`define MORE_DELAY					25'd2500000 // 2,500,000 x 40ns, 100ms
`endif

//--------------------------------------------------------------------------------
// Register Map
//--------------------------------------------------------------------------------
// D=44, G=47, M=4D, N=4E, S=53, V=56
// D : Dental
// 	- M : CT & Pano Multi
// 	- C : Cephalo
// N : NDT & EOD
//  - S : Static
//  - M : Multi function ( Multi frame )
// S : Security
//  - S : Static
//  - M : Multi function
// G : General Purpose (Medical or Vet)
//  - V : Vet
//  - S : Static
//  - M : Multi function
// 30=0, 31=1, 32=2, 33=3, 34=4, 35=5, 36=6, 37=7, 38=8, 39=9
// ROIC Band : TI = 54 49 / AD = 41 44

`define PURPOSE							16'h4753	// GS
`define SIZE_1							16'h3137	// 17
`define SIZE_2							16'h3137	// 17
`define MAJOR_REV						16'h3031	// 01
`define MINOR_REV						16'h3030	// 00
`define ROIC_VENDOR						16'h5449	// TI

//----------------------------------------
//----------------------------------------

`ifdef TB_SIM
	`define FULL_CYCLE_WIDTH			24'd25
`else
	`define FULL_CYCLE_WIDTH			24'd2500000 // 100ms when 25MHz, 2,500,000
// rev6
	// `define FULL_CYCLE_WIDTH			24'h4C4B40 // 100ms when 50MHz, 5000000
`endif

`ifdef TB_SIM
	`define MIN_UNIT			24'd250
`else
	`define MIN_UNIT			24'd250000 // 10ms when 25MHz, 250,000
`endif

`define AED_READ_ADDED_LINES			16'h5

//`define MAX_ADDR                        16'hFFFF
`define MAX_ADDR                        16'd512

//----------------------------------------
// Register Address
//----------------------------------------
//i2c
`define ADDR_GATE_GPIO_REG              16'h0099
/////
`define ADDR_SYS_CMD_REG				16'h0001
`define ADDR_OP_MODE_REG				16'h0002
`define ADDR_SET_GATE					16'h0003
`define ADDR_GATE_SIZE					16'h0004
`define ADDR_PWR_OFF_DWN				16'h0005
`define ADDR_READOUT_COUNT				16'h0006
`define ADDR_EXPOSE_SIZE				16'h0010
`define ADDR_BACK_BIAS_SIZE				16'h0011
`define ADDR_IMAGE_HEIGHT				16'h0012
`define ADDR_CYCLE_WIDTH_FLUSH			16'h0013
`define ADDR_CYCLE_WIDTH_AED			16'h0014
`define ADDR_CYCLE_WIDTH_READ			16'h0015
`define ADDR_REPEAT_BACK_BIAS			16'h0016
`define ADDR_REPEAT_FLUSH				16'h0017
`define ADDR_SATURATION_FLUSH_REPEAT	16'h0018
`define ADDR_EXP_DELAY					16'h0019
`define ADDR_READY_DELAY				16'h001A
`define ADDR_PRE_DELAY					16'h001B
`define ADDR_POST_DELAY					16'h001C
`define ADDR_FRAME_COUNT				16'h001E
`define ADDR_UP_BACK_BIAS				16'h0020
`define ADDR_DN_BACK_BIAS				16'h0021
`define ADDR_UP_BACK_BIAS_OPR			16'h0022
`define ADDR_DN_BACK_BIAS_OPR			16'h0023
`define ADDR_UP_GATE_STV1_READ			16'h0024
`define ADDR_DN_GATE_STV1_READ			16'h0025
`define ADDR_UP_GATE_STV2_READ			16'h0026
`define ADDR_DN_GATE_STV2_READ			16'h0027
`define ADDR_UP_GATE_CPV1_READ			16'h0028
`define ADDR_DN_GATE_CPV1_READ			16'h0029
`define ADDR_UP_GATE_CPV2_READ			16'h002A
`define ADDR_DN_GATE_CPV2_READ			16'h002B
`define ADDR_DN_GATE_OE1_READ			16'h002C
`define ADDR_UP_GATE_OE1_READ			16'h002D
`define ADDR_DN_GATE_OE2_READ			16'h002E
`define ADDR_UP_GATE_OE2_READ			16'h002F
`define ADDR_DN_GATE_XAO_READ			16'h0030
`define ADDR_UP_GATE_XAO_READ			16'h0031
`define ADDR_UP_GATE_STV1_AED			16'h0032
`define ADDR_DN_GATE_STV1_AED			16'h0033
`define ADDR_UP_GATE_STV2_AED			16'h0034
`define ADDR_DN_GATE_STV2_AED			16'h0035
`define ADDR_UP_GATE_CPV1_AED			16'h0036
`define ADDR_DN_GATE_CPV1_AED			16'h0037
`define ADDR_UP_GATE_CPV2_AED			16'h0038
`define ADDR_DN_GATE_CPV2_AED			16'h0039
`define ADDR_DN_GATE_OE1_AED			16'h003A
`define ADDR_UP_GATE_OE1_AED			16'h003B
`define ADDR_DN_GATE_OE2_AED			16'h003C
`define ADDR_UP_GATE_OE2_AED			16'h003D
`define ADDR_DN_GATE_XAO_AED			16'h003E
`define ADDR_UP_GATE_XAO_AED			16'h003F
`define ADDR_UP_GATE_STV1_FLUSH			16'h0040
`define ADDR_DN_GATE_STV1_FLUSH			16'h0041
`define ADDR_UP_GATE_STV2_FLUSH			16'h0042
`define ADDR_DN_GATE_STV2_FLUSH			16'h0043
`define ADDR_UP_GATE_CPV1_FLUSH			16'h0044
`define ADDR_DN_GATE_CPV1_FLUSH			16'h0045
`define ADDR_UP_GATE_CPV2_FLUSH			16'h0046
`define ADDR_DN_GATE_CPV2_FLUSH			16'h0047
`define ADDR_DN_GATE_OE1_FLUSH			16'h0048
`define ADDR_UP_GATE_OE1_FLUSH			16'h0049
`define ADDR_DN_GATE_OE2_FLUSH			16'h004A
`define ADDR_UP_GATE_OE2_FLUSH			16'h004B
// `define ADDR_DN_GATE_XAO_FLUSH			16'h004C
// `define ADDR_UP_GATE_XAO_FLUSH			16'h004D
`define ADDR_UP_ROIC_SYNC				16'h0050
`define ADDR_UP_ROIC_ACLK_0_READ		16'h0051
`define ADDR_UP_ROIC_ACLK_1_READ		16'h0052
`define ADDR_UP_ROIC_ACLK_2_READ		16'h0053
`define ADDR_UP_ROIC_ACLK_3_READ		16'h0054
`define ADDR_UP_ROIC_ACLK_4_READ		16'h0055
`define ADDR_UP_ROIC_ACLK_5_READ		16'h0056
`define ADDR_UP_ROIC_ACLK_6_READ		16'h0057
`define ADDR_UP_ROIC_ACLK_7_READ		16'h0058
`define ADDR_UP_ROIC_ACLK_8_READ		16'h0059
`define ADDR_UP_ROIC_ACLK_9_READ		16'h005A
`define ADDR_UP_ROIC_ACLK_10_READ		16'h005B
`define ADDR_UP_ROIC_ACLK_0_AED			16'h005C
`define ADDR_UP_ROIC_ACLK_1_AED			16'h005D
`define ADDR_UP_ROIC_ACLK_2_AED			16'h005E
`define ADDR_UP_ROIC_ACLK_3_AED			16'h005F
`define ADDR_UP_ROIC_ACLK_4_AED			16'h0060
`define ADDR_UP_ROIC_ACLK_5_AED			16'h0061
`define ADDR_UP_ROIC_ACLK_6_AED			16'h0062
`define ADDR_UP_ROIC_ACLK_7_AED			16'h0063
`define ADDR_UP_ROIC_ACLK_8_AED			16'h0064
`define ADDR_UP_ROIC_ACLK_9_AED			16'h0065
`define ADDR_UP_ROIC_ACLK_10_AED		16'h0066
`define ADDR_UP_ROIC_ACLK_0_FLUSH		16'h0067
`define ADDR_UP_ROIC_ACLK_1_FLUSH		16'h0068
`define ADDR_UP_ROIC_ACLK_2_FLUSH		16'h0069
`define ADDR_UP_ROIC_ACLK_3_FLUSH		16'h006A
`define ADDR_UP_ROIC_ACLK_4_FLUSH		16'h006B
`define ADDR_UP_ROIC_ACLK_5_FLUSH		16'h006C
`define ADDR_UP_ROIC_ACLK_6_FLUSH		16'h006D
`define ADDR_UP_ROIC_ACLK_7_FLUSH		16'h006E
`define ADDR_UP_ROIC_ACLK_8_FLUSH		16'h006F
`define ADDR_UP_ROIC_ACLK_9_FLUSH		16'h0070
`define ADDR_UP_ROIC_ACLK_10_FLUSH		16'h0071
`define ADDR_ROIC_REG_SET_0				16'h0072
`define ADDR_ROIC_REG_SET_1				16'h0073
`define ADDR_ROIC_REG_SET_1_dual		16'h0173
`define ADDR_ROIC_REG_SET_2				16'h0074
`define ADDR_ROIC_REG_SET_3				16'h0075
`define ADDR_ROIC_REG_SET_4				16'h0076
`define ADDR_ROIC_REG_SET_5				16'h0077
`define ADDR_ROIC_REG_SET_6				16'h0078
`define ADDR_ROIC_REG_SET_7				16'h0079
`define ADDR_ROIC_REG_SET_8				16'h007A
`define ADDR_ROIC_REG_SET_9				16'h007B
`define ADDR_ROIC_REG_SET_10			16'h007C
`define ADDR_ROIC_REG_SET_11			16'h007D
`define ADDR_ROIC_REG_SET_12			16'h007E
`define ADDR_ROIC_REG_SET_13			16'h007F
`define ADDR_ROIC_REG_SET_14			16'h0080
`define ADDR_ROIC_REG_SET_15			16'h0081
`define ADDR_ROIC_TEMPERATURE			16'h0082
`define ADDR_ROIC_BURST_CYCLE			16'h0090
`define ADDR_START_ROIC_BURST_CLK		16'h0091
`define ADDR_END_ROIC_BURST_CLK			16'h0092
`define ADDR_SEL_ROIC_REG				16'h00A0
`define ADDR_DN_AED_GATE_XAO_0			16'h00A2
`define ADDR_DN_AED_GATE_XAO_1			16'h00A3
`define ADDR_DN_AED_GATE_XAO_2			16'h00A4
`define ADDR_DN_AED_GATE_XAO_3			16'h00A5
`define ADDR_DN_AED_GATE_XAO_4			16'h00A6
`define ADDR_DN_AED_GATE_XAO_5			16'h00A7
`define ADDR_UP_AED_GATE_XAO_0			16'h00A8
`define ADDR_UP_AED_GATE_XAO_1			16'h00A9
`define ADDR_UP_AED_GATE_XAO_2			16'h00AA
`define ADDR_UP_AED_GATE_XAO_3			16'h00AB
`define ADDR_UP_AED_GATE_XAO_4			16'h00AC
`define ADDR_UP_AED_GATE_XAO_5			16'h00AD
`define ADDR_READY_AED_READ				16'h00B0
`define ADDR_AED_TH						16'h00B1
`define ADDR_SEL_AED_ROIC				16'h00B2
`define ADDR_NUM_TRIGGER				16'h00B3
`define ADDR_SEL_AED_TEST_ROIC			16'h00B4
`define ADDR_AED_CMD					16'h00B5
`define ADDR_NEGA_AED_TH				16'h00B6
`define ADDR_POSI_AED_TH				16'h00B7
`define ADDR_AED_DARK_DELAY				16'h00B8
`define ADDR_TEST_REG_A					16'h00BA
`define ADDR_TEST_REG_B					16'h00BB
`define ADDR_TEST_REG_C					16'h00BC
`define ADDR_TEST_REG_D					16'h00BD
`define ADDR_AED_DETECT_LINE_0			16'h00C0
`define ADDR_AED_DETECT_LINE_1			16'h00C1
`define ADDR_AED_DETECT_LINE_2			16'h00C2
`define ADDR_AED_DETECT_LINE_3			16'h00C3
`define ADDR_AED_DETECT_LINE_4			16'h00C4
`define ADDR_AED_DETECT_LINE_5			16'h00C5
`define ADDR_MAX_V_COUNT				16'h00D0
`define ADDR_MAX_H_COUNT				16'h00D1
`define ADDR_CSI2_WORD_COUNT			16'h00D2
//
`define ADDR_FPGA_VER_H					16'h00DF
`define ADDR_FPGA_VER_L					16'h00DE
`define ADDR_ROIC_VENDOR				16'h00DD
`define ADDR_IO_DELAY_TAB				16'h00DC
`define ADDR_STATE_LED_CTR				16'h00DD

//
`define ADDR_PURPOSE					16'h00F0
`define ADDR_SIZE_1						16'h00F1
`define ADDR_SIZE_2						16'h00F2
`define ADDR_MAJOR_REV					16'h00F3
`define ADDR_MINOR_REV					16'h00F4
`define ADDR_TEST_REG_0					16'h00F5
`define ADDR_TEST_REG_1					16'h00F6
`define ADDR_TEST_REG_2					16'h00F7
`define ADDR_TEST_REG_3					16'h00F8
`define ADDR_TEST_REG_4					16'h00F9
`define ADDR_TEST_REG_5					16'h00FA
`define ADDR_TEST_REG_6					16'h00FB
`define ADDR_TEST_REG_7					16'h00FC
`define ADDR_TEST_REG_8					16'h00FD
`define ADDR_TEST_REG_9					16'h00FE
`define ADDR_FSM_REG					16'h00FF

// TI ROIC Register Address
`define ADDR_TI_ROIC_REG_00				16'h0100
`define ADDR_TI_ROIC_REG_10				16'h0101
`define ADDR_TI_ROIC_REG_11				16'h0102
`define ADDR_TI_ROIC_REG_12				16'h0103
`define ADDR_TI_ROIC_REG_13				16'h0104
`define ADDR_TI_ROIC_REG_16				16'h0105
`define ADDR_TI_ROIC_REG_18				16'h0106
`define ADDR_TI_ROIC_REG_2C				16'h0107
`define ADDR_TI_ROIC_REG_30				16'h0108
`define ADDR_TI_ROIC_REG_31				16'h0109
`define ADDR_TI_ROIC_REG_32				16'h010A
`define ADDR_TI_ROIC_REG_33				16'h010B
`define ADDR_TI_ROIC_REG_40				16'h010C
`define ADDR_TI_ROIC_REG_42				16'h010D
`define ADDR_TI_ROIC_REG_43				16'h010E
`define ADDR_TI_ROIC_REG_46				16'h010F
`define ADDR_TI_ROIC_REG_47				16'h0110
`define ADDR_TI_ROIC_REG_4A				16'h0111
`define ADDR_TI_ROIC_REG_4B				16'h0112
`define ADDR_TI_ROIC_REG_50				16'h0113
`define ADDR_TI_ROIC_REG_51				16'h0114
`define ADDR_TI_ROIC_REG_52				16'h0115
`define ADDR_TI_ROIC_REG_53				16'h0116
`define ADDR_TI_ROIC_REG_54				16'h0117
`define ADDR_TI_ROIC_REG_55				16'h0118
`define ADDR_TI_ROIC_REG_5A				16'h0119
`define ADDR_TI_ROIC_REG_5C				16'h011A
`define ADDR_TI_ROIC_REG_5D				16'h011B
`define ADDR_TI_ROIC_REG_5E				16'h011C
`define ADDR_TI_ROIC_REG_61				16'h011D
// `define ADDR_TI_ROIC_REG_			16'h011E
// `define ADDR_TI_ROIC_REG_			16'h011F

`define ADDR_TI_ROIC_REG_ADDR			16'h0120
`define ADDR_TI_ROIC_REG_DATA			16'h0121
`define ADDR_TI_ROIC_SYNC				16'h0122
`define ADDR_TI_ROIC_TP_SEL				16'h0123
`define ADDR_TI_ROIC_STR				16'h0124

`define ADDR_TI_ROIC_DESER_RESET		16'h0130
`define ADDR_TI_ROIC_DESER_DLY_TAP_LD	16'h0131
`define ADDR_TI_ROIC_DESER_DLY_TAP_IN	16'h0132
`define ADDR_TI_ROIC_DESER_DLY_DATA_CE	16'h0133
`define ADDR_TI_ROIC_DESER_DLY_DATA_INC	16'h0134

`define ADDR_TI_ROIC_DESER_ALIGN_MODE	16'h0135
`define ADDR_TI_ROIC_DESER_ALIGN_START	16'h0136
`define ADDR_TI_ROIC_DESER_ALIGN_DONE	16'h0137

`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_0	16'h0140
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_1	16'h0141
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_2	16'h0142
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_3	16'h0143
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_4	16'h0144
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_5	16'h0145
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_6	16'h0146
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_7	16'h0147
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_8	16'h0148
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_9	16'h0149
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_10	16'h014A
`define ADDR_TI_ROIC_DESER_ALIGN_SHIFT_11	16'h014B

`define ADDR_TI_ROIC_DESER_SHIFT_SET_0		16'h0150
`define ADDR_TI_ROIC_DESER_SHIFT_SET_1		16'h0151
`define ADDR_TI_ROIC_DESER_SHIFT_SET_2		16'h0152
`define ADDR_TI_ROIC_DESER_SHIFT_SET_3		16'h0153
`define ADDR_TI_ROIC_DESER_SHIFT_SET_4		16'h0154
`define ADDR_TI_ROIC_DESER_SHIFT_SET_5		16'h0155
`define ADDR_TI_ROIC_DESER_SHIFT_SET_6		16'h0156
`define ADDR_TI_ROIC_DESER_SHIFT_SET_7		16'h0157
`define ADDR_TI_ROIC_DESER_SHIFT_SET_8		16'h0158
`define ADDR_TI_ROIC_DESER_SHIFT_SET_9		16'h0159
`define ADDR_TI_ROIC_DESER_SHIFT_SET_10		16'h015A
`define ADDR_TI_ROIC_DESER_SHIFT_SET_11		16'h015B

`define DEF_TI_ROIC_REG_00				16'h0000
`define DEF_TI_ROIC_REG_10				16'h0800 	// 16'h0BC0 skew pattern
`define DEF_TI_ROIC_REG_11				16'h0430
`define DEF_TI_ROIC_REG_12				16'h0400
`define DEF_TI_ROIC_REG_13				16'h0000
`define DEF_TI_ROIC_REG_16				16'h00C0
`define DEF_TI_ROIC_REG_18				16'h0001
`define DEF_TI_ROIC_REG_2C				16'h0000
`define DEF_TI_ROIC_REG_30				16'h0000
// `define DEF_TI_ROIC_REG_31				16'h0000
// `define DEF_TI_ROIC_REG_32				16'h0000
// `define DEF_TI_ROIC_REG_33				16'h0000
`define DEF_TI_ROIC_REG_40				16'h0105
`define DEF_TI_ROIC_REG_42				16'h0682
`define DEF_TI_ROIC_REG_43				16'h83FF
`define DEF_TI_ROIC_REG_46				16'h0D83
`define DEF_TI_ROIC_REG_47				16'h8B00
`define DEF_TI_ROIC_REG_4A				16'h0685
`define DEF_TI_ROIC_REG_4B				16'h0000
`define DEF_TI_ROIC_REG_50				16'h8300
`define DEF_TI_ROIC_REG_51				16'h8300
`define DEF_TI_ROIC_REG_52				16'h8300
`define DEF_TI_ROIC_REG_53				16'h8300
`define DEF_TI_ROIC_REG_54				16'h8300
`define DEF_TI_ROIC_REG_55				16'h8300
`define DEF_TI_ROIC_REG_5A				16'h0040
`define DEF_TI_ROIC_REG_5C				16'h8000
`define DEF_TI_ROIC_REG_5D				16'h0000
`define DEF_TI_ROIC_REG_5E				16'h0000
`define DEF_TI_ROIC_REG_61				16'h0400

`define DEF_IRST_ADDR					8'h40
`define DEF_SHR_ADDR					8'h42
`define DEF_SHS_ADDR					8'h43
`define DEF_LPF1_ADDR					8'h46
`define DEF_LPF2_ADDR					8'h47
`define DEF_TDEF_ADDR					8'h4A
`define DEF_GATE_ADDR					8'h4B
`define DEF_SM0_ADDR					8'h50
`define DEF_SM1_ADDR					8'h51
`define DEF_SM2_ADDR					8'h52
`define DEF_SM3_ADDR					8'h53
`define DEF_SM4_ADDR					8'h54
`define DEF_SM5_ADDR					8'h55


//----------------------------------------
// Register Default Value
//----------------------------------------
//i2c
`define DEF_GATE_GPIO_REG               16'h0000        
/////
`define DEF_SYS_CMD_REG					16'h0001
`define DEF_OP_MODE_REG					16'h0002 
// `define DEF_SET_GATE					16'hC908
`define DEF_SET_GATE					16'hC83B
`define DEF_GATE_SIZE					16'h0200 // 'd512
`define DEF_PWR_OFF_DWN					16'h0000

`define DEF_READOUT_COUNT				16'd0
// rev6
// `define DEF_EXPOSE_SIZE					16'h0064
`define DEF_EXPOSE_SIZE					16'd500	// h01F4
`define DEF_BACK_BIAS_SIZE				16'd45000	// h2FBC // 'd12220 

`define DEF_IMAGE_HEIGHT				16'd3072
// `define DEF_MAX_V_COUNT					16'd768		// CSI2 pixel 4 mode
`define DEF_MAX_V_COUNT					16'd1536	// CSI2 pixel 2 mode
`define DEF_MAX_H_COUNT					16'd256
// `define DEF_CSI2_WORD_COUNT				16'd2048	// CSI2 pixel 4 mode
`define DEF_CSI2_WORD_COUNT				16'd1024	// CSI2 pixel 2 mode

`define DEF_CYCLE_WIDTH_FLUSH			16'd100    // h0064
`define DEF_CYCLE_WIDTH_AED				16'd3660   // h0E4C 
`define DEF_CYCLE_WIDTH_READ			16'd4160   // h1040

`define DEF_REPEAT_BACK_BIAS			16'd1        // h0001
`define DEF_REPEAT_FLUSH				16'd2        // h0004
`define DEF_SATURATION_FLUSH_REPEAT		16'd2        // 
`define DEF_EXP_DELAY					16'd100      // h0002
`define DEF_READY_DELAY					16'd5       // 
`define DEF_PRE_DELAY					16'd7
`define DEF_POST_DELAY					16'd8
//
`define DEF_UP_BACK_BIAS				16'd2	// h0002
`define DEF_DN_BACK_BIAS				16'd23074	// h1DDE
`define DEF_UP_BACK_BIAS_OPR			16'd20000	// h11DE
`define DEF_DN_BACK_BIAS_OPR			16'd23074	// h1DDE
//
`define DEF_UP_GATE_STV1_READ			16'h003C
`define DEF_DN_GATE_STV1_READ			16'h0168
`define DEF_UP_GATE_STV2_READ			16'h003C
`define DEF_DN_GATE_STV2_READ			16'h0168
//
`define DEF_UP_GATE_CPV1_READ			16'h006E
`define DEF_DN_GATE_CPV1_READ			16'h01E5
`define DEF_UP_GATE_CPV2_READ			16'h006E
`define DEF_DN_GATE_CPV2_READ			16'h01E5
//
`define DEF_DN_GATE_OE1_READ			16'd990	// h03E0
`define DEF_UP_GATE_OE1_READ			16'd2490	// h0C94
`define DEF_DN_GATE_OE2_READ			16'd990	// h03E0
`define DEF_UP_GATE_OE2_READ			16'd2490	// h0C94
//
`define DEF_UP_GATE_STV1_AED			16'h003C
`define DEF_DN_GATE_STV1_AED			16'h0168
`define DEF_UP_GATE_STV2_AED			16'h003C
`define DEF_DN_GATE_STV2_AED			16'h0168
//
`define DEF_UP_GATE_CPV1_AED			16'h006E
`define DEF_DN_GATE_CPV1_AED			16'h01E5
`define DEF_UP_GATE_CPV2_AED			16'h006E
`define DEF_DN_GATE_CPV2_AED			16'h01E5
//
`define DEF_UP_GATE_STV1_FLUSH			16'h0002
`define DEF_DN_GATE_STV1_FLUSH			16'h0025
`define DEF_UP_GATE_STV2_FLUSH			16'h0002
`define DEF_DN_GATE_STV2_FLUSH			16'h0025
//
`define DEF_UP_GATE_CPV1_FLUSH			16'd10	// h000A
`define DEF_DN_GATE_CPV1_FLUSH			16'd40	// h0028
`define DEF_UP_GATE_CPV2_FLUSH			16'd10	// h000A
`define DEF_DN_GATE_CPV2_FLUSH			16'd40	// h0028
//
`define DEF_DN_GATE_OE1_FLUSH			16'd15	// h000F
`define DEF_UP_GATE_OE1_FLUSH			16'd180	// h00B4
`define DEF_DN_GATE_OE2_FLUSH			16'd15	// h000F
`define DEF_UP_GATE_OE2_FLUSH			16'd180	// h00B4

`define DEF_UP_ROIC_SYNC				16'h0002

`ifdef TB_SIM
	`define DEF_UP_ROIC_ACLK_0_READ		16'h003C // 'd60
	`define DEF_UP_ROIC_ACLK_1_READ		16'h006E // 'd110
	`define DEF_UP_ROIC_ACLK_2_READ		16'h0168 // 'd360
	`define DEF_UP_ROIC_ACLK_3_READ		16'h01E5 // 'd485
	`define DEF_UP_ROIC_ACLK_4_READ		16'h03D9 // 'd985
	`define DEF_UP_ROIC_ACLK_5_READ		16'h09C4 // 'd2500
	`define DEF_UP_ROIC_ACLK_6_READ		16'h09F6 // 'd2550
	`define DEF_UP_ROIC_ACLK_7_READ		16'h0A46 // 'd2630
	`define DEF_UP_ROIC_ACLK_8_READ		16'h0FA5 // 'd4005
	`define DEF_UP_ROIC_ACLK_9_READ		16'h0FD7 // 'd4055
	`define DEF_UP_ROIC_ACLK_10_READ	16'h0FDC // 'd4060
	// `define DEF_UP_ROIC_ACLK_8_READ		16'h0DB1 // 'd3505
	// `define DEF_UP_ROIC_ACLK_9_READ		16'h0DE3 // 'd3555
	// `define DEF_UP_ROIC_ACLK_10_READ	16'h0DE8 // 'd3560
	//
	`define DEF_UP_ROIC_ACLK_0_AED		16'h003C // 'd60
	`define DEF_UP_ROIC_ACLK_1_AED		16'h006E // 'd110
	`define DEF_UP_ROIC_ACLK_2_AED		16'h0168 // 'd360
	`define DEF_UP_ROIC_ACLK_3_AED		16'h01E5 // 'd485
	`define DEF_UP_ROIC_ACLK_4_AED		16'h03D9 // 'd985
	`define DEF_UP_ROIC_ACLK_5_AED		16'h09C4 // 'd2500
	`define DEF_UP_ROIC_ACLK_6_AED		16'h09F6 // 'd2550
	`define DEF_UP_ROIC_ACLK_7_AED		16'h0A46 // 'd2630
	`define DEF_UP_ROIC_ACLK_8_AED		16'h0DB1 // 'd3505
	`define DEF_UP_ROIC_ACLK_9_AED		16'h0DE3 // 'd3555
	`define DEF_UP_ROIC_ACLK_10_AED		16'h0DE8 // 'd3560
	//
	`define DEF_UP_ROIC_ACLK_0_FLUSH	16'h0005
	`define DEF_UP_ROIC_ACLK_1_FLUSH	16'h0007
	`define DEF_UP_ROIC_ACLK_2_FLUSH	16'h0053 // 'd83
	`define DEF_UP_ROIC_ACLK_3_FLUSH	16'h0055 // 'd85
	`define DEF_UP_ROIC_ACLK_4_FLUSH	16'h0057 // 'd87
	`define DEF_UP_ROIC_ACLK_5_FLUSH	16'h0059 // 'd89
	`define DEF_UP_ROIC_ACLK_6_FLUSH	16'h005B // 'd91
	`define DEF_UP_ROIC_ACLK_7_FLUSH	16'h005D // 'd93
	`define DEF_UP_ROIC_ACLK_8_FLUSH	16'h005F // 'd95
	`define DEF_UP_ROIC_ACLK_9_FLUSH	16'h0061 // 'd97
	`define DEF_UP_ROIC_ACLK_10_FLUSH	16'h0063 // 'd99
`else
	`define DEF_UP_ROIC_ACLK_0_READ		16'h003C // 'd60
	`define DEF_UP_ROIC_ACLK_1_READ		16'h006E // 'd110
	`define DEF_UP_ROIC_ACLK_2_READ		16'h0168 // 'd360
	`define DEF_UP_ROIC_ACLK_3_READ		16'h01E5 // 'd485
	`define DEF_UP_ROIC_ACLK_4_READ		16'h03D9 // 'd985
	`define DEF_UP_ROIC_ACLK_5_READ		16'h09C4 // 'd2500
	`define DEF_UP_ROIC_ACLK_6_READ		16'h09F6 // 'd2550
	`define DEF_UP_ROIC_ACLK_7_READ		16'h0A46 // 'd2630
	`define DEF_UP_ROIC_ACLK_8_READ		16'h0FA5 // 'd4005
	`define DEF_UP_ROIC_ACLK_9_READ		16'h0FD7 // 'd4055
	`define DEF_UP_ROIC_ACLK_10_READ	16'h0FDC // 'd4060
	//
	`define DEF_UP_ROIC_ACLK_0_AED		16'h003C // 'd60
	`define DEF_UP_ROIC_ACLK_1_AED		16'h006E // 'd110
	`define DEF_UP_ROIC_ACLK_2_AED		16'h0168 // 'd360
	`define DEF_UP_ROIC_ACLK_3_AED		16'h01E5 // 'd485
	`define DEF_UP_ROIC_ACLK_4_AED		16'h03D9 // 'd985
	`define DEF_UP_ROIC_ACLK_5_AED		16'h09C4 // 'd2500
	`define DEF_UP_ROIC_ACLK_6_AED		16'h09F6 // 'd2550
	`define DEF_UP_ROIC_ACLK_7_AED		16'h0A46 // 'd2630
	`define DEF_UP_ROIC_ACLK_8_AED		16'h0DB1 // 'd3505
	`define DEF_UP_ROIC_ACLK_9_AED		16'h0DE3 // 'd3555
	`define DEF_UP_ROIC_ACLK_10_AED		16'h0DE8 // 'd3560
	//
	`define DEF_UP_ROIC_ACLK_0_FLUSH	16'h0005
	`define DEF_UP_ROIC_ACLK_1_FLUSH	16'h0007
	`define DEF_UP_ROIC_ACLK_2_FLUSH	16'h0053 // 'd83
	`define DEF_UP_ROIC_ACLK_3_FLUSH	16'h0055 // 'd85
	`define DEF_UP_ROIC_ACLK_4_FLUSH	16'h0057 // 'd87
	`define DEF_UP_ROIC_ACLK_5_FLUSH	16'h0059 // 'd89
	`define DEF_UP_ROIC_ACLK_6_FLUSH	16'h005B // 'd91
	`define DEF_UP_ROIC_ACLK_7_FLUSH	16'h005D // 'd93
	`define DEF_UP_ROIC_ACLK_8_FLUSH	16'h005F // 'd95
	`define DEF_UP_ROIC_ACLK_9_FLUSH	16'h0061 // 'd97
	`define DEF_UP_ROIC_ACLK_10_FLUSH	16'h0063 // 'd99
`endif

// 71143 : [8:6] PWR [4:0] IFS
// 71124 : [8:6] PWR [5:0] IFS
`define DEF_ROIC_REG_SET_0				16'h0014
// `define DEF_ROIC_REG_SET_0				16'h0094
// `define DEF_ROIC_REG_SET_0				16'h0020
// 71143 : [8:7] LPF [5] CDS2_RESETEN [4] CMR_EN [3] READDOWN [2] EXTRST [1] ADCAVG [0] HOLES
// 71124 : [9:7] LPF [5] CDS2_RESETEN [4] CMR_EN [3] READDOWN [2] EXTRST [1] ADCAVG [0] HOLES
`define DEF_ROIC_REG_SET_1				16'h01A8
`define DEF_ROIC_REG_SET_1_dual			16'h01A0
// [8] PDTFTEN [7] REFDACDIS [5] RNDOMIZE [3] INTCLAMP [2] DOUTMODE [1] ECHOCLK [0] PIPELINE
`define DEF_ROIC_REG_SET_2				16'h0007
// [8] AZEN [7:0] REFDAC 
`define DEF_ROIC_REG_SET_3				16'h0014
// [7:4] INTRST_C [3:0] INTRST_O
`define DEF_ROIC_REG_SET_4				16'h00A2
// [7:4] CDS1_C [3:0] CDS1_O
`define DEF_ROIC_REG_SET_5				16'h0014
// [7:4] CDS2_C [3:0] CDS2_O
`define DEF_ROIC_REG_SET_6				16'h0058
// [7:4] FA_CDS1 [3:0] FA_CDS2
`define DEF_ROIC_REG_SET_7				16'h0037
// [8] CUSTCLMPEN [7:4] CUSTCLMP_C [3:0] CUSTCLMP_O
`define DEF_ROIC_REG_SET_8				16'h0069
// Not use, fixed 7.
`define DEF_ROIC_REG_SET_9				16'h0007
// [0] PIPELINE_AVGEN
`define DEF_ROIC_REG_SET_10				16'h0000
// [6] LFSR_EN [5:0] Not use, fixed 24
`define DEF_ROIC_REG_SET_11				16'h0018
// 71143 : [8] LP_EN [7:0] Not use, fixed 2
// 71124 : [8] FUNC_SLEEP [7:0] Not use, fixed 2
`define DEF_ROIC_REG_SET_12				16'h0002
// Not use, fixed 35
`define DEF_ROIC_REG_SET_13				16'h0023
// Not use, fixed 43
`define DEF_ROIC_REG_SET_14				16'h002B
// Not use, fixed 8
`define DEF_ROIC_REG_SET_15				16'h0008

`define DEF_ROIC_BURST_CYCLE			16'd185	// h00B9
`define DEF_START_ROIC_BURST_CLK		16'd1   // h0001
`define DEF_END_ROIC_BURST_CLK			16'd65  // h0041

`ifdef TB_SIM
	`define DEF_SEL_ROIC_REG			8'h00
`else
	`define DEF_SEL_ROIC_REG			8'h01
`endif

`define DEF_IO_DELAY_TAB				5'd4

`define DEF_DN_AED_GATE_XAO_0			16'd2
`define DEF_DN_AED_GATE_XAO_1			16'd90
`define DEF_DN_AED_GATE_XAO_2			16'd180
`define DEF_DN_AED_GATE_XAO_3			16'd270
`define DEF_DN_AED_GATE_XAO_4			16'd360
`define DEF_DN_AED_GATE_XAO_5			16'd450
`define DEF_UP_AED_GATE_XAO_0			16'd3206
`define DEF_UP_AED_GATE_XAO_1			16'd3296
`define DEF_UP_AED_GATE_XAO_2			16'd3386
`define DEF_UP_AED_GATE_XAO_3			16'd3476
`define DEF_UP_AED_GATE_XAO_4			16'd3566
`define DEF_UP_AED_GATE_XAO_5			16'd3657

`ifdef TB_SIM
	`define DEF_DN_GATE_OE1_AED				16'h000F
	`define DEF_UP_GATE_OE1_AED				16'h0050
	`define DEF_DN_GATE_OE2_AED				16'h000F
	`define DEF_UP_GATE_OE2_AED				16'h0050

	`define DEF_AED_DETECT_LINE_0		16'd10
	`define DEF_AED_DETECT_LINE_1		16'd16
	`define DEF_AED_DETECT_LINE_2		16'd22
	`define DEF_AED_DETECT_LINE_3		16'd28
	`define DEF_AED_DETECT_LINE_4		16'd34
	`define DEF_AED_DETECT_LINE_5		16'd40
`else
	`define DEF_DN_GATE_OE1_AED				16'd990
	`define DEF_UP_GATE_OE1_AED				16'd2490
	`define DEF_DN_GATE_OE2_AED				16'd990
	`define DEF_UP_GATE_OE2_AED				16'd2490

	`define DEF_AED_DETECT_LINE_0		16'd1301
	`define DEF_AED_DETECT_LINE_1		16'd1401
	`define DEF_AED_DETECT_LINE_2		16'd1501
	`define DEF_AED_DETECT_LINE_3		16'd1601
	`define DEF_AED_DETECT_LINE_4		16'd1701
	`define DEF_AED_DETECT_LINE_5		16'd1801
`endif

`define DEF_READY_AED_READ				16'd80	// h0006
`define DEF_AED_TH						16'h0008
`define DEF_SEL_AED_ROIC				16'h0FFF	// h056A
`define DEF_NUM_TRIGGER					16'd2	// h0006
`define DEF_SEL_AED_TEST_ROIC			16'h0040
`define DEF_AED_CMD						16'h0000
`define DEF_NEGA_AED_TH					16'h0004
`define DEF_POSI_AED_TH					16'h0005
`define DEF_AED_DARK_DELAY				16'd40	 // h0028
`define DEF_BURST_BREAK_PT_0			16'd2    // h0002
`define DEF_BURST_BREAK_PT_1			16'd360  // h0168
`define DEF_BURST_BREAK_PT_2			16'd985  // h03D9
`define DEF_BURST_BREAK_PT_3			16'd4360 //h1108

//--------------------------------------------------------------------------------
// ROIC Clock Generation
//--------------------------------------------------------------------------------

// BURST 1 : Header
// BURST 2 ~ 33 : ROIC Data
// BURST 34 : ROIC CONFIG Register
`define TOTAL_NUM_ROIC_BURST			16'd34 // h22 // ROIC DataSheet ����. Page25, Figure37
`define VALID_NUM_ROIC_BURST			16'd33 // h21 
`define VALID_NUM_ROIC_REG_OUT			16'd34 // h22 

//--------------------------------------------------------------------------------
// ROIC Data Latch 
//--------------------------------------------------------------------------------

`define NUM_ROIC_DATA_PARALLEL			4'h3 //4'd3 // ������ 4���� ����

//--------------------------------------------------------------------------------
// ROIC Register Set 
//--------------------------------------------------------------------------------

`ifdef TB_SIM
	`define NUM_ROIC						8'h2 //8'd11 ROIC 12 EA
`else
	// `define NUM_ROIC						8'hB //8'd11 ROIC 12 EA
	`define NUM_ROIC						8'hA //8'd11 ROIC 11 EA
`endif

`define NUM_SPI_WR						8'hF //8'd15 Configure Reigser 16 EA
`define CS_START_DELAY					8'h12 //8'd18 Reset Ǯ���� CS ���۵Ǳ� �� ������ Delay time , min 4000ns
`define CS2CLK_DELAY					8'h1A //8'd26 CS �� Ȱ��ȭ�ǰ� SCK �� ���۵��� �� ������ delay time
`define VALID_CLK_WIDTH					8'h3A //8'd58 SCK enable duration, 26 ~ 58
`define CLK2CS_DELAY					8'h3D //8'd61 SCK Enable �� ��Ȱ��ȭ�ǰ� CS�� ��Ȱ��ȭ �Ǳ� �� ������ delay time
`define CS_END_DELAY					8'h55 //8'd85 ROIC Register settting enable duration, 0 ~ 85

//--------------------------------------------------------------------------------
// ROIC GATE Drive Control
//--------------------------------------------------------------------------------

`define READ_DATA_OUT_START_LINE		16'd2	
`define AED_READ_SKIP_START_LINE_0		16'd7
`define AED_GATE_OE_START_LINE_0		16'd1
`define AED_GATE_OE_END_LINE_0			16'd6
`define AED_DATA_OUT_START_LINE_0		16'd3
`define AED_DATA_OUT_END_LINE_0			16'd8

//--------------------------------------------------------------------------------
// Ctrl AED 
//--------------------------------------------------------------------------------

`define STOP_NUM						4'd3

//--------------------------------------------------------------------------------
// Ctrl FSM 
//--------------------------------------------------------------------------------

//`define INIT_CYCLE_WIDTH				16'h30
//`define INIT_HALF_CYCLE_WIDTH			16'h18
`define INIT_CYCLE_WIDTH				16'd100 // h60 // rev6
`define INIT_HALF_CYCLE_WIDTH			16'd50	// h36 // rev6

//--------------------------------------------------------------------------------
// Data Tx/Rx 
//--------------------------------------------------------------------------------

// ���� setting �� ROIC Output format �� Dual LVDS �̹Ƿ� BURST SIZE =  8.
// �ѹ��� �ԷµǴ� data �� : 8EA
`define BURST_SIZE						8'd8
//
`define VALID_NUM_ROIC_BURST_DATA		16'd32
// 1ch 256pixe , dual LVDS �������? 128 ROIC CHANNEL setting
`define NUM_ROIC_CHANNEL				8'd127
// 4 pixel data �̹Ƿ� 768 * 4 = 3072
`define MEM_HEIGHT						10'd767
//
`define UP_1XROIC_SIZE					10'd124
`define DN_1XROIC_SIZE					10'd127
`define UP_2XROIC_SIZE					10'd252
`define DN_2XROIC_SIZE					10'd255
`define UP_3XROIC_SIZE					10'd380
`define DN_3XROIC_SIZE					10'd383
`define UP_4XROIC_SIZE					10'd508
`define DN_4XROIC_SIZE					10'd511
`define UP_5XROIC_SIZE					10'd636
`define DN_5XROIC_SIZE					10'd639
`define UP_6XROIC_SIZE					10'd764
`define DN_6XROIC_SIZE					10'd767

//----------------------------------------
//----------------------------------------
//----------------------------------------
