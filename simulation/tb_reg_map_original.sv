//==============================================================================
// Project     : BLUE Platform - X-ray Detector System
// Module      : tb_reg_map_original.sv
// Description : Testbench for Original Register Map (reg_map.sv)
//               Verifies original module works correctly with proper EIM protocol
//
// Copyright (c) 2024-2025 H&abyz Inc.
// Author      : drake.lee (holee9@gmail.com)
// Created     : 2025-12-05
//==============================================================================

`timescale 1ns/1ps
`include "../source/p_define.sv"

module tb_reg_map_original;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter EIM_CLK_PERIOD = 10;     // 100MHz = 10ns
    parameter FSM_CLK_PERIOD = 50;     // 20MHz = 50ns

    //==========================================================================
    // Clock and Reset
    //==========================================================================
    logic         eim_clk;
    logic         eim_rst;
    logic         fsm_clk;
    logic         rst;

    //==========================================================================
    // Register Interface Signals
    //==========================================================================
    logic         reg_read_index;
    logic [15:0]  reg_addr;
    logic [15:0]  reg_data;
    logic         reg_addr_index;
    logic         reg_data_index;
    logic [15:0]  reg_read_out;
    logic         read_data_en;

    //==========================================================================
    // FSM State Signals
    //==========================================================================
    logic         fsm_rst_index;
    logic         fsm_init_index;
    logic         fsm_back_bias_index;
    logic         fsm_flush_index;
    logic         fsm_aed_read_index;
    logic         fsm_exp_index;
    logic         fsm_read_index;
    logic         fsm_idle_index;

    //==========================================================================
    // Other Input Signals
    //==========================================================================
    logic         exp_req;
    logic         ready_to_get_image;
    logic         aed_ready_done;
    logic         panel_stable_exist;
    logic         exp_read_exist;
    wire  [15:0]  gate_gpio_data;
    logic [23:0]  readout_width;
    
    // Drive gate_gpio_data
    assign gate_gpio_data = 16'h0000;

    //==========================================================================
    // Test Statistics
    //==========================================================================
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial begin
        eim_clk = 0;
        forever #(EIM_CLK_PERIOD/2) eim_clk = ~eim_clk;
    end

    initial begin
        fsm_clk = 0;
        forever #(FSM_CLK_PERIOD/2) fsm_clk = ~fsm_clk;
    end

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    reg_map u_reg_map (
        .eim_clk                (eim_clk),
        .eim_rst                (eim_rst),
        .fsm_clk                (fsm_clk),
        .rst                    (rst),
        .exp_req                (exp_req),
        .fsm_rst_index          (fsm_rst_index),
        .fsm_init_index         (fsm_init_index),
        .fsm_back_bias_index    (fsm_back_bias_index),
        .fsm_flush_index        (fsm_flush_index),
        .fsm_aed_read_index     (fsm_aed_read_index),
        .fsm_exp_index          (fsm_exp_index),
        .fsm_read_index         (fsm_read_index),
        .fsm_idle_index         (fsm_idle_index),
        .gate_gpio_data         (gate_gpio_data),
        .ready_to_get_image     (ready_to_get_image),
        .aed_ready_done         (aed_ready_done),
        .panel_stable_exist     (panel_stable_exist),
        .exp_read_exist         (exp_read_exist),
        .reg_read_index         (reg_read_index),
        .reg_addr               (reg_addr),
        .reg_data               (reg_data),
        .reg_addr_index         (reg_addr_index),
        .reg_data_index         (reg_data_index),
        .reg_read_out           (reg_read_out),
        .read_data_en           (read_data_en),
        .readout_width          (readout_width),
        // Outputs (not monitored in this test)
        .en_pwr_dwn             (),
        .en_pwr_off             (),
        .system_rst             (),
        .reset_fsm              (),
        .org_reset_fsm          (),
        .dummy_get_image        (),
        .burst_get_image        (),
        .get_dark               (),
        .get_bright             (),
        .cmd_get_bright         (),
        .en_aed                 (),
        .aed_th                 (),
        .nega_aed_th            (),
        .posi_aed_th            (),
        .sel_aed_roic           (),
        .num_trigger            (),
        .sel_aed_test_roic      (),
        .ready_aed_read         (),
        .aed_dark_delay         (),
        .en_back_bias           (),
        .en_flush               (),
        .en_panel_stable        (),
        .cycle_width            (),
        .mux_image_height       (),
        .dsp_image_height       (),
        .frame_rpt              (),
        .saturation_flush_repeat(),
        .readout_count          (),
        .max_v_count            (),
        .max_h_count            (),
        .csi2_word_count        (),
        .roic_burst_cycle       (),
        .start_roic_burst_clk   (),
        .end_roic_burst_clk     (),
        .gate_mode1             (),
        .gate_mode2             (),
        .gate_cs1               (),
        .gate_cs2               (),
        .gate_sel               (),
        .gate_ud                (),
        .gate_stv_mode          (),
        .gate_oepsn             (),
        .gate_lr1               (),
        .gate_lr2               (),
        .stv_sel_h              (),
        .stv_sel_l1             (),
        .stv_sel_r1             (),
        .stv_sel_l2             (),
        .stv_sel_r2             (),
        .up_back_bias           (),
        .dn_back_bias           (),
        .ti_roic_tp_sel         (),
        .ti_roic_str            (),
        .ti_roic_reg_addr       (),
        .ti_roic_reg_data       (),
        .ti_roic_deser_reset    (),
        .ti_roic_deser_dly_tap_ld(),
        .ti_roic_deser_dly_tap_in(),
        .ti_roic_deser_dly_data_ce(),
        .ti_roic_deser_dly_data_inc(),
        .ti_roic_deser_align_mode(),
        .ti_roic_deser_align_start(),
        .ti_roic_deser_shift_set(),
        .seq_lut_addr           (),
        .seq_lut_data           (),
        .seq_lut_control        (),
        .acq_mode               (),
        .seq_state_read         (),
        .up_switch_sync         (),
        .dn_switch_sync         ()
    );

    //==========================================================================
    // Task: Write Register (EIM Protocol)
    //==========================================================================
    task write_register(input [15:0] addr, input [15:0] data);
        begin
            // EIM Write Protocol for original module:
            // 1. Setup address with reg_addr_index=1 (generates up_* signal)
            // 2. Keep reg_addr_index=1 and assert reg_data_index=1
            // 3. up_* && reg_data_index triggers actual write
            
            @(posedge eim_clk);
            reg_addr = addr;
            reg_data = data;
            reg_read_index = 0;
            reg_addr_index = 1;  // Start address phase
            reg_data_index = 0;
            
            @(posedge eim_clk);
            // Keep addr_index high and assert data_index
            // This ensures up_* signal is still high when data_index goes high
            reg_data_index = 1;  // Data phase (addr_index still = 1)
            $display("[%0t] WRITE Phase: addr_index=%b, data_index=%b, addr=0x%04X, data=0x%04X", 
                     $time, reg_addr_index, reg_data_index, reg_addr, reg_data);
            
            @(posedge eim_clk);
            // Hold data_index for one more clock to ensure write completes
            @(posedge eim_clk);
            // Deassert both signals
            reg_data_index = 0;
            reg_addr_index = 0;
            
            @(posedge eim_clk);
            $display("[%0t] WRITE: Addr=0x%04X, Data=0x%04X", $time, addr, data);
        end
    endtask

    //==========================================================================
    // Task: Read Register (EIM Protocol with Extended Hold Time)
    //==========================================================================
    task read_register(input [15:0] addr, output [15:0] data);
        begin
            // Setup address and hold for extended period (EIM protocol requirement)
            @(posedge eim_clk);
            reg_addr = addr;
            reg_data_index = 0;
            reg_addr_index = 1;  // Assert address valid
            reg_read_index = 0;
            
            // Keep address stable and assert read request
            @(posedge eim_clk);
            reg_read_index = 1;  // Assert read while address is valid
            
            // Hold all signals stable for pipeline to complete
            // Original module needs: dn_* generation (1) + reg_out_tmp load (1) + s_reg_read_out OR (1) = 3 clocks minimum
            @(posedge eim_clk);  // Clock 1: dn_* pulse
            @(posedge eim_clk);  // Clock 2: reg_out_tmp assignment
            @(posedge eim_clk);  // Clock 3: s_reg_read_out OR operation
            @(posedge eim_clk);  // Clock 4: Data stable
            @(posedge eim_clk);  // Clock 5: Sample (add margin for safety)
            
            // Sample output
            data = reg_read_out;
            
            // Deassert signals
            @(posedge eim_clk);
            reg_read_index = 0;
            reg_addr_index = 0;
            
            @(posedge eim_clk);
            $display("[%0t] READ:  Addr=0x%04X, Data=0x%04X", $time, addr, data);
        end
    endtask

    //==========================================================================
    // Task: Test Register Write and Read
    //==========================================================================
    task test_register(input [15:0] addr, input [15:0] write_val, input [15:0] expected, input string name);
        logic [15:0] read_val;
        begin
            test_count++;
            
            // Write
            write_register(addr, write_val);
            
            // Wait for write to settle
            repeat(3) @(posedge eim_clk);
            
            // Read
            read_register(addr, read_val);
            
            // Compare
            if (read_val === expected) begin
                pass_count++;
                $display("[PASS] Test #%0d: %s - Expected: 0x%04X, Got: 0x%04X", 
                         test_count, name, expected, read_val);
            end else begin
                fail_count++;
                $display("[FAIL] Test #%0d: %s - Expected: 0x%04X, Got: 0x%04X", 
                         test_count, name, expected, read_val);
            end
            $display("");
        end
    endtask

    //==========================================================================
    // Main Test Sequence
    //==========================================================================
    initial begin
        $display("========================================");
        $display("  Original reg_map.sv Testbench");
        $display("  EIM Protocol Verification");
        $display("========================================\n");

        // Initialize
        eim_rst = 0;
        rst = 0;
        reg_read_index = 0;
        reg_addr = 0;
        reg_data = 0;
        reg_addr_index = 0;
        reg_data_index = 0;
        
        fsm_rst_index = 1;  // Start in RESET state
        fsm_init_index = 0;
        fsm_back_bias_index = 0;
        fsm_flush_index = 0;
        fsm_aed_read_index = 0;
        fsm_exp_index = 0;
        fsm_read_index = 0;
        fsm_idle_index = 0;
        
        ready_to_get_image = 0;
        aed_ready_done = 0;
        panel_stable_exist = 0;
        exp_read_exist = 0;
        exp_req = 0;
        readout_width = 24'h000000;

        // Release reset
        repeat(10) @(posedge eim_clk);
        eim_rst = 1;
        rst = 1;
        repeat(10) @(posedge eim_clk);
        
        $display("[TEST 1] Basic Register Write/Read");
        $display("Testing registers in reg_out_tmp_0 group\n");
        
        // Test SYS_CMD_REG (0x0001)
        test_register(`ADDR_SYS_CMD_REG, 16'h1234, 16'h1234, "SYS_CMD_REG");
        
        // Test OP_MODE_REG (0x0002)
        test_register(`ADDR_OP_MODE_REG, 16'h5678, 16'h5678, "OP_MODE_REG");
        
        // Test SET_GATE (0x0003)
        test_register(`ADDR_SET_GATE, 16'hABCD, 16'hABCD, "SET_GATE");
        
        // Test GATE_SIZE (0x0004)
        test_register(`ADDR_GATE_SIZE, 16'h0200, 16'h0200, "GATE_SIZE");
        
        // Test PWR_OFF_DWN (0x0005)
        test_register(`ADDR_PWR_OFF_DWN, 16'h00FF, 16'h00FF, "PWR_OFF_DWN");
        
        $display("\n[TEST 2] FSM Register (Read-Only)");
        // FSM register is updated by FSM state inputs
        begin
            logic [15:0] fsm_val;
            fsm_idle_index = 1;
            fsm_rst_index = 0;
            repeat(10) @(posedge fsm_clk);  // Wait for FSM state to update
            
            read_register(`ADDR_FSM_REG, fsm_val);
            test_count++;
            if (fsm_val[2:0] == 3'b111) begin
                pass_count++;
                $display("[PASS] Test #%0d: FSM_REG IDLE state - Expected: 0x*7, Got: 0x%04X\n", test_count, fsm_val);
            end else begin
                fail_count++;
                $display("[FAIL] Test #%0d: FSM_REG IDLE state - Expected: 0x*7, Got: 0x%04X\n", test_count, fsm_val);
            end
        end
        
        $display("[TEST 3] Pattern Tests");
        test_register(`ADDR_SET_GATE, 16'h0000, 16'h0000, "SET_GATE (0x0000)");
        test_register(`ADDR_SET_GATE, 16'hFFFF, 16'hFFFF, "SET_GATE (0xFFFF)");
        test_register(`ADDR_SET_GATE, 16'hAAAA, 16'hAAAA, "SET_GATE (0xAAAA)");
        test_register(`ADDR_SET_GATE, 16'h5555, 16'h5555, "SET_GATE (0x5555)");
        
        // Final Summary
        $display("\n========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Total Tests : %0d", test_count);
        $display("  Passed      : %0d", pass_count);
        $display("  Failed      : %0d", fail_count);
        $display("  Pass Rate   : %0d%%", (pass_count * 100) / test_count);
        $display("========================================\n");
        
        if (fail_count == 0) begin
            $display("SUCCESS: All tests passed!");
        end else begin
            $display("FAILURE: %0d tests failed", fail_count);
        end
        
        $finish;
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #10000000;  // 10ms timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule
