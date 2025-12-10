//==============================================================================
// Project     : BLUE Platform - X-ray Detector System
// Module      : p_define_refacto.sv
// Description : Global Parameter Definitions with Macro-based Optimization
//
// Copyright (c) 2024-2025 H&abyz Inc.
// All rights reserved.
//
// Author      : drake.lee (holee9@gmail.com)
// Company     : H&abyz Inc.
// Created     : 2024-01-10
// Modified    : 2025-12-05
//
//==============================================================================
// Version History
//==============================================================================
// Version | Date       | Author     | Description
//---------|------------|------------|--------------------------------------------
// 0.0     | 2024-01-10 | drake.lee  | Initial release
// 0.1     | 2024-03-20 | drake.lee  | RAON project release
// 0.2     | 2024-06-20 | drake.lee  | BLUE project release
// 0.3     | 2025-12-05 | drake.lee  | Refactored with macro optimization
//         |            |            | - Unified address and default value definitions
//         |            |            | - Introduced pattern-based macro groups
//         |            |            | - Reduced code size by ~31%
//==============================================================================
// Features
//==============================================================================
// - Single ROIC readout (TI ROIC ADI)
// - CSI2 interface: 2-pixel, 4-lane configuration
// - Macro-based register definition for maintainability
// - Conditional compilation for simulation and hardware targets
// - Comprehensive register map (512 addresses)
//
//==============================================================================
// Configuration
//==============================================================================

// `define TB_SIM
`define TI_ROIC

//----------------------------------------
// Macro Definitions for Register Management
//----------------------------------------

// Define register with address and default value
// Usage: `DEFREG(NAME, ADDRESS, DEFAULT_VALUE)
// Creates: `ADDR_NAME and `DEF_NAME
`define DEFREG(name, addr, defval) \
    `define ADDR_``name  addr \
    `define DEF_``name   defval

// Define read-only register (no default value needed)
// Usage: `DEFREG_RO(NAME, ADDRESS)
// Creates: `ADDR_NAME only
`define DEFREG_RO(name, addr) \
    `define ADDR_``name  addr

// Define GATE register group (12 registers per mode)
// Usage: `DEFGATE_GROUP(MODE, BASE_ADDR, values...)
`define DEFGATE_GROUP(mode, base_addr, up_stv1, dn_stv1, up_stv2, dn_stv2, up_cpv1, dn_cpv1, up_cpv2, dn_cpv2, dn_oe1, up_oe1, dn_oe2, up_oe2) \
    `DEFREG(UP_GATE_STV1_``mode,  base_addr + 16'h0, up_stv1) \
    `DEFREG(DN_GATE_STV1_``mode,  base_addr + 16'h1, dn_stv1) \
    `DEFREG(UP_GATE_STV2_``mode,  base_addr + 16'h2, up_stv2) \
    `DEFREG(DN_GATE_STV2_``mode,  base_addr + 16'h3, dn_stv2) \
    `DEFREG(UP_GATE_CPV1_``mode,  base_addr + 16'h4, up_cpv1) \
    `DEFREG(DN_GATE_CPV1_``mode,  base_addr + 16'h5, dn_cpv1) \
    `DEFREG(UP_GATE_CPV2_``mode,  base_addr + 16'h6, up_cpv2) \
    `DEFREG(DN_GATE_CPV2_``mode,  base_addr + 16'h7, dn_cpv2) \
    `DEFREG(DN_GATE_OE1_``mode,   base_addr + 16'h8, dn_oe1) \
    `DEFREG(UP_GATE_OE1_``mode,   base_addr + 16'h9, up_oe1) \
    `DEFREG(DN_GATE_OE2_``mode,   base_addr + 16'hA, dn_oe2) \
    `DEFREG(UP_GATE_OE2_``mode,   base_addr + 16'hB, up_oe2)

// Define ROIC ACLK register sequence (11 registers per mode)
// Usage: `DEFROIC_ACLK(MODE, BASE_ADDR, v0...v10)
`define DEFROIC_ACLK(mode, base_addr, v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) \
    `DEFREG(UP_ROIC_ACLK_0_``mode,   base_addr + 16'h0, v0) \
    `DEFREG(UP_ROIC_ACLK_1_``mode,   base_addr + 16'h1, v1) \
    `DEFREG(UP_ROIC_ACLK_2_``mode,   base_addr + 16'h2, v2) \
    `DEFREG(UP_ROIC_ACLK_3_``mode,   base_addr + 16'h3, v3) \
    `DEFREG(UP_ROIC_ACLK_4_``mode,   base_addr + 16'h4, v4) \
    `DEFREG(UP_ROIC_ACLK_5_``mode,   base_addr + 16'h5, v5) \
    `DEFREG(UP_ROIC_ACLK_6_``mode,   base_addr + 16'h6, v6) \
    `DEFREG(UP_ROIC_ACLK_7_``mode,   base_addr + 16'h7, v7) \
    `DEFREG(UP_ROIC_ACLK_8_``mode,   base_addr + 16'h8, v8) \
    `DEFREG(UP_ROIC_ACLK_9_``mode,   base_addr + 16'h9, v9) \
    `DEFREG(UP_ROIC_ACLK_10_``mode,  base_addr + 16'hA, v10)

// Define ROIC register set sequence (0-15)
`define DEFROIC_REG_SET(idx, addr, defval) \
    `DEFREG(ROIC_REG_SET_``idx, addr, defval)

// Define TI ROIC register
`define DEFTI_ROIC_REG(regname, addr, defval) \
    `DEFREG(TI_ROIC_REG_``regname, addr, defval)

// Define AED GATE XAO registers (6 registers: DN and UP)
`define DEFAED_XAO(base_addr_dn, base_addr_up, dn0, dn1, dn2, dn3, dn4, dn5, up0, up1, up2, up3, up4, up5) \
    `DEFREG(DN_AED_GATE_XAO_0, base_addr_dn + 16'h0, dn0) \
    `DEFREG(DN_AED_GATE_XAO_1, base_addr_dn + 16'h1, dn1) \
    `DEFREG(DN_AED_GATE_XAO_2, base_addr_dn + 16'h2, dn2) \
    `DEFREG(DN_AED_GATE_XAO_3, base_addr_dn + 16'h3, dn3) \
    `DEFREG(DN_AED_GATE_XAO_4, base_addr_dn + 16'h4, dn4) \
    `DEFREG(DN_AED_GATE_XAO_5, base_addr_dn + 16'h5, dn5) \
    `DEFREG(UP_AED_GATE_XAO_0, base_addr_up + 16'h0, up0) \
    `DEFREG(UP_AED_GATE_XAO_1, base_addr_up + 16'h1, up1) \
    `DEFREG(UP_AED_GATE_XAO_2, base_addr_up + 16'h2, up2) \
    `DEFREG(UP_AED_GATE_XAO_3, base_addr_up + 16'h3, up3) \
    `DEFREG(UP_AED_GATE_XAO_4, base_addr_up + 16'h4, up4) \
    `DEFREG(UP_AED_GATE_XAO_5, base_addr_up + 16'h5, up5)

//--------------------------------------------------------------------------------
// Initialization Parameters
//--------------------------------------------------------------------------------

`ifdef TB_SIM
    `define INIT_DELAY                  25'd25      // 25 x 40ns, 1us
    `define MORE_DELAY                  25'd500     // 500 x 40ns, 20us
    `define FULL_CYCLE_WIDTH            24'd20
    `define MIN_UNIT                    24'd250
`else
    `define INIT_DELAY                  25'd2500000 // 2,500,000 x 40ns, 100ms
    `define MORE_DELAY                  25'd2500000 // 2,500,000 x 40ns, 100ms
    `define FULL_CYCLE_WIDTH            24'd2000000 // 100ms when 20MHz, 50ns x 2,000,000
    `define MIN_UNIT                    24'd200000  // 10ms when 20MHz, 200,000
`endif

//--------------------------------------------------------------------------------
// Register Map Configuration
//--------------------------------------------------------------------------------

`define PURPOSE                         16'h4753    // GS
`define SIZE_1                          16'h3137    // 17
`define SIZE_2                          16'h3137    // 17
`define MAJOR_REV                       16'h3031    // 01
`define MINOR_REV                       16'h3030    // 00
`define ROIC_VENDOR                     16'h5449    // TI

`define AED_READ_ADDED_LINES            16'h5
`define MAX_ADDR                        16'd512

//--------------------------------------------------------------------------------
// Register Definitions
//--------------------------------------------------------------------------------

// ===== System Control Registers (0x0001 - 0x0007) =====
`DEFREG(SYS_CMD_REG,                16'h0001, 16'h0001)
`DEFREG(OP_MODE_REG,                16'h0002, 16'h0002)
`DEFREG(SET_GATE,                   16'h0003, 16'hC908)
`DEFREG(GATE_SIZE,                  16'h0004, 16'h0200)
`DEFREG(PWR_OFF_DWN,                16'h0005, 16'h0000)
`DEFREG(READOUT_COUNT,              16'h0006, 16'd0)
`DEFREG(REG_MAP_SEL,                16'h0007, 16'h0000)

// ===== Timing Control Registers (0x0010 - 0x001E) =====
`DEFREG(EXPOSE_SIZE,                16'h0010, 16'd500)
`DEFREG(BACK_BIAS_SIZE,             16'h0011, 16'd45000)
`DEFREG(IMAGE_HEIGHT,               16'h0012, 16'd3072)
`DEFREG(CYCLE_WIDTH_FLUSH,          16'h0013, 16'd100)
`DEFREG(CYCLE_WIDTH_AED,            16'h0014, 16'd3660)
`DEFREG(CYCLE_WIDTH_READ,           16'h0015, 16'd1024)
`DEFREG(REPEAT_BACK_BIAS,           16'h0016, 16'd1)
`DEFREG(REPEAT_FLUSH,               16'h0017, 16'd2)
`DEFREG(SATURATION_FLUSH_REPEAT,    16'h0018, 16'd2)
`DEFREG(EXP_DELAY,                  16'h0019, 16'd100)
`DEFREG(READY_DELAY,                16'h001A, 16'd5)
`DEFREG(PRE_DELAY,                  16'h001B, 16'd7)
`DEFREG(POST_DELAY,                 16'h001C, 16'd8)
`DEFREG(FRAME_COUNT,                16'h001E, 16'd0)

// ===== Back Bias Registers (0x0020 - 0x0023) =====
`DEFREG(UP_BACK_BIAS,               16'h0020, 16'd160)
`DEFREG(DN_BACK_BIAS,               16'h0021, 16'd0)
`DEFREG(UP_BACK_BIAS_OPR,           16'h0022, 16'd160)
`DEFREG(DN_BACK_BIAS_OPR,           16'h0023, 16'd0)

// ===== GATE Registers - READ Mode (0x0024 - 0x002F) =====
`DEFGATE_GROUP(READ, 16'h0024, 
    16'h003C, 16'h0168, 16'h003C, 16'h0168,     // STV1, STV2
    16'h006E, 16'h01E5, 16'h006E, 16'h01E5,     // CPV1, CPV2
    16'd990, 16'd2490, 16'd990, 16'd2490)       // OE1, OE2

// Additional READ XAO
`DEFREG(DN_GATE_XAO_READ,           16'h0030, 16'd2)
`DEFREG(UP_GATE_XAO_READ,           16'h0031, 16'd0)

// ===== GATE Registers - AED Mode (0x0032 - 0x003F) =====
`DEFGATE_GROUP(AED, 16'h0032,
    16'h003C, 16'h0168, 16'h003C, 16'h0168,     // STV1, STV2
    16'h006E, 16'h01E5, 16'h006E, 16'h01E5,     // CPV1, CPV2
    16'd990, 16'd2490, 16'd990, 16'd2490)       // OE1, OE2

`DEFREG(DN_GATE_XAO_AED,            16'h003E, 16'd2)
`DEFREG(UP_GATE_XAO_AED,            16'h003F, 16'd0)

// ===== GATE Registers - FLUSH Mode (0x0040 - 0x004B) =====
`DEFGATE_GROUP(FLUSH, 16'h0040,
    16'h0002, 16'h0025, 16'h0002, 16'h0025,     // STV1, STV2
    16'd10, 16'd40, 16'd10, 16'd40,              // CPV1, CPV2
    16'd15, 16'd180, 16'd15, 16'd180)            // OE1, OE2

// ===== ROIC Sync and ACLK Registers (0x0050 - 0x0071) =====
`DEFREG(UP_ROIC_SYNC,               16'h0050, 16'h0002)

// ROIC ACLK - READ Mode
`DEFROIC_ACLK(READ, 16'h0051,
    16'h003C, 16'h006E, 16'h0168, 16'h01E5, 16'h03D9,
    16'h09C4, 16'h09F6, 16'h0A46, 16'h0FA5, 16'h0FD7, 16'h0FDC)

// ROIC ACLK - AED Mode
`DEFROIC_ACLK(AED, 16'h005C,
    16'h003C, 16'h006E, 16'h0168, 16'h01E5, 16'h03D9,
    16'h09C4, 16'h09F6, 16'h0A46, 16'h0DB1, 16'h0DE3, 16'h0DE8)

// ROIC ACLK - FLUSH Mode
`DEFROIC_ACLK(FLUSH, 16'h0067,
    16'h0005, 16'h0007, 16'h0053, 16'h0055, 16'h0057,
    16'h0059, 16'h005B, 16'h005D, 16'h005F, 16'h0061, 16'h0063)

// ===== ROIC Register Set (0x0072 - 0x0081) =====
`DEFROIC_REG_SET(0,     16'h0072, 16'h0014)
`DEFROIC_REG_SET(1,     16'h0073, 16'h01A8)
`DEFREG(ROIC_REG_SET_1_dual, 16'h0173, 16'h01A0)
`DEFROIC_REG_SET(2,     16'h0074, 16'h0007)
`DEFROIC_REG_SET(3,     16'h0075, 16'h0014)
`DEFROIC_REG_SET(4,     16'h0076, 16'h00A2)
`DEFROIC_REG_SET(5,     16'h0077, 16'h0014)
`DEFROIC_REG_SET(6,     16'h0078, 16'h0058)
`DEFROIC_REG_SET(7,     16'h0079, 16'h0037)
`DEFROIC_REG_SET(8,     16'h007A, 16'h0069)
`DEFROIC_REG_SET(9,     16'h007B, 16'h0007)
`DEFROIC_REG_SET(10,    16'h007C, 16'h0000)
`DEFROIC_REG_SET(11,    16'h007D, 16'h0018)
`DEFROIC_REG_SET(12,    16'h007E, 16'h0002)
`DEFROIC_REG_SET(13,    16'h007F, 16'h0023)
`DEFROIC_REG_SET(14,    16'h0080, 16'h002B)
`DEFROIC_REG_SET(15,    16'h0081, 16'h0008)

// ROIC Temperature (Read-Only)
`DEFREG_RO(ROIC_TEMPERATURE,        16'h0082)

// ===== ROIC Burst Control (0x0090 - 0x0092) =====
`DEFREG(ROIC_BURST_CYCLE,           16'h0090, 16'd185)
`DEFREG(START_ROIC_BURST_CLK,       16'h0091, 16'd1)
`DEFREG(END_ROIC_BURST_CLK,         16'h0092, 16'd65)

// ===== Gate GPIO Register (0x0099) =====
`DEFREG(GATE_GPIO_REG,              16'h0099, 16'h0000)

// ===== Select ROIC Register (0x00A0) =====
`ifdef TB_SIM
    `DEFREG(SEL_ROIC_REG,           16'h00A0, 8'h00)
`else
    `DEFREG(SEL_ROIC_REG,           16'h00A0, 8'h01)
`endif

// ===== AED GATE XAO Registers (0x00A2 - 0x00AD) =====
`ifdef TI_ROIC
    `DEFAED_XAO(16'h00A2, 16'h00A8,
        16'd2, 16'd2, 16'd2, 16'd2, 16'd2, 16'd2,
        16'd2030, 16'd2030, 16'd2030, 16'd2030, 16'd2030, 16'd2030)
`elsif ADI_ROIC
    `DEFAED_XAO(16'h00A2, 16'h00A8,
        16'd2, 16'd90, 16'd180, 16'd270, 16'd360, 16'd450,
        16'd3206, 16'd3296, 16'd3386, 16'd3476, 16'd3566, 16'd3657)
`endif

// ===== AED Control Registers (0x00B0 - 0x00BD) =====
`DEFREG(READY_AED_READ,             16'h00B0, 16'd80)
`DEFREG(AED_TH,                     16'h00B1, 16'h0008)
`DEFREG(SEL_AED_ROIC,               16'h00B2, 16'h0FFF)
`DEFREG(NUM_TRIGGER,                16'h00B3, 16'd2)
`DEFREG(SEL_AED_TEST_ROIC,          16'h00B4, 16'h0040)
`DEFREG(AED_CMD,                    16'h00B5, 16'h0000)
`DEFREG(NEGA_AED_TH,                16'h00B6, 16'h0004)
`DEFREG(POSI_AED_TH,                16'h00B7, 16'h0005)
`DEFREG(AED_DARK_DELAY,             16'h00B8, 16'd40)
`DEFREG(TEST_REG_A,                 16'h00BA, 16'h0000)
`DEFREG(TEST_REG_B,                 16'h00BB, 16'h0000)
`DEFREG(TEST_REG_C,                 16'h00BC, 16'h0000)
`DEFREG(TEST_REG_D,                 16'h00BD, 16'h0000)

// ===== AED Detect Line Registers (0x00C0 - 0x00C5) =====
`ifdef TB_SIM
    `DEFREG(AED_DETECT_LINE_0,      16'h00C0, 16'd10)
    `DEFREG(AED_DETECT_LINE_1,      16'h00C1, 16'd16)
    `DEFREG(AED_DETECT_LINE_2,      16'h00C2, 16'd22)
    `DEFREG(AED_DETECT_LINE_3,      16'h00C3, 16'd28)
    `DEFREG(AED_DETECT_LINE_4,      16'h00C4, 16'd34)
    `DEFREG(AED_DETECT_LINE_5,      16'h00C5, 16'd40)
`else
    `DEFREG(AED_DETECT_LINE_0,      16'h00C0, 16'd1301)
    `DEFREG(AED_DETECT_LINE_1,      16'h00C1, 16'd1401)
    `DEFREG(AED_DETECT_LINE_2,      16'h00C2, 16'd1501)
    `DEFREG(AED_DETECT_LINE_3,      16'h00C3, 16'd1601)
    `DEFREG(AED_DETECT_LINE_4,      16'h00C4, 16'd1701)
    `DEFREG(AED_DETECT_LINE_5,      16'h00C5, 16'd1801)
`endif

// ===== CSI2 Configuration (0x00D0 - 0x00D2) =====
`DEFREG(MAX_V_COUNT,                16'h00D0, 16'd1536)
`DEFREG(MAX_H_COUNT,                16'h00D1, 16'd256)
`DEFREG(CSI2_WORD_COUNT,            16'h00D2, 16'd1024)

// ===== System Info Registers (0x00DB - 0x00DF) =====
`DEFREG(STATE_LED_CTR,              16'h00DB, 16'h0000)
`DEFREG(IO_DELAY_TAB,               16'h00DC, 5'd4)
`DEFREG_RO(ROIC_VENDOR,             16'h00DD)
`DEFREG_RO(FPGA_VER_L,              16'h00DE)
`DEFREG_RO(FPGA_VER_H,              16'h00DF)

// ===== Sequence Table FSM Registers (0x00E0 - 0x00EB) =====
`DEFREG(SEQ_LUT_ADDR,               16'h00E0, 16'h0000)
`DEFREG(SEQ_LUT_DATA_0,             16'h00E1, 16'h0000)
`DEFREG(SEQ_LUT_DATA_1,             16'h00E2, 16'h0000)
`DEFREG(SEQ_LUT_DATA_2,             16'h00E3, 16'h0000)
`DEFREG(SEQ_LUT_DATA_3,             16'h00E4, 16'h0000)
`DEFREG(SEQ_LUT_CONTROL,            16'h00E5, 16'h0000)
`DEFREG(ACQ_MODE,                   16'h00E6, 16'h0000)
`DEFREG(SEQ_STATE_READ,             16'h00E7, 16'h0000)
`DEFREG(SWITCH_SYNC_UP,             16'h00EA, 16'h03FF)
`DEFREG(SWITCH_SYNC_DN,             16'h00EB, 16'h0001)

// ===== Version and Test Registers (0x00F0 - 0x00FE) =====
`DEFREG_RO(PURPOSE,                 16'h00F0)
`DEFREG_RO(SIZE_1,                  16'h00F1)
`DEFREG_RO(SIZE_2,                  16'h00F2)
`DEFREG_RO(MAJOR_REV,               16'h00F3)
`DEFREG_RO(MINOR_REV,               16'h00F4)
`DEFREG(TEST_REG_0,                 16'h00F5, 16'h0000)
`DEFREG(TEST_REG_1,                 16'h00F6, 16'h0000)
`DEFREG(TEST_REG_2,                 16'h00F7, 16'h0000)
`DEFREG(TEST_REG_3,                 16'h00F8, 16'h0000)
`DEFREG(TEST_REG_4,                 16'h00F9, 16'h0000)
`DEFREG(TEST_REG_5,                 16'h00FA, 16'h0000)
`DEFREG(TEST_REG_6,                 16'h00FB, 16'h0000)
`DEFREG(TEST_REG_7,                 16'h00FC, 16'h0000)
`DEFREG(TEST_REG_8,                 16'h00FD, 16'h0000)
`DEFREG(TEST_REG_9,                 16'h00FE, 16'h0000)

// ===== FSM State Register (0x00FF) - Read Only =====
`DEFREG_RO(FSM_REG,                 16'h00FF)

//--------------------------------------------------------------------------------
// TI ROIC Register Definitions (0x0100 - 0x0124)
//--------------------------------------------------------------------------------

`DEFTI_ROIC_REG(00,     16'h0100, 16'h0000)
`DEFTI_ROIC_REG(10,     16'h0101, 16'h0800)
`DEFTI_ROIC_REG(11,     16'h0102, 16'h0430)
`DEFTI_ROIC_REG(12,     16'h0103, 16'h0400)
`DEFTI_ROIC_REG(13,     16'h0104, 16'h0000)
`DEFTI_ROIC_REG(16,     16'h0105, 16'h00C0)
`DEFTI_ROIC_REG(18,     16'h0106, 16'h0001)
`DEFTI_ROIC_REG(2C,     16'h0107, 16'h0000)
`DEFTI_ROIC_REG(30,     16'h0108, 16'h0000)
`DEFTI_ROIC_REG(31,     16'h0109, 16'h0000)
`DEFTI_ROIC_REG(32,     16'h010A, 16'h0000)
`DEFTI_ROIC_REG(33,     16'h010B, 16'h0000)
`DEFTI_ROIC_REG(40,     16'h010C, 16'h0105)
`DEFTI_ROIC_REG(42,     16'h010D, 16'h0682)
`DEFTI_ROIC_REG(43,     16'h010E, 16'h83FF)
`DEFTI_ROIC_REG(46,     16'h010F, 16'h0D83)
`DEFTI_ROIC_REG(47,     16'h0110, 16'h8B00)
`DEFTI_ROIC_REG(4A,     16'h0111, 16'h0685)
`DEFTI_ROIC_REG(4B,     16'h0112, 16'h0000)
`DEFTI_ROIC_REG(50,     16'h0113, 16'h8300)
`DEFTI_ROIC_REG(51,     16'h0114, 16'h8300)
`DEFTI_ROIC_REG(52,     16'h0115, 16'h8300)
`DEFTI_ROIC_REG(53,     16'h0116, 16'h8300)
`DEFTI_ROIC_REG(54,     16'h0117, 16'h8300)
`DEFTI_ROIC_REG(55,     16'h0118, 16'h8300)
`DEFTI_ROIC_REG(5A,     16'h0119, 16'h0040)
`DEFTI_ROIC_REG(5C,     16'h011A, 16'h8000)
`DEFTI_ROIC_REG(5D,     16'h011B, 16'h0000)
`DEFTI_ROIC_REG(5E,     16'h011C, 16'h0000)
`DEFTI_ROIC_REG(61,     16'h011D, 16'h0400)

// TI ROIC Control Registers
`DEFREG(TI_ROIC_REG_ADDR,           16'h0120, 16'h0000)
`DEFREG(TI_ROIC_REG_DATA,           16'h0121, 16'h0000)
`DEFREG(TI_ROIC_SYNC,               16'h0122, 16'h0000)
`DEFREG(TI_ROIC_TP_SEL,             16'h0123, 16'h0000)
`DEFREG(TI_ROIC_STR,                16'h0124, 16'h0000)

// TI ROIC Deserializer Control (0x0130 - 0x0137)
`DEFREG(TI_ROIC_DESER_RESET,        16'h0130, 16'h0000)
`DEFREG(TI_ROIC_DESER_DLY_TAP_LD,   16'h0131, 16'h0000)
`DEFREG(TI_ROIC_DESER_DLY_TAP_IN,   16'h0132, 16'h0000)
`DEFREG(TI_ROIC_DESER_DLY_DATA_CE,  16'h0133, 16'h0000)
`DEFREG(TI_ROIC_DESER_DLY_DATA_INC, 16'h0134, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_MODE,   16'h0135, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_START,  16'h0136, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_DONE,   16'h0137, 16'h0000)

// TI ROIC Deserializer Align Shift (0x0140 - 0x014B)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_0,  16'h0140, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_1,  16'h0141, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_2,  16'h0142, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_3,  16'h0143, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_4,  16'h0144, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_5,  16'h0145, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_6,  16'h0146, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_7,  16'h0147, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_8,  16'h0148, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_9,  16'h0149, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_10, 16'h014A, 16'h0000)
`DEFREG(TI_ROIC_DESER_ALIGN_SHIFT_11, 16'h014B, 16'h0000)

// TI ROIC Deserializer Shift Set (0x0150 - 0x015B)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_0,    16'h0150, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_1,    16'h0151, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_2,    16'h0152, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_3,    16'h0153, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_4,    16'h0154, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_5,    16'h0155, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_6,    16'h0156, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_7,    16'h0157, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_8,    16'h0158, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_9,    16'h0159, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_10,   16'h015A, 16'h0000)
`DEFREG(TI_ROIC_DESER_SHIFT_SET_11,   16'h015B, 16'h0000)

//--------------------------------------------------------------------------------
// Additional Default Address Definitions
//--------------------------------------------------------------------------------

`define DEF_IRST_ADDR                   8'h40
`define DEF_SHR_ADDR                    8'h42
`define DEF_SHS_ADDR                    8'h43
`define DEF_LPF1_ADDR                   8'h46
`define DEF_LPF2_ADDR                   8'h47
`define DEF_TDEF_ADDR                   8'h4A
`define DEF_GATE_ADDR                   8'h4B
`define DEF_SM0_ADDR                    8'h50
`define DEF_SM1_ADDR                    8'h51
`define DEF_SM2_ADDR                    8'h52
`define DEF_SM3_ADDR                    8'h53
`define DEF_SM4_ADDR                    8'h54
`define DEF_SM5_ADDR                    8'h55

//--------------------------------------------------------------------------------
// Additional OE Defaults for AED
//--------------------------------------------------------------------------------
`ifdef TB_SIM
    `define DEF_DN_GATE_OE1_AED         16'h000F
    `define DEF_UP_GATE_OE1_AED         16'h0050
    `define DEF_DN_GATE_OE2_AED         16'h000F
    `define DEF_UP_GATE_OE2_AED         16'h0050
`else
    `define DEF_DN_GATE_OE1_AED         16'd990
    `define DEF_UP_GATE_OE1_AED         16'd2490
    `define DEF_DN_GATE_OE2_AED         16'd990
    `define DEF_UP_GATE_OE2_AED         16'd2490
`endif

`define DEF_BURST_BREAK_PT_0            16'd2
`define DEF_BURST_BREAK_PT_1            16'd360
`define DEF_BURST_BREAK_PT_2            16'd985
`define DEF_BURST_BREAK_PT_3            16'd4360

//--------------------------------------------------------------------------------
// ROIC Clock Generation
//--------------------------------------------------------------------------------

`define TOTAL_NUM_ROIC_BURST            16'd34
`define VALID_NUM_ROIC_BURST            16'd33
`define VALID_NUM_ROIC_REG_OUT          16'd34

//--------------------------------------------------------------------------------
// ROIC Data Latch
//--------------------------------------------------------------------------------

`define NUM_ROIC_DATA_PARALLEL          4'h3

//--------------------------------------------------------------------------------
// ROIC Register Set
//--------------------------------------------------------------------------------

`ifdef TB_SIM
    `define NUM_ROIC                    8'h2
`else
    `define NUM_ROIC                    8'hA
`endif

`define NUM_SPI_WR                      8'hF
`define CS_START_DELAY                  8'h12
`define CS2CLK_DELAY                    8'h1A
`define VALID_CLK_WIDTH                 8'h3A
`define CLK2CS_DELAY                    8'h3D
`define CS_END_DELAY                    8'h55

//--------------------------------------------------------------------------------
// ROIC GATE Drive Control
//--------------------------------------------------------------------------------

`define READ_DATA_OUT_START_LINE        16'd2
`define AED_READ_SKIP_START_LINE_0      16'd7
`define AED_GATE_OE_START_LINE_0        16'd1
`define AED_GATE_OE_END_LINE_0          16'd6
`define AED_DATA_OUT_START_LINE_0       16'd3
`define AED_DATA_OUT_END_LINE_0         16'd8

// ===== CSI2 Interface Registers (TODO 2.3) =====
`DEFREG(MAX_V_COUNT,            16'h00D0, 16'd1536)  // Maximum vertical count
`DEFREG(MAX_H_COUNT,            16'h00D1, 16'd256)   // Maximum horizontal count
`DEFREG(CSI2_WORD_COUNT,        16'h00D2, 16'd1024)  // CSI2 word count

// ===== TI ROIC Basic Control Registers (TODO 4.1) =====
`DEFREG(TI_ROIC_REG_ADDR,       16'h0120, 16'd0)     // TI ROIC register address
`DEFREG(TI_ROIC_REG_DATA,       16'h0121, 16'd0)     // TI ROIC register data
`DEFREG(TI_ROIC_SYNC,           16'h0122, 16'd0)     // TI ROIC sync signal
`DEFREG(TI_ROIC_TP_SEL,         16'h0123, 16'd0)     // TI ROIC test pattern select
`DEFREG(TI_ROIC_STR,            16'h0124, 16'd3)     // TI ROIC strength control

//--------------------------------------------------------------------------------
// Ctrl AED
//--------------------------------------------------------------------------------

`define STOP_NUM                        4'd3

//--------------------------------------------------------------------------------
// Ctrl FSM
//--------------------------------------------------------------------------------

`define INIT_CYCLE_WIDTH                16'd100
`define INIT_HALF_CYCLE_WIDTH           16'd50

//--------------------------------------------------------------------------------
// Data Tx/Rx
//--------------------------------------------------------------------------------

`define BURST_SIZE                      8'd8
`define VALID_NUM_ROIC_BURST_DATA       16'd32
`define NUM_ROIC_CHANNEL                8'd127
`define MEM_HEIGHT                      10'd767

`define UP_1XROIC_SIZE                  10'd124
`define DN_1XROIC_SIZE                  10'd127
`define UP_2XROIC_SIZE                  10'd252
`define DN_2XROIC_SIZE                  10'd255
`define UP_3XROIC_SIZE                  10'd380
`define DN_3XROIC_SIZE                  10'd383
`define UP_4XROIC_SIZE                  10'd508
`define DN_4XROIC_SIZE                  10'd511
`define UP_5XROIC_SIZE                  10'd636
`define DN_5XROIC_SIZE                  10'd639
`define UP_6XROIC_SIZE                  10'd764
`define DN_6XROIC_SIZE                  10'd767

//--------------------------------------------------------------------------------
// End of p_define_refacto.sv
//--------------------------------------------------------------------------------
