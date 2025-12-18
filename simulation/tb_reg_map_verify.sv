`timescale 1ns / 1ps
`include "../source/p_define.sv"

//==============================================================================
// Testbench: Compare reg_map (original) vs reg_map_refacto
//==============================================================================
module tb_reg_map_compare;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter real CLK_PERIOD = 10;  // 100MHz
    parameter real CLK_50M_PERIOD = 20;  // 50MHz
    parameter real SCLK_PERIOD = 200;  // 5MHz for SPI (200ns period)
    localparam HEADER  = 2;
    localparam PAYLOAD = 16;
    localparam ADDRSZ  = 14;
    localparam PKTSZ   = HEADER + ADDRSZ + PAYLOAD;

    //==========================================================================
    // Clock and Reset
    //==========================================================================
    logic clk = 1'b0;
    logic clk_50M = 1'b1;
    logic m_sclk_in = 1'b1;
    
    // Active low reset for reg_map modules
    logic reset_n = 1'b0;  // Active low - start in reset
    // Active high reset for SPI modules
    logic reset = 1'b1;    // Active high - start in reset
    
    always #(CLK_PERIOD/2) clk = ~clk;
    always #(CLK_50M_PERIOD/2) clk_50M = ~clk_50M;
    always #(SCLK_PERIOD/2) m_sclk_in = ~m_sclk_in;
    
    initial begin
        reset_n = 1'b0;  // Assert reset (active low)
        reset = 1'b1;    // Assert reset (active high)
        #(CLK_PERIOD*5);
        reset_n = 1'b1;  // Release reset
        reset = 1'b0;    // Release reset
    end

    //==========================================================================
    // SPI Master Signals
    //==========================================================================
    logic m_start = 1'b0;
    logic [1:0] slaveselect = 2'b00;
    logic [HEADER-1:0] masterHeader;
    logic [ADDRSZ-1:0] masterAddrToSend;
    logic [PAYLOAD-1:0] masterDataToSend;
    logic [PAYLOAD-1:0] masterDataReceived;
    
    // SPI wires
    logic m_SCLK, m_MOSI, m_MISO;
    logic [2:0] m_CS;
    logic spi_active;
    assign spi_active = ~m_CS[0];  // CS active low
    
    //==========================================================================
    // SPI Slave Outputs (connected to both reg_maps)
    //==========================================================================
    logic spi_start_flag;
    logic [ADDRSZ-1:0] slave_reg_addr;
    logic slave_addr_valid;
    logic [PAYLOAD-1:0] slave_reg_data;
    logic slave_reg_data_valid;
    logic slave_rw_out;

    logic [15:0] slave_reg_addr_16;
    //==========================================================================
    // Common Inputs for both reg_maps
    //==========================================================================
    logic exp_req = 1'b0;
    logic ready_to_get_image = 1'b0;
    logic aed_ready_done = 1'b0;
    logic panel_stable_exist = 1'b0;
    logic exp_read_exist = 1'b0;
    logic [23:0] readout_width = 24'd0;
    logic [63:0] seq_lut_read_data = 64'd0;
    logic [15:0] seq_state_read = 16'd0;
    logic [4:0] ti_roic_deser_align_shift[11:0];
    logic [11:0] ti_roic_deser_align_done = 12'd0;
    logic fsm_rst_index = 1'b1;
    logic fsm_init_index = 1'b0;
    logic fsm_back_bias_index = 1'b0;
    logic fsm_flush_index = 1'b0;
    logic fsm_aed_read_index = 1'b0;
    logic fsm_exp_index = 1'b0;
    logic fsm_read_index = 1'b0;
    logic fsm_idle_index = 1'b0;

    // Initialize array
    initial begin
        for (int i=0; i<12; i++) ti_roic_deser_align_shift[i] = 5'd0;
    end

    //==========================================================================
    // Original Module Outputs (TODO 1.1)
    //==========================================================================
    logic [15:0] orig_reg_read_out;
    logic orig_read_data_en;
    logic orig_system_rst;
    logic orig_reset_fsm;
    logic orig_gate_mode1, orig_gate_mode2;
    logic orig_gate_cs1, orig_gate_cs2;
    logic orig_gate_sel, orig_gate_ud;
    logic orig_gate_stv_mode, orig_gate_oepsn;
    logic orig_gate_lr1, orig_gate_lr2;
    logic [15:0] orig_gate_size;
    logic [15:0] orig_max_v_count, orig_max_h_count;
    logic [15:0] orig_csi2_word_count;

    //==========================================================================
    // Refactored Module Outputs (TODO 1.1)
    //==========================================================================
    logic [15:0] refac_reg_read_out;
    logic refac_read_data_en;
    logic refac_system_rst;
    logic refac_reset_fsm;
    logic refac_gate_mode1, refac_gate_mode2;
    logic refac_gate_cs1, refac_gate_cs2;
    logic refac_gate_sel, refac_gate_ud;
    logic refac_gate_stv_mode, refac_gate_oepsn;
    logic refac_gate_lr1, refac_gate_lr2;
    logic [15:0] refac_gate_size;
    logic [15:0] refac_max_v_count, refac_max_h_count;
    logic [15:0] refac_csi2_word_count;

    //==========================================================================
    // SPI Master (Single Instance)
    //==========================================================================
    spi_master #(
        .pktsz(PKTSZ), 
        .header(HEADER), 
        .payload(PAYLOAD), 
        .addrsz(ADDRSZ)
    ) u_spi_master (
        .clk(clk_50M), 
        .reset(reset), 
        .start(m_start),
        .slaveselect(slaveselect),
        .masterHeader(masterHeader),
        .masterAddrToSend(masterAddrToSend),
        .masterDataToSend(masterDataToSend),
        .masterDataReceived(masterDataReceived),
        .SCLK(m_SCLK), 
        .CS(m_CS), 
        .MOSI(m_MOSI), 
        .MISO(m_MISO)
    );

    //==========================================================================
    // SPI Slave (Single Instance)
    //==========================================================================
    spi_slave #(
        .header(HEADER),
        .payload(PAYLOAD),
        .addrsz(ADDRSZ),
        .pktsz(PKTSZ)
    ) u_spi_slave (
        .clk(clk),
        .reset(reset),
        .SCLK(m_SCLK),
        .SSB(m_CS[0]),
        .MOSI(m_MOSI),
        .MISO(m_MISO),
        .spi_start_flag(spi_start_flag),
        .read_data(orig_reg_read_out),  // Read from original module
        .read_en(orig_read_data_en),
        .reg_addr(slave_reg_addr),
        .addr_valid(slave_addr_valid),
        .wr_data(slave_reg_data),
        .wr_data_valid(slave_reg_data_valid),
        .rw_out(slave_rw_out)
    );

    assign slave_reg_addr_16 = {2'b00, slave_reg_addr};  // Zero-extend to 16 bits
    //==========================================================================
    // Original reg_map Instance
    //==========================================================================
    reg_map u_reg_map_orig (
        .eim_clk(clk),
        .eim_rst(reset_n),
        .fsm_clk(clk),
        .rst(reset_n),
        .reg_addr(slave_reg_addr_16),
        .reg_read_index(slave_rw_out & spi_active),
        .reg_addr_index(slave_addr_valid),
        .reg_data_index(slave_reg_data_valid),
        .reg_data(slave_reg_data),
        
        // Inputs
        .exp_req(exp_req),
        .ready_to_get_image(ready_to_get_image),
        .aed_ready_done(aed_ready_done),
        .panel_stable_exist(panel_stable_exist),
        .exp_read_exist(exp_read_exist),
        .readout_width(readout_width),
        .seq_lut_read_data(seq_lut_read_data),
        .seq_state_read(seq_state_read),
        .ti_roic_deser_align_shift(ti_roic_deser_align_shift),
        .ti_roic_deser_align_done(ti_roic_deser_align_done),
        .fsm_rst_index(fsm_rst_index),
        .fsm_init_index(fsm_init_index),
        .fsm_back_bias_index(fsm_back_bias_index),
        .fsm_flush_index(fsm_flush_index),
        .fsm_aed_read_index(fsm_aed_read_index),
        .fsm_exp_index(fsm_exp_index),
        .fsm_read_index(fsm_read_index),
        .fsm_idle_index(fsm_idle_index),
        
        // Outputs - TODO 1.1
        .reg_read_out(orig_reg_read_out),
        .read_data_en(orig_read_data_en),
        .en_pwr_dwn(),
        .en_pwr_off(),
        .system_rst(orig_system_rst),
        .reset_fsm(orig_reset_fsm),
        .gate_mode1(orig_gate_mode1),
        .gate_mode2(orig_gate_mode2),
        .gate_cs1(orig_gate_cs1),
        .gate_cs2(orig_gate_cs2),
        .gate_sel(orig_gate_sel),
        .gate_ud(orig_gate_ud),
        .gate_stv_mode(orig_gate_stv_mode),
        .gate_oepsn(orig_gate_oepsn),
        .gate_lr1(orig_gate_lr1),
        .gate_lr2(orig_gate_lr2),
        .gate_size(orig_gate_size),
        .max_v_count(orig_max_v_count),
        .max_h_count(orig_max_h_count),
        .csi2_word_count(orig_csi2_word_count),
        
        // Unconnected outputs (TODO 1.2+)
        .gate_gpio_data(),
        .org_reset_fsm(),
        .dummy_get_image(),
        .burst_get_image(),
        .get_dark(),
        .get_bright(),
        .cmd_get_bright(),
        .en_aed(),
        .aed_dark_delay(),
        .en_back_bias(),
        .en_flush(),
        .en_panel_stable(),
        .aed_th(),
        .nega_aed_th(),
        .posi_aed_th(),
        .sel_aed_roic(),
        .num_trigger(),
        .sel_aed_test_roic(),
        .ready_aed_read(),
        .cycle_width(),
        .mux_image_height(),
        .dsp_image_height(),
        .frame_rpt(),
        .saturation_flush_repeat(),
        .readout_count(),
        .roic_burst_cycle(),
        .start_roic_burst_clk(),
        .end_roic_burst_clk(),
        .stv_sel_h(),
        .stv_sel_l1(),
        .stv_sel_r1(),
        .stv_sel_l2(),
        .stv_sel_r2(),
        .up_back_bias(),
        .dn_back_bias(),
        .dn_aed_gate_xao_0(),
        .dn_aed_gate_xao_1(),
        .dn_aed_gate_xao_2(),
        .dn_aed_gate_xao_3(),
        .dn_aed_gate_xao_4(),
        .dn_aed_gate_xao_5(),
        .up_aed_gate_xao_0(),
        .up_aed_gate_xao_1(),
        .up_aed_gate_xao_2(),
        .up_aed_gate_xao_3(),
        .up_aed_gate_xao_4(),
        .up_aed_gate_xao_5(),
        .ti_roic_sync(),
        .ti_roic_tp_sel(),
        .ti_roic_str(),
        .ti_roic_reg_addr(),
        .ti_roic_reg_data(),
        .ti_roic_deser_reset(),
        .ti_roic_deser_dly_tap_ld(),
        .ti_roic_deser_dly_tap_in(),
        .ti_roic_deser_dly_data_ce(),
        .ti_roic_deser_dly_data_inc(),
        .ti_roic_deser_align_mode(),
        .ti_roic_deser_align_start(),
        .ti_roic_deser_shift_set(),
        .ld_io_delay_tab(),
        .io_delay_tab(),
        .en_16bit_adc(),
        .en_test_pattern_col(),
        .en_test_pattern_row(),
        .en_test_roic_col(),
        .en_test_roic_row(),
        .aed_test_mode1(),
        .aed_test_mode2(),
        .seq_lut_addr(),
        .seq_lut_data(),
        .seq_lut_wr_en(),
        .seq_lut_control(),
        .seq_lut_config_done(),
        .acq_mode(),
        .acq_expose_size(),
        .up_switch_sync(),
        .dn_switch_sync(),
        .exp_ack()
    );

    //==========================================================================
    // Refactored reg_map Instance
    //==========================================================================
    reg_map_refacto u_reg_map_refac (
        .eim_clk(clk),
        .eim_rst(reset_n),
        .fsm_clk(clk),
        .rst(reset_n),
        .reg_addr(slave_reg_addr_16),
        .reg_read_index(slave_rw_out & spi_active),
        .reg_data_index(slave_reg_data_valid),
        .reg_data(slave_reg_data),
        
        // Inputs
        .exp_req(exp_req),
        .ready_to_get_image(ready_to_get_image),
        .aed_ready_done(aed_ready_done),
        .panel_stable_exist(panel_stable_exist),
        .exp_read_exist(exp_read_exist),
        .seq_lut_read_data(seq_lut_read_data),
        .ti_roic_deser_align_shift(ti_roic_deser_align_shift),
        .ti_roic_deser_align_done(ti_roic_deser_align_done),
        .fsm_rst_index(fsm_rst_index),
        .fsm_init_index(fsm_init_index),
        .fsm_back_bias_index(fsm_back_bias_index),
        .fsm_flush_index(fsm_flush_index),
        .fsm_aed_read_index(fsm_aed_read_index),
        .fsm_exp_index(fsm_exp_index),
        .fsm_read_index(fsm_read_index),
        .fsm_idle_index(fsm_idle_index),
        
        // Outputs - TODO 1.1
        .reg_read_out(refac_reg_read_out),
        .read_data_en(refac_read_data_en),
        .system_rst(refac_system_rst),
        .reset_fsm(refac_reset_fsm),
        .gate_mode1(refac_gate_mode1),
        .gate_mode2(refac_gate_mode2),
        .gate_cs1(refac_gate_cs1),
        .gate_cs2(refac_gate_cs2),
        .gate_sel(refac_gate_sel),
        .gate_ud(refac_gate_ud),
        .gate_stv_mode(refac_gate_stv_mode),
        .gate_oepsn(refac_gate_oepsn),
        .gate_lr1(refac_gate_lr1),
        .gate_lr2(refac_gate_lr2),
        .gate_size(refac_gate_size),
        .max_v_count(refac_max_v_count),
        .max_h_count(refac_max_h_count),
        .csi2_word_count(refac_csi2_word_count),
        
        // Unconnected outputs (TODO 1.2+)
        .state_led_ctr(),
        .reg_map_sel(),
        .org_reset_fsm(),
        .gate_gpio_data(),
        .stv_sel_h(),
        .stv_sel_l1(),
        .stv_sel_r1(),
        .stv_sel_l2(),
        .stv_sel_r2(),
        .dn_aed_gate_xao_0(),
        .dn_aed_gate_xao_1(),
        .dn_aed_gate_xao_2(),
        .dn_aed_gate_xao_3(),
        .dn_aed_gate_xao_4(),
        .dn_aed_gate_xao_5(),
        .up_aed_gate_xao_0(),
        .up_aed_gate_xao_1(),
        .up_aed_gate_xao_2(),
        .up_aed_gate_xao_3(),
        .up_aed_gate_xao_4(),
        .up_aed_gate_xao_5(),
        .ti_roic_sync(),
        .ti_roic_tp_sel(),
        .ti_roic_str(),
        .ti_roic_reg_addr(),
        .ti_roic_reg_data(),
        .ti_roic_deser_reset(),
        .ti_roic_deser_dly_tap_ld(),
        .ti_roic_deser_dly_tap_in(),
        .ti_roic_deser_dly_data_ce(),
        .ti_roic_deser_dly_data_inc(),
        .ti_roic_deser_align_mode(),
        .ti_roic_deser_align_start(),
        .ti_roic_deser_shift_set(),
        .up_back_bias(),
        .dn_back_bias(),
        .seq_lut_addr(),
        .seq_lut_data(),
        .seq_lut_wr_en(),
        .seq_lut_control(),
        .seq_lut_config_done(),
        .acq_mode(),
        .acq_expose_size(),
        .get_dark(),
        .get_bright(),
        .cmd_get_bright(),
        .dummy_get_image(),
        .burst_get_image(),
        .en_panel_stable(),
        .en_16bit_adc(),
        .en_test_pattern_col(),
        .en_test_pattern_row(),
        .en_test_roic_col(),
        .en_test_roic_row(),
        .exp_ack()
    );

    //==========================================================================
    // Comparison Flags
    //==========================================================================
    logic match_system_rst;
    logic match_reset_fsm;
    logic match_gate_mode;
    logic match_gate_size;
    logic match_csi2_interface;
    logic all_match;

    always_comb begin
        match_system_rst = (orig_system_rst == refac_system_rst);
        match_reset_fsm = (orig_reset_fsm == refac_reset_fsm);
        match_gate_mode = (orig_gate_mode1 == refac_gate_mode1) &&
                         (orig_gate_mode2 == refac_gate_mode2) &&
                         (orig_gate_cs1 == refac_gate_cs1) &&
                         (orig_gate_cs2 == refac_gate_cs2) &&
                         (orig_gate_sel == refac_gate_sel) &&
                         (orig_gate_ud == refac_gate_ud) &&
                         (orig_gate_stv_mode == refac_gate_stv_mode) &&
                         (orig_gate_oepsn == refac_gate_oepsn) &&
                         (orig_gate_lr1 == refac_gate_lr1) &&
                         (orig_gate_lr2 == refac_gate_lr2);
        match_gate_size = (orig_gate_size == refac_gate_size);
        match_csi2_interface = (orig_max_v_count == refac_max_v_count) &&
                              (orig_max_h_count == refac_max_h_count) &&
                              (orig_csi2_word_count == refac_csi2_word_count);
        all_match = match_system_rst && match_reset_fsm && match_gate_mode && 
                   match_gate_size && match_csi2_interface;
    end

    //==========================================================================
    // Test Tasks
    //==========================================================================
    task do_mspi_write(input [HEADER-1:0] from_header, 
                       input [15:0] from_addr, 
                       input [PAYLOAD-1:0] from_data);
        int i;
        begin
            @(posedge m_sclk_in);
            masterHeader = from_header;
            masterAddrToSend = from_addr[ADDRSZ-1:0];
            masterDataToSend = from_data;
            #1;
            #(SCLK_PERIOD) m_start = 1'b1;
            #(SCLK_PERIOD) m_start = 1'b0;
        end
        
        for (i=0; i<PKTSZ; i++)
            begin
                #(SCLK_PERIOD);
            end
        
        repeat(3) @(posedge m_sclk_in);
    endtask

    task do_mspi_read(input [HEADER-1:0] from_header, 
                      input [15:0] from_addr);
        int i;
        begin
            @(posedge m_sclk_in);
            masterHeader = from_header;
            masterAddrToSend = from_addr[ADDRSZ-1:0];
            #1;
            #(SCLK_PERIOD) m_start = 1'b1;
            #(SCLK_PERIOD) m_start = 1'b0;
        end
        
        for (i=0; i<PKTSZ; i++)
            begin
                #(SCLK_PERIOD);
            end

        repeat(3) @(posedge m_sclk_in);
    endtask

    //==========================================================================
    // Test Stimulus
    //==========================================================================
    initial begin
        $display("=== Starting Testbench ===");
        
        // Wait for reset
        @(posedge reset_n);  // Wait for reset release (active low)
        #100;
        
        // Test 1: Write to SYS_CMD_REG (0x0001) - system_rst
        $display("Test 1: Write SYS_CMD_REG = 0x0001");
        do_mspi_write(2'b10, `ADDR_SYS_CMD_REG, 16'h0001);
        #100;
        $display("Test 1: Read SYS_CMD_REG");
        do_mspi_read(2'b01, `ADDR_SYS_CMD_REG);
        #100;
        $display("Read value: 0x%04h (Expected: 0x0001)", masterDataReceived);
        
        // Test 2: Write to OP_MODE_REG (0x0002) - reset_fsm
        $display("Test 2: Write OP_MODE_REG = 0x0010");
        do_mspi_write(2'b10, `ADDR_OP_MODE_REG, 16'h0010);
        #100;
        $display("Test 2: Read OP_MODE_REG");
        do_mspi_read(2'b01, `ADDR_OP_MODE_REG);
        #100;
        $display("Read value: 0x%04h (Expected: 0x0010)", masterDataReceived);
        
        // Test 3: Write to SET_GATE (0x0003) - gate_mode
        $display("Test 3: Write SET_GATE = 0x0003");
        do_mspi_write(2'b10, `ADDR_SET_GATE, 16'h0003);
        #100;
        $display("Test 3: Read SET_GATE");
        do_mspi_read(2'b01, `ADDR_SET_GATE);
        #100;
        $display("Read value: 0x%04h (Expected: 0x0003)", masterDataReceived);
        
        // Test 4: Write to GATE_SIZE (0x0004) - gate_size
        $display("Test 4: Write GATE_SIZE = 0x0004");
        do_mspi_write(2'b10, `ADDR_GATE_SIZE, 16'h0004);
        #100;
        $display("Test 4: Read GATE_SIZE");
        do_mspi_read(2'b01, `ADDR_GATE_SIZE);
        #100;
        $display("Read value: 0x%04h (Expected: 0x0004)", masterDataReceived);
        
        // Test 5: Write to MAX_V_COUNT (0x00D0) - max_v_count
        $display("Test 5: Write MAX_V_COUNT = 0x001E (30)");
        do_mspi_write(2'b10, `ADDR_MAX_V_COUNT, 16'd30);
        #100;
        $display("Test 5: Read MAX_V_COUNT");
        do_mspi_read(2'b01, `ADDR_MAX_V_COUNT);
        #100;
        $display("Read value: 0x%04h (Expected: 0x001E)", masterDataReceived);
        
        // Print comparison results
        #100;
        $display("=== Comparison Results ===");
        $display("match_system_rst: %b", match_system_rst);
        $display("match_reset_fsm: %b", match_reset_fsm);
        $display("match_gate_mode: %b", match_gate_mode);
        $display("match_gate_size: %b", match_gate_size);
        $display("match_csi2_interface: %b", match_csi2_interface);
        $display("all_match: %b", all_match);
        
        #500;
        $display("=== Test Complete ===");
        $finish;
    end

endmodule
