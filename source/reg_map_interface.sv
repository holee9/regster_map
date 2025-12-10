//==============================================================================
// Project     : BLUE Platform - X-ray Detector System
// Module      : reg_map_interface.sv
// Description : Interface Definition for Register Map Module
//               Defines all input/output signals and parameters
//
// Copyright (c) 2024-2025 H&abyz Inc.
// All rights reserved.
//
// Author      : drake.lee (holee9@gmail.com)
// Company     : H&abyz Inc.
// Created     : 2025-12-05
//
//==============================================================================

`ifndef REG_MAP_INTERFACE_SV
`define REG_MAP_INTERFACE_SV

//==============================================================================
// Interface: reg_map_if
// Description: Complete interface for register map module
//==============================================================================
interface reg_map_if (
    input logic eim_clk,
    input logic fsm_clk
);

    //==========================================================================
    // Clock and Reset Signals
    //==========================================================================
    logic         eim_rst;                // EIM clock domain reset (active high)
    logic         rst;                    // FSM clock domain reset (active high)

    //==========================================================================
    // FSM State Input Signals (from main FSM)
    //==========================================================================
    // One-hot encoded FSM state indicators
    logic         fsm_rst_index;          // FSM in RESET state
    logic         fsm_init_index;         // FSM in INIT state
    logic         fsm_back_bias_index;    // FSM in BACK_BIAS state
    logic         fsm_flush_index;        // FSM in FLUSH state
    logic         fsm_aed_read_index;     // FSM in AED_READ state
    logic         fsm_exp_index;          // FSM in EXPOSURE state
    logic         fsm_read_index;         // FSM in READ state
    logic         fsm_idle_index;         // FSM in IDLE state

    //==========================================================================
    // System Status Input Signals
    //==========================================================================
    logic         ready_to_get_image;     // System ready to acquire image
    logic         aed_ready_done;         // AED (Auto Exposure Detection) ready
    logic         panel_stable_exist;     // Panel voltage stabilized
    logic         exp_read_exist;         // Exposure/Read operation in progress

    //==========================================================================
    // Register Access Interface (EIM Interface - 66MHz)
    //==========================================================================
    logic         reg_read_index;         // Register read request
    logic [15:0]  reg_addr;               // Register address (0x0000 ~ 0x01FF)
    logic [15:0]  reg_data;               // Register write data
    logic         reg_data_index;         // Register write enable

    //==========================================================================
    // Register Read Output Interface
    //==========================================================================
    logic [15:0]  reg_read_out;           // Register read data output
    logic         read_data_en;           // Read data valid signal

    //==========================================================================
    // System Control Output Signals (Phase 0 - Currently Implemented)
    //==========================================================================
    logic [7:0]   state_led_ctr;          // LED control for state indication
    logic         reg_map_sel;            // Register map selection

    //==========================================================================
    // Phase 1 Output Signals (TODO - Not Yet Implemented)
    //==========================================================================
    // System Control
    // logic         system_rst;           // System-level reset control
    // logic         reset_fsm;            // FSM reset control
    // logic         en_pwr_dwn;           // Power down enable
    // logic         en_pwr_off;           // Power off enable
    
    // Image Acquisition Commands
    // logic         get_dark;             // Dark frame acquisition command
    // logic         get_bright;           // Bright frame acquisition command
    // logic         cmd_get_bright;       // Bright frame acquisition trigger
    // logic         burst_get_image;      // Burst image acquisition mode
    // logic         dummy_get_image;      // Dummy image acquisition
    // logic         exp_ack;              // Exposure acknowledgment
    
    // GATE Control (17 signals from SET_GATE register)
    // logic         gate_mode1;           // Gate control mode 1
    // logic         gate_mode2;           // Gate control mode 2
    // logic         gate_cs1;             // Gate chip select 1
    // logic         gate_cs2;             // Gate chip select 2
    // logic         gate_sel;             // Gate selection
    // logic [11:0]  stv_sel_*;            // STV selection signals (12 bits)

    //==========================================================================
    // Phase 2 Output Signals (TODO - Not Yet Implemented)
    //==========================================================================
    // Timing Control
    // logic [23:0]  cycle_width;          // FSM-based multiplexed cycle width
    // logic [15:0]  mux_image_height;     // FSM-based multiplexed image height
    // logic [15:0]  frame_rpt;            // Frame repeat count
    
    // CSI2 Interface
    // logic [15:0]  max_v_count;          // Maximum vertical count
    // logic [23:0]  max_h_count;          // Maximum horizontal count
    // logic [15:0]  csi2_word_count;      // CSI-2 word count

    //==========================================================================
    // Phase 3 Output Signals (TODO - AED System)
    //==========================================================================
    // AED Control
    // logic [15:0]  aed_th;               // AED threshold
    // logic [15:0]  nega_aed_th;          // Negative AED threshold
    // logic [15:0]  posi_aed_th;          // Positive AED threshold
    
    // Gate XAO Outputs (12 signals: gate_xao_0 ~ gate_xao_5, each H/L)
    // logic [15:0]  gate_xao_0_h;
    // logic [15:0]  gate_xao_0_l;
    // ... (10 more signals)

    //==========================================================================
    // Phase 4 Output Signals (TODO - ROIC Control)
    //==========================================================================
    // TI ROIC Control
    // logic         ti_roic_sync;         // TI ROIC synchronization
    // logic         ti_roic_str;          // TI ROIC strobe
    
    // Deserializer Control
    // logic [7:0]   des_*;                // Deserializer control signals

    //==========================================================================
    // Phase 5 Output Signals (TODO - Sequence Table)
    //==========================================================================
    // Sequence LUT
    // logic [15:0]  seq_lut_*;            // Sequence lookup table signals
    // logic [7:0]   acq_mode;             // Acquisition mode

    //==========================================================================
    // DUT Modport (for testbench)
    //==========================================================================
    modport dut (
        // Clocks and Resets
        input  eim_clk,
        input  eim_rst,
        input  fsm_clk,
        input  rst,
        
        // FSM State Inputs
        input  fsm_rst_index,
        input  fsm_init_index,
        input  fsm_back_bias_index,
        input  fsm_flush_index,
        input  fsm_aed_read_index,
        input  fsm_exp_index,
        input  fsm_read_index,
        input  fsm_idle_index,
        
        // System Status Inputs
        input  ready_to_get_image,
        input  aed_ready_done,
        input  panel_stable_exist,
        input  exp_read_exist,
        
        // Register Access Interface
        input  reg_read_index,
        input  reg_addr,
        input  reg_data,
        input  reg_data_index,
        
        // Register Read Outputs
        output reg_read_out,
        output read_data_en,
        
        // System Control Outputs
        output state_led_ctr,
        output reg_map_sel
    );

    //==========================================================================
    // TB Modport (for testbench driver)
    //==========================================================================
    modport tb (
        // Clocks (input only)
        input  eim_clk,
        input  fsm_clk,
        
        // Outputs from TB (inputs to DUT)
        output eim_rst,
        output rst,
        output fsm_rst_index,
        output fsm_init_index,
        output fsm_back_bias_index,
        output fsm_flush_index,
        output fsm_aed_read_index,
        output fsm_exp_index,
        output fsm_read_index,
        output fsm_idle_index,
        output ready_to_get_image,
        output aed_ready_done,
        output panel_stable_exist,
        output exp_read_exist,
        output reg_read_index,
        output reg_addr,
        output reg_data,
        output reg_data_index,
        
        // Inputs to TB (outputs from DUT)
        input  reg_read_out,
        input  read_data_en,
        input  state_led_ctr,
        input  reg_map_sel
    );

    //==========================================================================
    // Monitor Modport (for verification)
    //==========================================================================
    modport monitor (
        input eim_clk,
        input fsm_clk,
        input eim_rst,
        input rst,
        input fsm_rst_index,
        input fsm_init_index,
        input fsm_back_bias_index,
        input fsm_flush_index,
        input fsm_aed_read_index,
        input fsm_exp_index,
        input fsm_read_index,
        input fsm_idle_index,
        input ready_to_get_image,
        input aed_ready_done,
        input panel_stable_exist,
        input exp_read_exist,
        input reg_read_index,
        input reg_addr,
        input reg_data,
        input reg_data_index,
        input reg_read_out,
        input read_data_en,
        input state_led_ctr,
        input reg_map_sel
    );

endinterface

//==============================================================================
// Parameter Package: reg_map_params_pkg
// Description: Common parameters and types for register map
//==============================================================================
package reg_map_params_pkg;

    //==========================================================================
    // Clock Parameters
    //==========================================================================
    parameter real EIM_CLK_FREQ = 100.0e6;     // 100 MHz
    parameter real FSM_CLK_FREQ = 20.0e6;      // 20 MHz
    parameter real EIM_CLK_PERIOD = 10.0;      // ns
    parameter real FSM_CLK_PERIOD = 50.0;      // ns

    //==========================================================================
    // Register Map Parameters
    //==========================================================================
    parameter int REG_ADDR_WIDTH = 16;         // Register address width
    parameter int REG_DATA_WIDTH = 16;         // Register data width
    parameter int REG_MEMORY_SIZE = 512;       // Total register count (0x000~0x1FF)

    //==========================================================================
    // FSM State Encoding
    //==========================================================================
    typedef enum logic [2:0] {
        FSM_STATE_RESET     = 3'b000,
        FSM_STATE_INIT      = 3'b001,
        FSM_STATE_BACK_BIAS = 3'b010,
        FSM_STATE_FLUSH     = 3'b011,
        FSM_STATE_AED_READ  = 3'b100,
        FSM_STATE_EXPOSURE  = 3'b101,
        FSM_STATE_READ      = 3'b110,
        FSM_STATE_IDLE      = 3'b111
    } fsm_state_t;

    //==========================================================================
    // FSM Register Bit Definitions (ADDR_FSM_REG = 0x00FF)
    //==========================================================================
    parameter int FSM_REG_STATE_LSB        = 0;   // [2:0] FSM state
    parameter int FSM_REG_READY_TO_GET_BIT = 3;   // [3] ready_to_get_image
    parameter int FSM_REG_AED_READY_BIT    = 4;   // [4] aed_ready_done
    parameter int FSM_REG_EXP_READ_BIT     = 5;   // [5] exp_read_exist
    parameter int FSM_REG_PANEL_STABLE_BIT = 6;   // [6] panel_stable_exist
    parameter int FSM_REG_RESERVED_BIT     = 7;   // [7] reserved

    //==========================================================================
    // Register Transaction Type
    //==========================================================================
    typedef enum logic [1:0] {
        REG_TRANS_IDLE  = 2'b00,
        REG_TRANS_WRITE = 2'b01,
        REG_TRANS_READ  = 2'b10
    } reg_trans_type_t;

    //==========================================================================
    // Register Access Structure
    //==========================================================================
    typedef struct packed {
        logic [15:0] addr;
        logic [15:0] data;
        logic        is_read;
        logic        valid;
    } reg_transaction_t;

endpackage

`endif // REG_MAP_INTERFACE_SV

//==============================================================================
// End of reg_map_interface.sv
//==============================================================================
