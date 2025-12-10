//==============================================================================
// Project     : BLUE Platform - X-ray Detector System
// Module      : tb_reg_map_refacto.sv
// Description : Testbench for Register Map Module (Refactored Version)
//
// Copyright (c) 2024-2025 H&abyz Inc.
// All rights reserved.
//
// Author      : drake.lee (holee9@gmail.com)
// Company     : H&abyz Inc.
// Created     : 2025-12-05
//
// # ModelSim/QuestaSim
// vlog -sv p_define_refacto.sv reg_map_refacto.sv tb_reg_map_refacto.sv
// vsim -c tb_reg_map_refacto -do "run -all; quit"

// # Vivado Simulator
// xvlog --sv p_define_refacto.sv reg_map_refacto.sv tb_reg_map_refacto.sv
// xelab tb_reg_map_refacto -debug typical
// xsim tb_reg_map_refacto -runall
//==============================================================================

`timescale 1ns/1ps

module tb_reg_map_refacto;

    //==========================================================================
    // Test Parameters
    //==========================================================================
    parameter EIM_CLK_PERIOD = 10.0;     // 100MHz clock period (ns)
    parameter FSM_CLK_PERIOD = 50.0;     // 20MHz clock period (ns)
    
    //==========================================================================
    // DUT Signals - Clock and Reset
    //==========================================================================
    logic         eim_clk;
    logic         eim_rst;
    logic         fsm_clk;
    logic         rst;

    //==========================================================================
    // DUT Signals - FSM State Inputs
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
    // DUT Signals - System Status Inputs
    //==========================================================================
    logic         ready_to_get_image;
    logic         aed_ready_done;
    logic         panel_stable_exist;
    logic         exp_read_exist;

    //==========================================================================
    // DUT Signals - Register Access Interface
    //==========================================================================
    logic         reg_read_index;
    logic [15:0]  reg_addr;
    logic [15:0]  reg_data;
    logic         reg_data_index;

    //==========================================================================
    // DUT Signals - Register Read Outputs
    //==========================================================================
    wire [15:0]   reg_read_out;
    wire          read_data_en;

    //==========================================================================
    // DUT Signals - System Control Outputs
    //==========================================================================
    wire [7:0]    state_led_ctr;
    wire          reg_map_sel;

    //==========================================================================
    // Test Control Variables
    //==========================================================================
    integer       test_count;
    integer       pass_count;
    integer       fail_count;
    logic [15:0]  expected_data;
    string        test_name;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    reg_map_refacto DUT (
        // Clock and Reset
        .eim_clk            (eim_clk),
        .eim_rst            (eim_rst),
        .fsm_clk            (fsm_clk),
        .rst                (rst),
        
        // FSM State Inputs
        .fsm_rst_index      (fsm_rst_index),
        .fsm_init_index     (fsm_init_index),
        .fsm_back_bias_index(fsm_back_bias_index),
        .fsm_flush_index    (fsm_flush_index),
        .fsm_aed_read_index (fsm_aed_read_index),
        .fsm_exp_index      (fsm_exp_index),
        .fsm_read_index     (fsm_read_index),
        .fsm_idle_index     (fsm_idle_index),
        
        // System Status Inputs
        .ready_to_get_image (ready_to_get_image),
        .aed_ready_done     (aed_ready_done),
        .panel_stable_exist (panel_stable_exist),
        .exp_read_exist     (exp_read_exist),
        
        // Register Access Interface
        .reg_read_index     (reg_read_index),
        .reg_addr           (reg_addr),
        .reg_data           (reg_data),
        .reg_data_index     (reg_data_index),
        
        // Register Read Outputs
        .reg_read_out       (reg_read_out),
        .read_data_en       (read_data_en),
        
        // System Control Outputs
        .state_led_ctr      (state_led_ctr),
        .reg_map_sel        (reg_map_sel)
    );

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
    // Task: Reset Sequence
    //==========================================================================
    task reset_dut();
        begin
            eim_rst = 0;
            rst = 0;
            @(posedge eim_clk);
            @(posedge fsm_clk);
            #(EIM_CLK_PERIOD * 5);
            eim_rst = 1;
            rst = 1;
            #(EIM_CLK_PERIOD * 10);
            $display("[%0t] Reset completed", $time);
        end
    endtask

    //==========================================================================
    // Task: Write Register
    //==========================================================================
    task write_register(input [15:0] addr, input [15:0] data);
        begin
            @(posedge eim_clk);
            reg_addr = addr;
            reg_data = data;
            reg_read_index = 0;
            @(posedge eim_clk);
            reg_data_index = 1;
            @(posedge eim_clk);
            reg_data_index = 0;
            @(posedge eim_clk);
            $display("[%0t] Write: Addr=0x%04X, Data=0x%04X", $time, addr, data);
        end
    endtask

    //==========================================================================
    // Task: Read Register
    //==========================================================================
    task read_register(input [15:0] addr, output [15:0] data);
        begin
            @(posedge eim_clk);
            reg_addr = addr;
            reg_data_index = 0;
            @(posedge eim_clk);
            reg_read_index = 1;
            @(posedge eim_clk);
            @(posedge eim_clk);
            data = reg_read_out;
            reg_read_index = 0;
            @(posedge eim_clk);
            $display("[%0t] Read:  Addr=0x%04X, Data=0x%04X", $time, addr, data);
        end
    endtask

    //==========================================================================
    // Task: Check Register Value
    //==========================================================================
    task check_register(input [15:0] addr, input [15:0] expected, input string name);
        logic [15:0] read_data;
        begin
            test_count++;
            test_name = name;
            read_register(addr, read_data);
            
            if (read_data === expected) begin
                pass_count++;
                $display("[PASS] Test #%0d: %s - Expected: 0x%04X, Got: 0x%04X", 
                         test_count, name, expected, read_data);
            end else begin
                fail_count++;
                $display("[FAIL] Test #%0d: %s - Expected: 0x%04X, Got: 0x%04X", 
                         test_count, name, expected, read_data);
            end
        end
    endtask

    //==========================================================================
    // Task: Set FSM State
    //==========================================================================
    task set_fsm_state(input [2:0] state);
        begin
            fsm_rst_index       = (state == 3'b000);
            fsm_init_index      = (state == 3'b001);
            fsm_back_bias_index = (state == 3'b010);
            fsm_flush_index     = (state == 3'b011);
            fsm_aed_read_index  = (state == 3'b100);
            fsm_exp_index       = (state == 3'b101);
            fsm_read_index      = (state == 3'b110);
            fsm_idle_index      = (state == 3'b111);
            #(FSM_CLK_PERIOD * 5);
            $display("[%0t] FSM State changed to: %0d", $time, state);
        end
    endtask

    //==========================================================================
    // Main Test Sequence
    //==========================================================================
    initial begin
        // Initialize
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize inputs
        reg_read_index = 0;
        reg_addr = 0;
        reg_data = 0;
        reg_data_index = 0;
        
        fsm_rst_index = 0;
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

        $display("========================================");
        $display("  Register Map Refactored Testbench");
        $display("========================================");
        $display("");

        // Test 1: Reset
        $display("[TEST 1] Reset Test");
        reset_dut();
        #(EIM_CLK_PERIOD * 10);

        // Test 2: Write/Read Basic Registers
        $display("");
        $display("[TEST 2] Basic Register Write/Read");
        write_register(16'h0000, 16'h0001);  // REG_MAP_SEL
        check_register(16'h0000, 16'h0001, "REG_MAP_SEL Write/Read");
        
        write_register(16'h0001, 16'h00AA);  // STATE_LED_CTR
        check_register(16'h0001, 16'h00AA, "STATE_LED_CTR Write/Read");

        // Test 3: Read-Only Registers (should not be writable)
        $display("");
        $display("[TEST 3] Read-Only Register Protection");
        write_register(16'h00FF, 16'hDEAD);  // FSM_REG (read-only)
        check_register(16'h00FF, 16'h0000, "FSM_REG Write Protection");
        
        write_register(16'h0110, 16'hBEEF);  // FPGA_VER_H (read-only)
        // Note: FPGA_VER will return actual USR_ACCESSE2 value, not 0
        $display("        FPGA_VER_H is read-only, will return actual config data");

        // Test 4: FSM Register with State Changes
        $display("");
        $display("[TEST 4] FSM Register State Tracking");
        
        set_fsm_state(3'b000);  // RESET state
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h0000, "FSM_REG RESET State");
        
        set_fsm_state(3'b001);  // INIT state
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h0001, "FSM_REG INIT State");
        
        set_fsm_state(3'b101);  // EXPOSURE state
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h0005, "FSM_REG EXPOSURE State");
        
        set_fsm_state(3'b111);  // IDLE state
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h0007, "FSM_REG IDLE State");

        // Test 5: FSM Register with Status Bits
        $display("");
        $display("[TEST 5] FSM Register Status Bits");
        
        ready_to_get_image = 1;
        aed_ready_done = 1;
        panel_stable_exist = 1;
        exp_read_exist = 1;
        set_fsm_state(3'b111);  // IDLE state
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h00FF, "FSM_REG All Status Bits Set");
        
        ready_to_get_image = 0;
        aed_ready_done = 0;
        panel_stable_exist = 0;
        exp_read_exist = 0;
        #(FSM_CLK_PERIOD * 10);
        check_register(16'h00FF, 16'h0007, "FSM_REG All Status Bits Clear");

        // Test 6: Multiple Register Writes
        $display("");
        $display("[TEST 6] Multiple Register Operations");
        write_register(16'h0002, 16'h1234);  // SYS_CMD_REG
        write_register(16'h0003, 16'h5678);  // OP_MODE_REG
        write_register(16'h0004, 16'hABCD);  // SET_GATE
        
        check_register(16'h0002, 16'h1234, "SYS_CMD_REG");
        check_register(16'h0003, 16'h5678, "OP_MODE_REG");
        check_register(16'h0004, 16'hABCD, "SET_GATE");

        // Test 7: Read Constant ROM Values
        $display("");
        $display("[TEST 7] Read-Only Constant Registers");
        check_register(16'h0100, 16'h0000, "ROIC_VENDOR");  // Will show actual value
        check_register(16'h0101, 16'h0000, "PURPOSE");      // Will show actual value
        check_register(16'h0102, 16'h0000, "SIZE_1");       // Will show actual value
        check_register(16'h0103, 16'h0000, "SIZE_2");       // Will show actual value

        // Test 8: Output Signal Verification
        $display("");
        $display("[TEST 8] Output Signal Verification");
        write_register(16'h0000, 16'h0001);  // Enable reg_map_sel
        #(EIM_CLK_PERIOD * 5);
        if (reg_map_sel === 1'b1) begin
            test_count++; pass_count++;
            $display("[PASS] Test #%0d: reg_map_sel Output", test_count);
        end else begin
            test_count++; fail_count++;
            $display("[FAIL] Test #%0d: reg_map_sel Output", test_count);
        end
        
        write_register(16'h0001, 16'h00FF);  // Set all LED bits
        #(EIM_CLK_PERIOD * 5);
        if (state_led_ctr === 8'hFF) begin
            test_count++; pass_count++;
            $display("[PASS] Test #%0d: state_led_ctr Output", test_count);
        end else begin
            test_count++; fail_count++;
            $display("[FAIL] Test #%0d: state_led_ctr Output (Got: 0x%02X)", test_count, state_led_ctr);
        end

        // Test 9: Boundary Address Test
        $display("");
        $display("[TEST 9] Boundary Address Test");
        write_register(16'h01FF, 16'hAAAA);  // Last valid address
        check_register(16'h01FF, 16'hAAAA, "Last Valid Address (0x01FF)");
        
        write_register(16'h0200, 16'hBBBB);  // Out of range (should not write)
        check_register(16'h0200, 16'h0000, "Out of Range Address (0x0200)");

        // Test Summary
        $display("");
        $display("========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Total Tests : %0d", test_count);
        $display("  Passed      : %0d", pass_count);
        $display("  Failed      : %0d", fail_count);
        $display("  Pass Rate   : %0d%%", (pass_count * 100) / test_count);
        $display("========================================");
        
        if (fail_count == 0) begin
            $display("  ALL TESTS PASSED!");
        end else begin
            $display("  SOME TESTS FAILED!");
        end
        $display("========================================");
        
        #(EIM_CLK_PERIOD * 100);
        $finish;
    end

    //==========================================================================
    // Waveform Dump
    //==========================================================================
    initial begin
        $dumpfile("tb_reg_map_refacto.vcd");
        $dumpvars(0, tb_reg_map_refacto);
    end

    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #100000000;  // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule

//==============================================================================
// End of tb_reg_map_refacto.sv
//==============================================================================
