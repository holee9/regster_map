`timescale 1ns / 1ps
`include "../source/p_define_refacto.sv"

//==============================================================================
// Testbench: Full Verification of reg_map_refacto
// Purpose: Complete validation of all reg_map_refacto outputs
//==============================================================================
module tb_reg_map_refacto_full;

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
    logic reset_n = 1'b0;
    // Active high reset for SPI modules
    logic reset = 1'b1;
    
    always #(CLK_PERIOD/2) clk = ~clk;
    always #(CLK_50M_PERIOD/2) clk_50M = ~clk_50M;
    always #(SCLK_PERIOD/2) m_sclk_in = ~m_sclk_in;
    
    initial begin
        reset_n = 1'b0;
        reset = 1'b1;
        #10us;
        reset_n = 1'b1;
        reset = 1'b0;
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
    
    logic m_SCLK, m_MOSI, m_MISO;
    logic [2:0] m_CS;
    logic spi_active;
    assign spi_active = ~m_CS[0];

    //==========================================================================
    // SPI Slave Outputs
    //==========================================================================
    logic spi_start_flag;
    logic [ADDRSZ-1:0] slave_reg_addr;
    logic slave_addr_valid;
    logic [PAYLOAD-1:0] slave_reg_data;
    logic slave_reg_data_valid;
    logic slave_rw_out;
    logic [15:0] slave_reg_addr_16;
    assign slave_reg_addr_16 = {2'b00, slave_reg_addr};  // Zero-extend to 16 bits

    //==========================================================================
    // Common Inputs
    //==========================================================================
    logic exp_req = 1'b0;
    logic ready_to_get_image = 1'b0;
    logic aed_ready_done = 1'b0;
    logic panel_stable_exist = 1'b0;
    logic exp_read_exist = 1'b0;
    logic [63:0] seq_lut_read_data = 64'd0;
    logic [4:0] ti_roic_deser_align_shift[11:0];
    logic [11:0] ti_roic_deser_align_done = 12'd0;
    logic fsm_rst_index = 1'b0;
    logic fsm_init_index = 1'b0;
    logic fsm_back_bias_index = 1'b0;
    logic fsm_flush_index = 1'b0;
    logic fsm_aed_read_index = 1'b0;
    logic fsm_exp_index = 1'b0;
    logic fsm_read_index = 1'b0;
    logic fsm_idle_index = 1'b0;

    initial begin
        for (int i=0; i<12; i++) ti_roic_deser_align_shift[i] = 5'd0;
    end

    //==========================================================================
    // DUT Outputs - All Signals
    //==========================================================================
    logic [15:0] reg_read_out;
    logic read_data_en;
    logic [7:0] state_led_ctr;
    logic reg_map_sel;
    logic system_rst;
    logic org_reset_fsm;
    logic reset_fsm;
    logic [15:0] max_v_count, max_h_count, csi2_word_count;
    logic ti_roic_sync, ti_roic_tp_sel;
    logic [1:0] ti_roic_str;
    logic [15:0] ti_roic_reg_addr, ti_roic_reg_data;
    logic ti_roic_deser_reset, ti_roic_deser_dly_tap_ld;
    logic [4:0] ti_roic_deser_dly_tap_in;
    logic ti_roic_deser_dly_data_ce, ti_roic_deser_dly_data_inc;
    logic ti_roic_deser_align_mode, ti_roic_deser_align_start;
    logic [11:0][4:0] ti_roic_deser_shift_set;
    logic [15:0] up_back_bias, dn_back_bias;
    logic [7:0] seq_lut_addr;
    logic [63:0] seq_lut_data;
    logic seq_lut_wr_en;
    logic [15:0] seq_lut_control;
    logic seq_lut_config_done;
    logic [2:0] acq_mode;
    logic [31:0] acq_expose_size;
    logic get_dark, get_bright, cmd_get_bright, dummy_get_image, burst_get_image;
    logic en_panel_stable, en_16bit_adc;
    logic en_test_pattern_col, en_test_pattern_row;
    logic en_test_roic_col, en_test_roic_row;
    logic exp_ack;
    logic gate_mode1, gate_mode2, gate_cs1, gate_cs2;
    logic gate_sel, gate_ud, gate_stv_mode, gate_oepsn;
    logic gate_lr1, gate_lr2;
    logic stv_sel_h, stv_sel_l1, stv_sel_r1, stv_sel_l2, stv_sel_r2;
    logic [15:0] gate_size, gate_gpio_data;
    logic [15:0] dn_aed_gate_xao_0, dn_aed_gate_xao_1, dn_aed_gate_xao_2;
    logic [15:0] dn_aed_gate_xao_3, dn_aed_gate_xao_4, dn_aed_gate_xao_5;
    logic [15:0] up_aed_gate_xao_0, up_aed_gate_xao_1, up_aed_gate_xao_2;
    logic [15:0] up_aed_gate_xao_3, up_aed_gate_xao_4, up_aed_gate_xao_5;

    //==========================================================================
    // SPI Master Instance
    //==========================================================================
    spi_master #(
        .pktsz(PKTSZ), .header(HEADER), 
        .payload(PAYLOAD), .addrsz(ADDRSZ)
    ) u_spi_master (
        .clk(clk_50M), .reset(reset), 
        .start(m_start), .slaveselect(slaveselect),
        .masterHeader(masterHeader),
        .masterAddrToSend(masterAddrToSend),
        .masterDataToSend(masterDataToSend),
        .masterDataReceived(masterDataReceived),
        .SCLK(m_SCLK), .CS(m_CS), 
        .MOSI(m_MOSI), .MISO(m_MISO)
    );

    //==========================================================================
    // SPI Slave Instance
    //==========================================================================
    spi_slave #(
        .header(HEADER), .payload(PAYLOAD),
        .addrsz(ADDRSZ), .pktsz(PKTSZ)
    ) u_spi_slave (
        .clk(clk), .reset(reset),
        .SCLK(m_SCLK), .SSB(m_CS[0]),
        .MOSI(m_MOSI), .MISO(m_MISO),
        .spi_start_flag(spi_start_flag),
        .read_data(reg_read_out),
        .read_en(read_data_en),
        .reg_addr(slave_reg_addr),
        .addr_valid(slave_addr_valid),
        .wr_data(slave_reg_data),
        .wr_data_valid(slave_reg_data_valid),
        .rw_out(slave_rw_out)
    );

    //==========================================================================
    // DUT: reg_map_refacto Instance
    //==========================================================================
    reg_map_refacto u_dut (
        .eim_clk(clk), .eim_rst(reset_n),
        .fsm_clk(clk), .rst(reset_n),
        .reg_addr(slave_reg_addr_16),
        .reg_read_index(slave_rw_out & spi_active),
        .reg_data_index(slave_reg_data_valid),
        .reg_data(slave_reg_data),
        
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
        
        .reg_read_out(reg_read_out),
        .read_data_en(read_data_en),
        .state_led_ctr(state_led_ctr),
        .reg_map_sel(reg_map_sel),
        .system_rst(system_rst),
        .org_reset_fsm(org_reset_fsm),
        .reset_fsm(reset_fsm),
        .max_v_count(max_v_count),
        .max_h_count(max_h_count),
        .csi2_word_count(csi2_word_count),
        .ti_roic_sync(ti_roic_sync),
        .ti_roic_tp_sel(ti_roic_tp_sel),
        .ti_roic_str(ti_roic_str),
        .ti_roic_reg_addr(ti_roic_reg_addr),
        .ti_roic_reg_data(ti_roic_reg_data),
        .ti_roic_deser_reset(ti_roic_deser_reset),
        .ti_roic_deser_dly_tap_ld(ti_roic_deser_dly_tap_ld),
        .ti_roic_deser_dly_tap_in(ti_roic_deser_dly_tap_in),
        .ti_roic_deser_dly_data_ce(ti_roic_deser_dly_data_ce),
        .ti_roic_deser_dly_data_inc(ti_roic_deser_dly_data_inc),
        .ti_roic_deser_align_mode(ti_roic_deser_align_mode),
        .ti_roic_deser_align_start(ti_roic_deser_align_start),
        .ti_roic_deser_shift_set(ti_roic_deser_shift_set),
        .up_back_bias(up_back_bias),
        .dn_back_bias(dn_back_bias),
        .seq_lut_addr(seq_lut_addr),
        .seq_lut_data(seq_lut_data),
        .seq_lut_wr_en(seq_lut_wr_en),
        .seq_lut_control(seq_lut_control),
        .seq_lut_config_done(seq_lut_config_done),
        .acq_mode(acq_mode),
        .acq_expose_size(acq_expose_size),
        .get_dark(get_dark),
        .get_bright(get_bright),
        .cmd_get_bright(cmd_get_bright),
        .dummy_get_image(dummy_get_image),
        .burst_get_image(burst_get_image),
        .en_panel_stable(en_panel_stable),
        .en_16bit_adc(en_16bit_adc),
        .en_test_pattern_col(en_test_pattern_col),
        .en_test_pattern_row(en_test_pattern_row),
        .en_test_roic_col(en_test_roic_col),
        .en_test_roic_row(en_test_roic_row),
        .exp_ack(exp_ack),
        .gate_mode1(gate_mode1),
        .gate_mode2(gate_mode2),
        .gate_cs1(gate_cs1),
        .gate_cs2(gate_cs2),
        .gate_sel(gate_sel),
        .gate_ud(gate_ud),
        .gate_stv_mode(gate_stv_mode),
        .gate_oepsn(gate_oepsn),
        .gate_lr1(gate_lr1),
        .gate_lr2(gate_lr2),
        .stv_sel_h(stv_sel_h),
        .stv_sel_l1(stv_sel_l1),
        .stv_sel_r1(stv_sel_r1),
        .stv_sel_l2(stv_sel_l2),
        .stv_sel_r2(stv_sel_r2),
        .gate_size(gate_size),
        .gate_gpio_data(gate_gpio_data),
        .dn_aed_gate_xao_0(dn_aed_gate_xao_0),
        .dn_aed_gate_xao_1(dn_aed_gate_xao_1),
        .dn_aed_gate_xao_2(dn_aed_gate_xao_2),
        .dn_aed_gate_xao_3(dn_aed_gate_xao_3),
        .dn_aed_gate_xao_4(dn_aed_gate_xao_4),
        .dn_aed_gate_xao_5(dn_aed_gate_xao_5),
        .up_aed_gate_xao_0(up_aed_gate_xao_0),
        .up_aed_gate_xao_1(up_aed_gate_xao_1),
        .up_aed_gate_xao_2(up_aed_gate_xao_2),
        .up_aed_gate_xao_3(up_aed_gate_xao_3),
        .up_aed_gate_xao_4(up_aed_gate_xao_4),
        .up_aed_gate_xao_5(up_aed_gate_xao_5)
    );

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
        for (i=0; i<PKTSZ; i++) #(SCLK_PERIOD);

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
        for (i=0; i<PKTSZ; i++) #(SCLK_PERIOD);

        repeat(3) @(posedge m_sclk_in);

    endtask

    task test_reg_write_read(input [15:0] addr, input [15:0] wdata, input string name);
        logic [15:0] rdata;
        begin
            $display("[TEST] %s: Write 0x%04h to 0x%04h", name, wdata, addr);
            do_mspi_write(2'b10, addr, wdata);
            #100;
            do_mspi_read(2'b01, addr);
            #100;
            rdata = masterDataReceived;
            if (rdata === wdata)
                $display("  [PASS] Read 0x%04h (Expected: 0x%04h)", rdata, wdata);
            else
                $display("  [FAIL] Read 0x%04h (Expected: 0x%04h)", rdata, wdata);
        end
    endtask

    task test_output_toggle(input [15:0] addr, input [15:0] val0, input [15:0] val1, input string name, input string signal_name);
        string sig_val0, sig_val1;
        logic test_pass;
        begin
            $display("[TOGGLE] %s: Testing %s output toggle", name, signal_name);
            
            // Write value 0 and capture signal
            do_mspi_write(2'b10, addr, val0);
            #200;
            sig_val0 = get_signal_value(signal_name);
            $display("  Write 0x%04h -> %s = %s", val0, signal_name, sig_val0);
            
            // Write value 1 and capture signal
            do_mspi_write(2'b10, addr, val1);
            #200;
            sig_val1 = get_signal_value(signal_name);
            $display("  Write 0x%04h -> %s = %s", val1, signal_name, sig_val1);
            
            // Check if signal toggled
            if (sig_val0 != sig_val1) begin
                $display("  [PASS] Signal toggled: %s -> %s", sig_val0, sig_val1);
                test_pass = 1;
            end else begin
                $display("  [FAIL] Signal did NOT toggle (both = %s)", sig_val0);
                test_pass = 0;
            end
            
            // Verify register readback
            do_mspi_read(2'b01, addr);
            #100;
            if (masterDataReceived === val1) begin
                if (test_pass)
                    $display("  [PASS] Register readback verified (0x%04h)", masterDataReceived);
            end else begin
                $display("  [FAIL] Register readback: expected 0x%04h, got 0x%04h", val1, masterDataReceived);
            end
        end
    endtask

    function string get_signal_value(input string signal_name);
        case(signal_name)
            "system_rst": return $sformatf("%b", system_rst);
            "reset_fsm": return $sformatf("%b", reset_fsm);
            "gate_mode1": return $sformatf("%b", gate_mode1);
            "gate_mode2": return $sformatf("%b", gate_mode2);
            "gate_cs1": return $sformatf("%b", gate_cs1);
            "gate_cs2": return $sformatf("%b", gate_cs2);
            "gate_sel": return $sformatf("%b", gate_sel);
            "gate_ud": return $sformatf("%b", gate_ud);
            "gate_stv_mode": return $sformatf("%b", gate_stv_mode);
            "gate_oepsn": return $sformatf("%b", gate_oepsn);
            "gate_lr1": return $sformatf("%b", gate_lr1);
            "gate_lr2": return $sformatf("%b", gate_lr2);
            "stv_sel_h": return $sformatf("%b", stv_sel_h);
            "stv_sel_l1": return $sformatf("%b", stv_sel_l1);
            "stv_sel_r1": return $sformatf("%b", stv_sel_r1);
            "stv_sel_l2": return $sformatf("%b", stv_sel_l2);
            "stv_sel_r2": return $sformatf("%b", stv_sel_r2);
            "gate_size": return $sformatf("0x%04h", gate_size);
            "max_v_count": return $sformatf("0x%04h", max_v_count);
            "max_h_count": return $sformatf("0x%04h", max_h_count);
            "csi2_word_count": return $sformatf("0x%04h", csi2_word_count);
            "up_back_bias": return $sformatf("0x%04h", up_back_bias);
            "dn_back_bias": return $sformatf("0x%04h", dn_back_bias);
            "ti_roic_sync": return $sformatf("%b", ti_roic_sync);
            "ti_roic_str": return $sformatf("%b", ti_roic_str);
            "en_panel_stable": return $sformatf("%b", en_panel_stable);
            "en_16bit_adc": return $sformatf("%b", en_16bit_adc);
            "get_dark": return $sformatf("%b", get_dark);
            "get_bright": return $sformatf("%b", get_bright);
            "dummy_get_image": return $sformatf("%b", dummy_get_image);
            "burst_get_image": return $sformatf("%b", burst_get_image);
            "acq_mode": return $sformatf("%b", acq_mode);
            "acq_expose_size": return $sformatf("0x%08h", acq_expose_size);
            "gate_gpio_data": return $sformatf("0x%04h", gate_gpio_data);
            "seq_lut_addr": return $sformatf("0x%02h", seq_lut_addr);
            "seq_lut_wr_en": return $sformatf("%b", seq_lut_wr_en);
            "ti_roic_deser_reset": return $sformatf("%b", ti_roic_deser_reset);
            "ti_roic_deser_align_mode": return $sformatf("%b", ti_roic_deser_align_mode);
            "ti_roic_deser_align_start": return $sformatf("%b", ti_roic_deser_align_start);
            default: return "UNKNOWN";
        endcase
    endfunction

    task test_input_readback(input string signal_name, input [15:0] addr, input [15:0] expected_val, input string test_name);
        logic [15:0] rdata;
        begin
            $display("[INPUT-READ] %s: Testing %s readback", test_name, signal_name);
            $display("  Input value set to: 0x%04h", expected_val);
            
            // Read the register
            do_mspi_read(2'b01, addr);
            #100;
            rdata = masterDataReceived;
            
            // Compare and report
            if (rdata === expected_val) begin
                $display("  [PASS] Read 0x%04h (Expected: 0x%04h)", rdata, expected_val);
            end else begin
                $display("  [FAIL] Read 0x%04h (Expected: 0x%04h)", rdata, expected_val);
            end
        end
    endtask

    task test_fsm_state_readback(input [2:0] expected_state, input string state_name);
        logic [15:0] rdata;
        logic [2:0] state_bits;
        begin
            $display("[FSM-READ] Testing FSM state: %s", state_name);
            
            // Read FSM_REG
            do_mspi_read(2'b01, `ADDR_FSM_REG);
            #100;
            rdata = masterDataReceived;
            state_bits = rdata[2:0];
            
            $display("  FSM_REG = 0x%04h, State bits[2:0] = 3'b%03b", rdata, state_bits);
            $display("  [7]=Reserved, [6]=panel_stable, [5]=exp_read, [4]=aed_ready, [3]=ready_to_get");
            $display("  Status bits: [6]=%b [5]=%b [4]=%b [3]=%b", rdata[6], rdata[5], rdata[4], rdata[3]);
            
            // Compare state
            if (state_bits === expected_state) begin
                $display("  [PASS] FSM state = %s (3'b%03b)", state_name, state_bits);
            end else begin
                $display("  [FAIL] FSM state = 3'b%03b (Expected: %s = 3'b%03b)", state_bits, state_name, expected_state);
            end
        end
    endtask

    //==========================================================================
    // Test Stimulus - Comprehensive Register Tests
    //==========================================================================
    initial begin
        $display("=== Starting Full Verification ===");
        $display("Time: %0t", $time);
        
        @(posedge reset_n);
        #100;
        
        //======================================================================
        // 1. System Control Registers (0x0001 - 0x0007)
        //======================================================================
        $display("\n=== 1. System Control Registers ===");
        test_reg_write_read(`ADDR_SYS_CMD_REG, 16'h0001, "SYS_CMD_REG");
        test_reg_write_read(`ADDR_OP_MODE_REG, 16'h007F, "OP_MODE_REG");
        test_reg_write_read(`ADDR_SET_GATE, 16'hC908, "SET_GATE");
        test_reg_write_read(`ADDR_GATE_SIZE, 16'h0200, "GATE_SIZE");
        test_reg_write_read(`ADDR_PWR_OFF_DWN, 16'h0001, "PWR_OFF_DWN");
        test_reg_write_read(`ADDR_READOUT_COUNT, 16'h0005, "READOUT_COUNT");
        test_reg_write_read(`ADDR_REG_MAP_SEL, 16'h0001, "REG_MAP_SEL");
        
        //======================================================================
        // 2. Timing Control Registers (0x0010 - 0x001E)
        //======================================================================
        $display("\n=== 2. Timing Control Registers ===");
        test_reg_write_read(`ADDR_EXPOSE_SIZE, 16'd500, "EXPOSE_SIZE");
        test_reg_write_read(`ADDR_BACK_BIAS_SIZE, 16'd45000, "BACK_BIAS_SIZE");
        test_reg_write_read(`ADDR_IMAGE_HEIGHT, 16'd3072, "IMAGE_HEIGHT");
        test_reg_write_read(`ADDR_CYCLE_WIDTH_FLUSH, 16'd100, "CYCLE_WIDTH_FLUSH");
        test_reg_write_read(`ADDR_CYCLE_WIDTH_AED, 16'd3660, "CYCLE_WIDTH_AED");
        test_reg_write_read(`ADDR_CYCLE_WIDTH_READ, 16'd1024, "CYCLE_WIDTH_READ");
        test_reg_write_read(`ADDR_REPEAT_BACK_BIAS, 16'd1, "REPEAT_BACK_BIAS");
        test_reg_write_read(`ADDR_REPEAT_FLUSH, 16'd2, "REPEAT_FLUSH");
        test_reg_write_read(`ADDR_SATURATION_FLUSH_REPEAT, 16'd2, "SATURATION_FLUSH_REPEAT");
        test_reg_write_read(`ADDR_EXP_DELAY, 16'd100, "EXP_DELAY");
        test_reg_write_read(`ADDR_READY_DELAY, 16'd5, "READY_DELAY");
        test_reg_write_read(`ADDR_PRE_DELAY, 16'd7, "PRE_DELAY");
        test_reg_write_read(`ADDR_POST_DELAY, 16'd8, "POST_DELAY");
        test_reg_write_read(`ADDR_FRAME_COUNT, 16'd10, "FRAME_COUNT");
        
        //======================================================================
        // 3. Back Bias Registers (0x0020 - 0x0023)
        //======================================================================
        $display("\n=== 3. Back Bias Registers ===");
        test_reg_write_read(`ADDR_UP_BACK_BIAS, 16'd160, "UP_BACK_BIAS");
        test_reg_write_read(`ADDR_DN_BACK_BIAS, 16'd0, "DN_BACK_BIAS");
        test_reg_write_read(`ADDR_UP_BACK_BIAS_OPR, 16'd160, "UP_BACK_BIAS_OPR");
        test_reg_write_read(`ADDR_DN_BACK_BIAS_OPR, 16'd0, "DN_BACK_BIAS_OPR");
        
        //======================================================================
        // 4. GATE Registers - READ Mode (0x0024 - 0x0031)
        //======================================================================
        $display("\n=== 4. GATE Registers - READ Mode ===");
        test_reg_write_read(`ADDR_UP_GATE_STV1_READ, 16'h003C, "UP_GATE_STV1_READ");
        test_reg_write_read(`ADDR_DN_GATE_STV1_READ, 16'h0168, "DN_GATE_STV1_READ");
        test_reg_write_read(`ADDR_UP_GATE_STV2_READ, 16'h003C, "UP_GATE_STV2_READ");
        test_reg_write_read(`ADDR_DN_GATE_STV2_READ, 16'h0168, "DN_GATE_STV2_READ");
        test_reg_write_read(`ADDR_UP_GATE_CPV1_READ, 16'h006E, "UP_GATE_CPV1_READ");
        test_reg_write_read(`ADDR_DN_GATE_CPV1_READ, 16'h01E5, "DN_GATE_CPV1_READ");
        test_reg_write_read(`ADDR_UP_GATE_CPV2_READ, 16'h006E, "UP_GATE_CPV2_READ");
        test_reg_write_read(`ADDR_DN_GATE_CPV2_READ, 16'h01E5, "DN_GATE_CPV2_READ");
        test_reg_write_read(`ADDR_DN_GATE_OE1_READ, 16'd990, "DN_GATE_OE1_READ");
        test_reg_write_read(`ADDR_UP_GATE_OE1_READ, 16'd2490, "UP_GATE_OE1_READ");
        test_reg_write_read(`ADDR_DN_GATE_OE2_READ, 16'd990, "DN_GATE_OE2_READ");
        test_reg_write_read(`ADDR_UP_GATE_OE2_READ, 16'd2490, "UP_GATE_OE2_READ");
        test_reg_write_read(`ADDR_DN_GATE_XAO_READ, 16'd2, "DN_GATE_XAO_READ");
        test_reg_write_read(`ADDR_UP_GATE_XAO_READ, 16'd0, "UP_GATE_XAO_READ");
        
        //======================================================================
        // 5. GATE Registers - AED Mode (0x0032 - 0x003F)
        //======================================================================
        $display("\n=== 5. GATE Registers - AED Mode ===");
        test_reg_write_read(`ADDR_UP_GATE_STV1_AED, 16'h003C, "UP_GATE_STV1_AED");
        test_reg_write_read(`ADDR_DN_GATE_STV1_AED, 16'h0168, "DN_GATE_STV1_AED");
        test_reg_write_read(`ADDR_UP_GATE_STV2_AED, 16'h003C, "UP_GATE_STV2_AED");
        test_reg_write_read(`ADDR_DN_GATE_STV2_AED, 16'h0168, "DN_GATE_STV2_AED");
        test_reg_write_read(`ADDR_UP_GATE_CPV1_AED, 16'h006E, "UP_GATE_CPV1_AED");
        test_reg_write_read(`ADDR_DN_GATE_CPV1_AED, 16'h01E5, "DN_GATE_CPV1_AED");
        test_reg_write_read(`ADDR_UP_GATE_CPV2_AED, 16'h006E, "UP_GATE_CPV2_AED");
        test_reg_write_read(`ADDR_DN_GATE_CPV2_AED, 16'h01E5, "DN_GATE_CPV2_AED");
        test_reg_write_read(`ADDR_DN_GATE_OE1_AED, 16'd990, "DN_GATE_OE1_AED");
        test_reg_write_read(`ADDR_UP_GATE_OE1_AED, 16'd2490, "UP_GATE_OE1_AED");
        test_reg_write_read(`ADDR_DN_GATE_OE2_AED, 16'd990, "DN_GATE_OE2_AED");
        test_reg_write_read(`ADDR_UP_GATE_OE2_AED, 16'd2490, "UP_GATE_OE2_AED");
        test_reg_write_read(`ADDR_DN_GATE_XAO_AED, 16'd2, "DN_GATE_XAO_AED");
        test_reg_write_read(`ADDR_UP_GATE_XAO_AED, 16'd0, "UP_GATE_XAO_AED");
        
        //======================================================================
        // 6. GATE Registers - FLUSH Mode (0x0040 - 0x004B)
        //======================================================================
        $display("\n=== 6. GATE Registers - FLUSH Mode ===");
        test_reg_write_read(`ADDR_UP_GATE_STV1_FLUSH, 16'h0002, "UP_GATE_STV1_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_STV1_FLUSH, 16'h0025, "DN_GATE_STV1_FLUSH");
        test_reg_write_read(`ADDR_UP_GATE_STV2_FLUSH, 16'h0002, "UP_GATE_STV2_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_STV2_FLUSH, 16'h0025, "DN_GATE_STV2_FLUSH");
        test_reg_write_read(`ADDR_UP_GATE_CPV1_FLUSH, 16'd10, "UP_GATE_CPV1_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_CPV1_FLUSH, 16'd40, "DN_GATE_CPV1_FLUSH");
        test_reg_write_read(`ADDR_UP_GATE_CPV2_FLUSH, 16'd10, "UP_GATE_CPV2_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_CPV2_FLUSH, 16'd40, "DN_GATE_CPV2_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_OE1_FLUSH, 16'd15, "DN_GATE_OE1_FLUSH");
        test_reg_write_read(`ADDR_UP_GATE_OE1_FLUSH, 16'd180, "UP_GATE_OE1_FLUSH");
        test_reg_write_read(`ADDR_DN_GATE_OE2_FLUSH, 16'd15, "DN_GATE_OE2_FLUSH");
        test_reg_write_read(`ADDR_UP_GATE_OE2_FLUSH, 16'd180, "UP_GATE_OE2_FLUSH");
        
        //======================================================================
        // 7. ROIC SYNC and ACLK - READ Mode (0x0050 - 0x005B)
        //======================================================================
        $display("\n=== 7. ROIC ACLK - READ Mode ===");
        test_reg_write_read(`ADDR_UP_ROIC_SYNC, 16'h0002, "UP_ROIC_SYNC");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_0_READ, 16'h003C, "UP_ROIC_ACLK_0_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_1_READ, 16'h006E, "UP_ROIC_ACLK_1_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_2_READ, 16'h0168, "UP_ROIC_ACLK_2_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_3_READ, 16'h01E5, "UP_ROIC_ACLK_3_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_4_READ, 16'h03D9, "UP_ROIC_ACLK_4_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_5_READ, 16'h09C4, "UP_ROIC_ACLK_5_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_6_READ, 16'h09F6, "UP_ROIC_ACLK_6_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_7_READ, 16'h0A46, "UP_ROIC_ACLK_7_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_8_READ, 16'h0FA5, "UP_ROIC_ACLK_8_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_9_READ, 16'h0FD7, "UP_ROIC_ACLK_9_READ");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_10_READ, 16'h0FDC, "UP_ROIC_ACLK_10_READ");
        
        //======================================================================
        // 8. ROIC ACLK - AED Mode (0x005C - 0x0066)
        //======================================================================
        $display("\n=== 8. ROIC ACLK - AED Mode ===");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_0_AED, 16'h003C, "UP_ROIC_ACLK_0_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_1_AED, 16'h006E, "UP_ROIC_ACLK_1_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_2_AED, 16'h0168, "UP_ROIC_ACLK_2_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_3_AED, 16'h01E5, "UP_ROIC_ACLK_3_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_4_AED, 16'h03D9, "UP_ROIC_ACLK_4_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_5_AED, 16'h09C4, "UP_ROIC_ACLK_5_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_6_AED, 16'h09F6, "UP_ROIC_ACLK_6_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_7_AED, 16'h0A46, "UP_ROIC_ACLK_7_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_8_AED, 16'h0DB1, "UP_ROIC_ACLK_8_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_9_AED, 16'h0DE3, "UP_ROIC_ACLK_9_AED");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_10_AED, 16'h0DE8, "UP_ROIC_ACLK_10_AED");
        
        //======================================================================
        // 9. ROIC ACLK - FLUSH Mode (0x0067 - 0x0071)
        //======================================================================
        $display("\n=== 9. ROIC ACLK - FLUSH Mode ===");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_0_FLUSH, 16'h0005, "UP_ROIC_ACLK_0_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_1_FLUSH, 16'h0007, "UP_ROIC_ACLK_1_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_2_FLUSH, 16'h0053, "UP_ROIC_ACLK_2_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_3_FLUSH, 16'h0055, "UP_ROIC_ACLK_3_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_4_FLUSH, 16'h0057, "UP_ROIC_ACLK_4_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_5_FLUSH, 16'h0059, "UP_ROIC_ACLK_5_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_6_FLUSH, 16'h005B, "UP_ROIC_ACLK_6_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_7_FLUSH, 16'h005D, "UP_ROIC_ACLK_7_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_8_FLUSH, 16'h005F, "UP_ROIC_ACLK_8_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_9_FLUSH, 16'h0061, "UP_ROIC_ACLK_9_FLUSH");
        test_reg_write_read(`ADDR_UP_ROIC_ACLK_10_FLUSH, 16'h0063, "UP_ROIC_ACLK_10_FLUSH");
        
        //======================================================================
        // 10. ROIC Register Set (0x0072 - 0x0081)
        //======================================================================
        $display("\n=== 10. ROIC Register Set ===");
        test_reg_write_read(`ADDR_ROIC_REG_SET_0, 16'h0014, "ROIC_REG_SET_0");
        test_reg_write_read(`ADDR_ROIC_REG_SET_1, 16'h01A8, "ROIC_REG_SET_1");
        test_reg_write_read(`ADDR_ROIC_REG_SET_2, 16'h0007, "ROIC_REG_SET_2");
        test_reg_write_read(`ADDR_ROIC_REG_SET_3, 16'h0014, "ROIC_REG_SET_3");
        test_reg_write_read(`ADDR_ROIC_REG_SET_4, 16'h00A2, "ROIC_REG_SET_4");
        test_reg_write_read(`ADDR_ROIC_REG_SET_5, 16'h0014, "ROIC_REG_SET_5");
        test_reg_write_read(`ADDR_ROIC_REG_SET_6, 16'h0058, "ROIC_REG_SET_6");
        test_reg_write_read(`ADDR_ROIC_REG_SET_7, 16'h0037, "ROIC_REG_SET_7");
        test_reg_write_read(`ADDR_ROIC_REG_SET_8, 16'h0069, "ROIC_REG_SET_8");
        test_reg_write_read(`ADDR_ROIC_REG_SET_9, 16'h0007, "ROIC_REG_SET_9");
        test_reg_write_read(`ADDR_ROIC_REG_SET_10, 16'h0000, "ROIC_REG_SET_10");
        test_reg_write_read(`ADDR_ROIC_REG_SET_11, 16'h0018, "ROIC_REG_SET_11");
        test_reg_write_read(`ADDR_ROIC_REG_SET_12, 16'h0002, "ROIC_REG_SET_12");
        test_reg_write_read(`ADDR_ROIC_REG_SET_13, 16'h0023, "ROIC_REG_SET_13");
        test_reg_write_read(`ADDR_ROIC_REG_SET_14, 16'h002B, "ROIC_REG_SET_14");
        test_reg_write_read(`ADDR_ROIC_REG_SET_15, 16'h0008, "ROIC_REG_SET_15");
        
        //======================================================================
        // 11. ROIC Burst Control (0x0090 - 0x0099)
        //======================================================================
        $display("\n=== 11. ROIC Burst Control ===");
        test_reg_write_read(`ADDR_ROIC_BURST_CYCLE, 16'd185, "ROIC_BURST_CYCLE");
        test_reg_write_read(`ADDR_START_ROIC_BURST_CLK, 16'd1, "START_ROIC_BURST_CLK");
        test_reg_write_read(`ADDR_END_ROIC_BURST_CLK, 16'd65, "END_ROIC_BURST_CLK");
        test_reg_write_read(`ADDR_GATE_GPIO_REG, 16'h0000, "GATE_GPIO_REG");
        
        //======================================================================
        // 12. SEL ROIC REG (0x00A0)
        //======================================================================
        $display("\n=== 12. SEL ROIC REG ===");
        test_reg_write_read(`ADDR_SEL_ROIC_REG, 16'h0001, "SEL_ROIC_REG");
        
        //======================================================================
        // 13. AED GATE XAO Registers (0x00A2 - 0x00AD)
        //======================================================================
        $display("\n=== 13. AED GATE XAO Registers ===");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_0, 16'd2, "DN_AED_GATE_XAO_0");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_1, 16'd2, "DN_AED_GATE_XAO_1");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_2, 16'd2, "DN_AED_GATE_XAO_2");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_3, 16'd2, "DN_AED_GATE_XAO_3");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_4, 16'd2, "DN_AED_GATE_XAO_4");
        test_reg_write_read(`ADDR_DN_AED_GATE_XAO_5, 16'd2, "DN_AED_GATE_XAO_5");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_0, 16'd2030, "UP_AED_GATE_XAO_0");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_1, 16'd2030, "UP_AED_GATE_XAO_1");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_2, 16'd2030, "UP_AED_GATE_XAO_2");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_3, 16'd2030, "UP_AED_GATE_XAO_3");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_4, 16'd2030, "UP_AED_GATE_XAO_4");
        test_reg_write_read(`ADDR_UP_AED_GATE_XAO_5, 16'd2030, "UP_AED_GATE_XAO_5");
        
        //======================================================================
        // 14. AED Control Registers (0x00B0 - 0x00BD)
        //======================================================================
        $display("\n=== 14. AED Control Registers ===");
        test_reg_write_read(`ADDR_READY_AED_READ, 16'd80, "READY_AED_READ");
        test_reg_write_read(`ADDR_AED_TH, 16'h0008, "AED_TH");
        test_reg_write_read(`ADDR_SEL_AED_ROIC, 16'h0FFF, "SEL_AED_ROIC");
        test_reg_write_read(`ADDR_NUM_TRIGGER, 16'd2, "NUM_TRIGGER");
        test_reg_write_read(`ADDR_SEL_AED_TEST_ROIC, 16'h0040, "SEL_AED_TEST_ROIC");
        test_reg_write_read(`ADDR_AED_CMD, 16'h0000, "AED_CMD");
        test_reg_write_read(`ADDR_NEGA_AED_TH, 16'h0004, "NEGA_AED_TH");
        test_reg_write_read(`ADDR_POSI_AED_TH, 16'h0005, "POSI_AED_TH");
        test_reg_write_read(`ADDR_AED_DARK_DELAY, 16'd40, "AED_DARK_DELAY");
        test_reg_write_read(`ADDR_TEST_REG_A, 16'h1234, "TEST_REG_A");
        test_reg_write_read(`ADDR_TEST_REG_B, 16'h5678, "TEST_REG_B");
        test_reg_write_read(`ADDR_TEST_REG_C, 16'hABCD, "TEST_REG_C");
        test_reg_write_read(`ADDR_TEST_REG_D, 16'hEF01, "TEST_REG_D");
        
        //======================================================================
        // 15. AED Detect Line Registers (0x00C0 - 0x00C5)
        //======================================================================
        $display("\n=== 15. AED Detect Line Registers ===");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_0, 16'd1301, "AED_DETECT_LINE_0");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_1, 16'd1401, "AED_DETECT_LINE_1");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_2, 16'd1501, "AED_DETECT_LINE_2");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_3, 16'd1601, "AED_DETECT_LINE_3");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_4, 16'd1701, "AED_DETECT_LINE_4");
        test_reg_write_read(`ADDR_AED_DETECT_LINE_5, 16'd1801, "AED_DETECT_LINE_5");
        
        //======================================================================
        // 16. CSI2 Configuration (0x00D0 - 0x00D2)
        //======================================================================
        $display("\n=== 16. CSI2 Configuration ===");
        test_reg_write_read(`ADDR_MAX_V_COUNT, 16'd1536, "MAX_V_COUNT");
        test_reg_write_read(`ADDR_MAX_H_COUNT, 16'd256, "MAX_H_COUNT");
        test_reg_write_read(`ADDR_CSI2_WORD_COUNT, 16'd1024, "CSI2_WORD_COUNT");
        
        //======================================================================
        // 17. System Info Registers (0x00DB - 0x00DC)
        //======================================================================
        $display("\n=== 17. System Info Registers ===");
        test_reg_write_read(`ADDR_STATE_LED_CTR, 16'h0001, "STATE_LED_CTR");
        test_reg_write_read(`ADDR_IO_DELAY_TAB, 16'h0004, "IO_DELAY_TAB");
        
        //======================================================================
        // 18. Sequence Table FSM Registers (0x00E0 - 0x00EB)
        //======================================================================
        $display("\n=== 18. Sequence Table FSM Registers ===");
        test_reg_write_read(`ADDR_SEQ_LUT_ADDR, 16'h0010, "SEQ_LUT_ADDR");
        test_reg_write_read(`ADDR_SEQ_LUT_DATA_0, 16'h1111, "SEQ_LUT_DATA_0");
        test_reg_write_read(`ADDR_SEQ_LUT_DATA_1, 16'h2222, "SEQ_LUT_DATA_1");
        test_reg_write_read(`ADDR_SEQ_LUT_DATA_2, 16'h3333, "SEQ_LUT_DATA_2");
        test_reg_write_read(`ADDR_SEQ_LUT_DATA_3, 16'h4444, "SEQ_LUT_DATA_3");
        test_reg_write_read(`ADDR_SEQ_LUT_CONTROL, 16'h0003, "SEQ_LUT_CONTROL");
        test_reg_write_read(`ADDR_ACQ_MODE, 16'h0007, "ACQ_MODE");
        test_reg_write_read(`ADDR_SEQ_STATE_READ, 16'h0001, "SEQ_STATE_READ");
        test_reg_write_read(`ADDR_SWITCH_SYNC_UP, 16'h03FF, "SWITCH_SYNC_UP");
        test_reg_write_read(`ADDR_SWITCH_SYNC_DN, 16'h0001, "SWITCH_SYNC_DN");
        
        //======================================================================
        // 19. Test Registers (0x00F5 - 0x00FE)
        //======================================================================
        $display("\n=== 19. Test Registers ===");
        test_reg_write_read(`ADDR_TEST_REG_0, 16'hA0A0, "TEST_REG_0");
        test_reg_write_read(`ADDR_TEST_REG_1, 16'hB1B1, "TEST_REG_1");
        test_reg_write_read(`ADDR_TEST_REG_2, 16'hC2C2, "TEST_REG_2");
        test_reg_write_read(`ADDR_TEST_REG_3, 16'hD3D3, "TEST_REG_3");
        test_reg_write_read(`ADDR_TEST_REG_4, 16'hE4E4, "TEST_REG_4");
        test_reg_write_read(`ADDR_TEST_REG_5, 16'hF5F5, "TEST_REG_5");
        test_reg_write_read(`ADDR_TEST_REG_6, 16'h0606, "TEST_REG_6");
        test_reg_write_read(`ADDR_TEST_REG_7, 16'h1717, "TEST_REG_7");
        test_reg_write_read(`ADDR_TEST_REG_8, 16'h2828, "TEST_REG_8");
        test_reg_write_read(`ADDR_TEST_REG_9, 16'h3939, "TEST_REG_9");
        
        //======================================================================
        // 20. TI ROIC Registers (0x0100 - 0x011D)
        //======================================================================
        $display("\n=== 20. TI ROIC Registers ===");
        test_reg_write_read(`ADDR_TI_ROIC_REG_00, 16'h0000, "TI_ROIC_REG_00");
        test_reg_write_read(`ADDR_TI_ROIC_REG_10, 16'h0800, "TI_ROIC_REG_10");
        test_reg_write_read(`ADDR_TI_ROIC_REG_11, 16'h0430, "TI_ROIC_REG_11");
        test_reg_write_read(`ADDR_TI_ROIC_REG_12, 16'h0400, "TI_ROIC_REG_12");
        test_reg_write_read(`ADDR_TI_ROIC_REG_13, 16'h0000, "TI_ROIC_REG_13");
        test_reg_write_read(`ADDR_TI_ROIC_REG_16, 16'h00C0, "TI_ROIC_REG_16");
        test_reg_write_read(`ADDR_TI_ROIC_REG_18, 16'h0001, "TI_ROIC_REG_18");
        test_reg_write_read(`ADDR_TI_ROIC_REG_2C, 16'h0000, "TI_ROIC_REG_2C");
        test_reg_write_read(`ADDR_TI_ROIC_REG_30, 16'h0000, "TI_ROIC_REG_30");
        test_reg_write_read(`ADDR_TI_ROIC_REG_31, 16'h0000, "TI_ROIC_REG_31");
        test_reg_write_read(`ADDR_TI_ROIC_REG_32, 16'h0000, "TI_ROIC_REG_32");
        test_reg_write_read(`ADDR_TI_ROIC_REG_33, 16'h0000, "TI_ROIC_REG_33");
        test_reg_write_read(`ADDR_TI_ROIC_REG_40, 16'h0105, "TI_ROIC_REG_40");
        test_reg_write_read(`ADDR_TI_ROIC_REG_42, 16'h0682, "TI_ROIC_REG_42");
        test_reg_write_read(`ADDR_TI_ROIC_REG_43, 16'h83FF, "TI_ROIC_REG_43");
        test_reg_write_read(`ADDR_TI_ROIC_REG_46, 16'h0D83, "TI_ROIC_REG_46");
        test_reg_write_read(`ADDR_TI_ROIC_REG_47, 16'h8B00, "TI_ROIC_REG_47");
        test_reg_write_read(`ADDR_TI_ROIC_REG_4A, 16'h0685, "TI_ROIC_REG_4A");
        test_reg_write_read(`ADDR_TI_ROIC_REG_4B, 16'h0000, "TI_ROIC_REG_4B");
        test_reg_write_read(`ADDR_TI_ROIC_REG_50, 16'h8300, "TI_ROIC_REG_50");
        test_reg_write_read(`ADDR_TI_ROIC_REG_51, 16'h8300, "TI_ROIC_REG_51");
        test_reg_write_read(`ADDR_TI_ROIC_REG_52, 16'h8300, "TI_ROIC_REG_52");
        test_reg_write_read(`ADDR_TI_ROIC_REG_53, 16'h8300, "TI_ROIC_REG_53");
        test_reg_write_read(`ADDR_TI_ROIC_REG_54, 16'h8300, "TI_ROIC_REG_54");
        test_reg_write_read(`ADDR_TI_ROIC_REG_55, 16'h8300, "TI_ROIC_REG_55");
        test_reg_write_read(`ADDR_TI_ROIC_REG_5A, 16'h0040, "TI_ROIC_REG_5A");
        test_reg_write_read(`ADDR_TI_ROIC_REG_5C, 16'h8000, "TI_ROIC_REG_5C");
        test_reg_write_read(`ADDR_TI_ROIC_REG_5D, 16'h0000, "TI_ROIC_REG_5D");
        test_reg_write_read(`ADDR_TI_ROIC_REG_5E, 16'h0000, "TI_ROIC_REG_5E");
        test_reg_write_read(`ADDR_TI_ROIC_REG_61, 16'h0400, "TI_ROIC_REG_61");
        
        //======================================================================
        // 21. TI ROIC Control Registers (0x0120 - 0x0124)
        //======================================================================
        $display("\n=== 21. TI ROIC Control Registers ===");
        test_reg_write_read(`ADDR_TI_ROIC_REG_ADDR, 16'h0055, "TI_ROIC_REG_ADDR");
        test_reg_write_read(`ADDR_TI_ROIC_REG_DATA, 16'hAA55, "TI_ROIC_REG_DATA");
        test_reg_write_read(`ADDR_TI_ROIC_SYNC, 16'h0001, "TI_ROIC_SYNC");
        test_reg_write_read(`ADDR_TI_ROIC_TP_SEL, 16'h0001, "TI_ROIC_TP_SEL");
        test_reg_write_read(`ADDR_TI_ROIC_STR, 16'h0003, "TI_ROIC_STR");
        
        //======================================================================
        // 22. TI ROIC Deserializer Control (0x0130 - 0x0137)
        //======================================================================
        $display("\n=== 22. TI ROIC Deserializer Control ===");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_RESET, 16'h0001, "TI_ROIC_DESER_RESET");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_DLY_TAP_LD, 16'h0001, "TI_ROIC_DESER_DLY_TAP_LD");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_DLY_TAP_IN, 16'h001F, "TI_ROIC_DESER_DLY_TAP_IN");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_DLY_DATA_CE, 16'h0FFF, "TI_ROIC_DESER_DLY_DATA_CE");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_DLY_DATA_INC, 16'h0001, "TI_ROIC_DESER_DLY_DATA_INC");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_MODE, 16'h0001, "TI_ROIC_DESER_ALIGN_MODE");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_START, 16'h0001, "TI_ROIC_DESER_ALIGN_START");
        
        //======================================================================
        // 23. TI ROIC Deserializer Align Shift (0x0140 - 0x014B)
        //======================================================================
        $display("\n=== 23. TI ROIC Deserializer Align Shift ===");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_0, 16'h0001, "TI_ROIC_DESER_ALIGN_SHIFT_0");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_1, 16'h0002, "TI_ROIC_DESER_ALIGN_SHIFT_1");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_2, 16'h0003, "TI_ROIC_DESER_ALIGN_SHIFT_2");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_3, 16'h0004, "TI_ROIC_DESER_ALIGN_SHIFT_3");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_4, 16'h0005, "TI_ROIC_DESER_ALIGN_SHIFT_4");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_5, 16'h0006, "TI_ROIC_DESER_ALIGN_SHIFT_5");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_6, 16'h0007, "TI_ROIC_DESER_ALIGN_SHIFT_6");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_7, 16'h0008, "TI_ROIC_DESER_ALIGN_SHIFT_7");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_8, 16'h0009, "TI_ROIC_DESER_ALIGN_SHIFT_8");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_9, 16'h000A, "TI_ROIC_DESER_ALIGN_SHIFT_9");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_10, 16'h000B, "TI_ROIC_DESER_ALIGN_SHIFT_10");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_ALIGN_SHIFT_11, 16'h000C, "TI_ROIC_DESER_ALIGN_SHIFT_11");
        
        //======================================================================
        // 24. TI ROIC Deserializer Shift Set (0x0150 - 0x015B)
        //======================================================================
        $display("\n=== 24. TI ROIC Deserializer Shift Set ===");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_0, 16'h0011, "TI_ROIC_DESER_SHIFT_SET_0");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_1, 16'h0012, "TI_ROIC_DESER_SHIFT_SET_1");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_2, 16'h0013, "TI_ROIC_DESER_SHIFT_SET_2");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_3, 16'h0014, "TI_ROIC_DESER_SHIFT_SET_3");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_4, 16'h0015, "TI_ROIC_DESER_SHIFT_SET_4");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_5, 16'h0016, "TI_ROIC_DESER_SHIFT_SET_5");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_6, 16'h0017, "TI_ROIC_DESER_SHIFT_SET_6");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_7, 16'h0018, "TI_ROIC_DESER_SHIFT_SET_7");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_8, 16'h0019, "TI_ROIC_DESER_SHIFT_SET_8");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_9, 16'h001A, "TI_ROIC_DESER_SHIFT_SET_9");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_10, 16'h001B, "TI_ROIC_DESER_SHIFT_SET_10");
        test_reg_write_read(`ADDR_TI_ROIC_DESER_SHIFT_SET_11, 16'h001C, "TI_ROIC_DESER_SHIFT_SET_11");
        
        //======================================================================
        // 25. Read-Only Register Tests
        //======================================================================
        $display("\n=== 25. Read-Only Register Tests ===");
        
        do_mspi_read(2'b01, `ADDR_FSM_REG);
        #100;
        $display("  FSM_REG read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_FPGA_VER_H);
        #100;
        $display("  FPGA_VER_H read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_FPGA_VER_L);
        #100;
        $display("  FPGA_VER_L read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_ROIC_VENDOR);
        #100;
        $display("  ROIC_VENDOR read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_PURPOSE);
        #100;
        $display("  PURPOSE read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_SIZE_1);
        #100;
        $display("  SIZE_1 read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_SIZE_2);
        #100;
        $display("  SIZE_2 read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_MAJOR_REV);
        #100;
        $display("  MAJOR_REV read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_MINOR_REV);
        #100;
        $display("  MINOR_REV read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_ROIC_TEMPERATURE);
        #100;
        $display("  ROIC_TEMPERATURE read: 0x%04h", masterDataReceived);
        
        do_mspi_read(2'b01, `ADDR_TI_ROIC_DESER_ALIGN_DONE);
        #100;
        $display("  TI_ROIC_DESER_ALIGN_DONE read: 0x%04h", masterDataReceived);
        
        //======================================================================
        // 26. Rapid Sequential Access Test
        //======================================================================
        $display("\n=== 26. Rapid Sequential Access Test ===");
        for (int i = 0; i < 10; i++) begin
            test_reg_write_read(`ADDR_GATE_SIZE, 16'h0100 + i, $sformatf("RAPID_%0d", i));
        end
        
        //======================================================================
        // 27. Border Address Test
        //======================================================================
        $display("\n=== 27. Border Address Test ===");
        test_reg_write_read(16'h0001, 16'hFFFF, "MIN_ADDR");
        test_reg_write_read(16'h015B, 16'hAAAA, "MAX_ADDR");
        
        //======================================================================
        // 28. Output Signal Toggle Tests
        //======================================================================
        $display("\n=== 28. Output Signal Toggle Tests ===");
        
        // System Reset Toggle
        test_output_toggle(`ADDR_SYS_CMD_REG, 16'h0000, 16'h0001, "SYS_CMD_REG", "system_rst");
        
        // GATE Mode Toggles
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0001, "SET_GATE[0]", "gate_mode1");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0002, "SET_GATE[1]", "gate_mode2");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0004, "SET_GATE[2]", "gate_cs1");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0008, "SET_GATE[3]", "gate_cs2");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0010, "SET_GATE[4]", "gate_sel");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0020, "SET_GATE[5]", "gate_ud");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0040, "SET_GATE[6]", "gate_stv_mode");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0080, "SET_GATE[7]", "gate_oepsn");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0100, "SET_GATE[8]", "gate_lr1");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0200, "SET_GATE[9]", "gate_lr2");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h0800, "SET_GATE[11]", "stv_sel_h");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h1000, "SET_GATE[12]", "stv_sel_l1");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h2000, "SET_GATE[13]", "stv_sel_r1");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h4000, "SET_GATE[14]", "stv_sel_l2");
        test_output_toggle(`ADDR_SET_GATE, 16'h0000, 16'h8000, "SET_GATE[15]", "stv_sel_r2");
        
        // Gate Size Value Change
        test_output_toggle(`ADDR_GATE_SIZE, 16'h0100, 16'h0200, "GATE_SIZE", "gate_size");
        test_output_toggle(`ADDR_GATE_SIZE, 16'h0200, 16'h0400, "GATE_SIZE", "gate_size");
        
        // CSI2 Value Changes
        test_output_toggle(`ADDR_MAX_V_COUNT, 16'd768, 16'd1536, "MAX_V_COUNT", "max_v_count");
        test_output_toggle(`ADDR_MAX_H_COUNT, 16'd128, 16'd256, "MAX_H_COUNT", "max_h_count");
        test_output_toggle(`ADDR_CSI2_WORD_COUNT, 16'd512, 16'd1024, "CSI2_WORD_COUNT", "csi2_word_count");
        
        // Back Bias Value Changes
        test_output_toggle(`ADDR_UP_BACK_BIAS, 16'd100, 16'd200, "UP_BACK_BIAS", "up_back_bias");
        test_output_toggle(`ADDR_DN_BACK_BIAS, 16'd0, 16'd100, "DN_BACK_BIAS", "dn_back_bias");
        
        // TI ROIC Control Toggles
        test_output_toggle(`ADDR_TI_ROIC_SYNC, 16'h0000, 16'h0001, "TI_ROIC_SYNC", "ti_roic_sync");
        test_output_toggle(`ADDR_TI_ROIC_STR, 16'h0000, 16'h0003, "TI_ROIC_STR", "ti_roic_str");
        test_output_toggle(`ADDR_TI_ROIC_DESER_RESET, 16'h0000, 16'h0001, "TI_ROIC_DESER_RESET", "ti_roic_deser_reset");
        test_output_toggle(`ADDR_TI_ROIC_DESER_ALIGN_MODE, 16'h0000, 16'h0001, "TI_ROIC_DESER_ALIGN_MODE", "ti_roic_deser_align_mode");
        test_output_toggle(`ADDR_TI_ROIC_DESER_ALIGN_START, 16'h0000, 16'h0001, "TI_ROIC_DESER_ALIGN_START", "ti_roic_deser_align_start");
        
        // OP_MODE_REG bit toggles
        test_output_toggle(`ADDR_OP_MODE_REG, 16'h0000, 16'h0001, "OP_MODE_REG[0]", "en_panel_stable");
        test_output_toggle(`ADDR_OP_MODE_REG, 16'h0000, 16'h0002, "OP_MODE_REG[1]", "en_16bit_adc");
        test_output_toggle(`ADDR_OP_MODE_REG, 16'h0000, 16'h0100, "OP_MODE_REG[8]", "burst_get_image");
        
        // SYS_CMD_REG command bit toggles
        test_output_toggle(`ADDR_SYS_CMD_REG, 16'h0000, 16'h0002, "SYS_CMD_REG[1]", "get_dark");
        test_output_toggle(`ADDR_SYS_CMD_REG, 16'h0000, 16'h0004, "SYS_CMD_REG[2]", "get_bright");
        test_output_toggle(`ADDR_SYS_CMD_REG, 16'h0000, 16'h0100, "SYS_CMD_REG[8]", "dummy_get_image");
        
        // ACQ Mode Value Changes
        test_output_toggle(`ADDR_ACQ_MODE, 16'h0000, 16'h0001, "ACQ_MODE", "acq_mode");
        test_output_toggle(`ADDR_ACQ_MODE, 16'h0001, 16'h0003, "ACQ_MODE", "acq_mode");
        test_output_toggle(`ADDR_ACQ_MODE, 16'h0003, 16'h0007, "ACQ_MODE", "acq_mode");
        
        // GATE GPIO Toggle
        test_output_toggle(`ADDR_GATE_GPIO_REG, 16'h0000, 16'hFFFF, "GATE_GPIO_REG", "gate_gpio_data");
        test_output_toggle(`ADDR_GATE_GPIO_REG, 16'hFFFF, 16'h5555, "GATE_GPIO_REG", "gate_gpio_data");
        test_output_toggle(`ADDR_GATE_GPIO_REG, 16'h5555, 16'hAAAA, "GATE_GPIO_REG", "gate_gpio_data");
        
        // SEQ LUT Address Changes
        test_output_toggle(`ADDR_SEQ_LUT_ADDR, 16'h0000, 16'h0010, "SEQ_LUT_ADDR", "seq_lut_addr");
        test_output_toggle(`ADDR_SEQ_LUT_ADDR, 16'h0010, 16'h0020, "SEQ_LUT_ADDR", "seq_lut_addr");
        test_output_toggle(`ADDR_SEQ_LUT_ADDR, 16'h0020, 16'h00FF, "SEQ_LUT_ADDR", "seq_lut_addr");
        
        // SEQ LUT Write Enable Toggle (via CONTROL register)
        $display("\n[TOGGLE] SEQ_LUT_CONTROL: Testing seq_lut_wr_en toggle");
        do_mspi_write(2'b10, `ADDR_SEQ_LUT_CONTROL, 16'h0000);
        #200;
        $display("  Write 0x0000 -> seq_lut_wr_en = %b", seq_lut_wr_en);
        if (seq_lut_wr_en == 1'b0)
            $display("  [PASS] seq_lut_wr_en = 0");
        else
            $display("  [FAIL] seq_lut_wr_en = %b (expected 0)", seq_lut_wr_en);
            
        do_mspi_write(2'b10, `ADDR_SEQ_LUT_CONTROL, 16'h0001);
        #200;
        $display("  Write 0x0001 -> seq_lut_wr_en = %b", seq_lut_wr_en);
        if (seq_lut_wr_en == 1'b1)
            $display("  [PASS] seq_lut_wr_en = 1");
        else
            $display("  [FAIL] seq_lut_wr_en = %b (expected 1)", seq_lut_wr_en);
        
        // Expose Size Multi-value Changes with Verification
        $display("\n[MULTI-VALUE] Testing acq_expose_size changes");
        do_mspi_write(2'b10, `ADDR_EXPOSE_SIZE, 16'd100);
        #200;
        $display("  Write EXPOSE_SIZE=100 -> acq_expose_size = 0x%08h", acq_expose_size);
        if (acq_expose_size == 32'd100)
            $display("  [PASS] acq_expose_size = 100");
        else
            $display("  [FAIL] acq_expose_size = %0d (expected 100)", acq_expose_size);
            
        do_mspi_write(2'b10, `ADDR_EXPOSE_SIZE, 16'd500);
        #200;
        $display("  Write EXPOSE_SIZE=500 -> acq_expose_size = 0x%08h", acq_expose_size);
        if (acq_expose_size == 32'd500)
            $display("  [PASS] acq_expose_size = 500");
        else
            $display("  [FAIL] acq_expose_size = %0d (expected 500)", acq_expose_size);
            
        do_mspi_write(2'b10, `ADDR_EXPOSE_SIZE, 16'd1000);
        #200;
        $display("  Write EXPOSE_SIZE=1000 -> acq_expose_size = 0x%08h", acq_expose_size);
        if (acq_expose_size == 32'd1000)
            $display("  [PASS] acq_expose_size = 1000");
        else
            $display("  [FAIL] acq_expose_size = %0d (expected 1000)", acq_expose_size);
            
        do_mspi_write(2'b10, `ADDR_EXPOSE_SIZE, 16'd5000);
        #200;
        $display("  Write EXPOSE_SIZE=5000 -> acq_expose_size = 0x%08h", acq_expose_size);
        if (acq_expose_size == 32'd5000)
            $display("  [PASS] acq_expose_size = 5000");
        else
            $display("  [FAIL] acq_expose_size = %0d (expected 5000)", acq_expose_size);
        
        //======================================================================
        // 29. Input Signal Readback Tests
        //======================================================================
        $display("\n=== 29. Input Signal Readback Tests ===");
        
        // Test ti_roic_deser_align_done readback
        $display("\n--- Testing ti_roic_deser_align_done readback ---");
        ti_roic_deser_align_done = 12'b000000000000;
        #200;
        test_input_readback("ti_roic_deser_align_done", `ADDR_TI_ROIC_DESER_ALIGN_DONE, 16'h0000, "ALIGN_DONE=0x000");
        
        ti_roic_deser_align_done = 12'b111111111111;
        #200;
        test_input_readback("ti_roic_deser_align_done", `ADDR_TI_ROIC_DESER_ALIGN_DONE, 16'h0FFF, "ALIGN_DONE=0xFFF");
        
        ti_roic_deser_align_done = 12'b101010101010;
        #200;
        test_input_readback("ti_roic_deser_align_done", `ADDR_TI_ROIC_DESER_ALIGN_DONE, 16'h0AAA, "ALIGN_DONE=0xAAA");
        
        ti_roic_deser_align_done = 12'b010101010101;
        #200;
        test_input_readback("ti_roic_deser_align_done", `ADDR_TI_ROIC_DESER_ALIGN_DONE, 16'h0555, "ALIGN_DONE=0x555");
        
        // Test individual bits
        $display("\n--- Testing individual ti_roic_deser_align_done bits ---");
        for (int i = 0; i < 12; i++) begin
            ti_roic_deser_align_done = (1 << i);
            #200;
            test_input_readback($sformatf("ti_roic_deser_align_done[%0d]", i), 
                              `ADDR_TI_ROIC_DESER_ALIGN_DONE, 
                              16'(1 << i), 
                              $sformatf("BIT_%0d", i));
        end
        
        // Test FSM state inputs readback via FSM_REG
        $display("\n--- Testing FSM State Inputs ---");
        
        // Reset all FSM states first
        fsm_rst_index = 1'b0;
        fsm_init_index = 1'b0;
        fsm_back_bias_index = 1'b0;
        fsm_flush_index = 1'b0;
        fsm_aed_read_index = 1'b0;
        fsm_exp_index = 1'b0;
        fsm_read_index = 1'b0;
        fsm_idle_index = 1'b0;
        #200;
        
        // Test RESET state (000)
        fsm_rst_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b000, "RESET");
        fsm_rst_index = 1'b0;
        #100;
        
        // Test INIT state (001)
        fsm_init_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b001, "INIT");
        fsm_init_index = 1'b0;
        #100;
        
        // Test BACK_BIAS state (010)
        fsm_back_bias_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b010, "BACK_BIAS");
        fsm_back_bias_index = 1'b0;
        #100;
        
        // Test FLUSH state (011)
        fsm_flush_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b011, "FLUSH");
        fsm_flush_index = 1'b0;
        #100;
        
        // Test AED_READ state (100)
        fsm_aed_read_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b100, "AED_READ");
        fsm_aed_read_index = 1'b0;
        #100;
        
        // Test EXPOSURE state (101)
        fsm_exp_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b101, "EXPOSURE");
        fsm_exp_index = 1'b0;
        #100;
        
        // Test READ state (110)
        fsm_read_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b110, "READ");
        fsm_read_index = 1'b0;
        #100;
        
        // Test IDLE state (111)
        fsm_idle_index = 1'b1;
        #200;
        test_fsm_state_readback(3'b111, "IDLE");
        fsm_idle_index = 1'b0;
        #100;
        
        // Test FSM_REG status bits
        $display("\n--- Testing FSM_REG Status Bits ---");
        
        // Reset status inputs
        ready_to_get_image = 1'b0;
        aed_ready_done = 1'b0;
        exp_read_exist = 1'b0;
        panel_stable_exist = 1'b0;
        fsm_idle_index = 1'b1;  // Keep in IDLE state
        #200;
        test_input_readback("FSM_REG[all_status=0]", `ADDR_FSM_REG, 16'h0007, "STATUS_ALL_0");
        
        // Test ready_to_get_image bit[3]
        ready_to_get_image = 1'b1;
        #200;
        test_input_readback("FSM_REG[ready_to_get_image]", `ADDR_FSM_REG, 16'h000F, "READY_BIT");
        ready_to_get_image = 1'b0;
        #200;
        
        // Test aed_ready_done bit[4]
        aed_ready_done = 1'b1;
        #200;
        test_input_readback("FSM_REG[aed_ready_done]", `ADDR_FSM_REG, 16'h0017, "AED_READY_BIT");
        aed_ready_done = 1'b0;
        #200;
        
        // Test exp_read_exist bit[5]
        exp_read_exist = 1'b1;
        #200;
        test_input_readback("FSM_REG[exp_read_exist]", `ADDR_FSM_REG, 16'h0027, "EXP_READ_BIT");
        exp_read_exist = 1'b0;
        #200;
        
        // Test panel_stable_exist bit[6]
        panel_stable_exist = 1'b1;
        #200;
        test_input_readback("FSM_REG[panel_stable_exist]", `ADDR_FSM_REG, 16'h0047, "PANEL_STABLE_BIT");
        panel_stable_exist = 1'b0;
        #200;
        
        // Test all status bits together
        ready_to_get_image = 1'b1;
        aed_ready_done = 1'b1;
        exp_read_exist = 1'b1;
        panel_stable_exist = 1'b1;
        #200;
        test_input_readback("FSM_REG[all_status=1]", `ADDR_FSM_REG, 16'h007F, "STATUS_ALL_1");
        
        // Test ti_roic_deser_align_shift readback (via SEQ_LUT_READ_DATA)
        $display("\n--- Testing ti_roic_deser_align_shift readback ---");
        
        // Set align shift values
        for (int i = 0; i < 12; i++) begin
            ti_roic_deser_align_shift[i] = 5'(i);
        end
        #200;
        
        // Note: These are read via TI_ROIC_DESER_ALIGN_SHIFT_x registers
        $display("  Info: ti_roic_deser_align_shift[0-11] set to 0-11");
        for (int i = 0; i < 12; i++) begin
            do_mspi_read(2'b01, `ADDR_TI_ROIC_DESER_ALIGN_SHIFT_0 + i);
            #100;
            if (masterDataReceived[4:0] === 5'(i))
                $display("  [PASS] ALIGN_SHIFT_%0d = %0d", i, masterDataReceived[4:0]);
            else
                $display("  [FAIL] ALIGN_SHIFT_%0d = %0d (expected %0d)", i, masterDataReceived[4:0], i);
        end
        
        // Test exp_req/exp_ack inversion
        $display("\n--- Testing exp_req/exp_ack inversion ---");
        exp_req = 1'b0;
        #100;
        if (exp_ack === 1'b1)
            $display("  [PASS] exp_req=0 → exp_ack=1");
        else
            $display("  [FAIL] exp_req=0 → exp_ack=%b (expected 1)", exp_ack);
        
        exp_req = 1'b1;
        #100;
        if (exp_ack === 1'b0)
            $display("  [PASS] exp_req=1 → exp_ack=0");
        else
            $display("  [FAIL] exp_req=1 → exp_ack=%b (expected 0)", exp_ack);
        
        //======================================================================
        // 30. Test Statistics Collection
        //======================================================================
        #100;
        $display("\n=== 30. Final Test Statistics ===");
        $display("Total register write/read tests: 237");
        $display("Total toggle tests: 60+");
        $display("Total multi-value tests: 4");
        $display("Total input signal readback tests: 42 (ti_roic_deser_align_done: 16, FSM: 13, align_shift: 12, exp_ack: 2)");
        $display("  - ti_roic_deser_align_done: 16 tests");
        $display("  - FSM states: 8 tests");
        $display("  - FSM status bits: 5 tests");
        $display("  - ti_roic_deser_align_shift: 12 tests");
        $display("Review the log above for individual PASS/FAIL results");
        
        //======================================================================
        // 31. Output Signal Summary
        //======================================================================
        $display("\n=== 31. Final Output Signal Summary ===");
        $display("system_rst: %b", system_rst);
        $display("reset_fsm: %b", reset_fsm);
        $display("gate_mode1/2: %b/%b", gate_mode1, gate_mode2);
        $display("gate_cs1/2: %b/%b", gate_cs1, gate_cs2);
        $display("gate_sel: %b", gate_sel);
        $display("gate_ud: %b", gate_ud);
        $display("gate_stv_mode: %b", gate_stv_mode);
        $display("gate_oepsn: %b", gate_oepsn);
        $display("gate_size: 0x%04h", gate_size);
        $display("max_v_count: %0d", max_v_count);
        $display("max_h_count: %0d", max_h_count);
        $display("csi2_word_count: %0d", csi2_word_count);
        $display("up_back_bias: 0x%04h", up_back_bias);
        $display("dn_back_bias: 0x%04h", dn_back_bias);
        $display("acq_mode: %b", acq_mode);
        $display("acq_expose_size: 0x%08h (%0d)", acq_expose_size, acq_expose_size);
        $display("ti_roic_sync: %b", ti_roic_sync);
        $display("ti_roic_str: %b", ti_roic_str);
        $display("seq_lut_addr: 0x%02h", seq_lut_addr);
        $display("seq_lut_wr_en: %b", seq_lut_wr_en);
        $display("en_panel_stable: %b", en_panel_stable);
        $display("en_16bit_adc: %b", en_16bit_adc);
        $display("get_dark: %b", get_dark);
        $display("get_bright: %b", get_bright);
        $display("dummy_get_image: %b", dummy_get_image);
        $display("burst_get_image: %b", burst_get_image);
        $display("gate_gpio_data: 0x%04h", gate_gpio_data);
        
        #500;
        $display("\n=== Full Verification Complete ===");
        $display("Check the log for PASS/FAIL status of each test");
        $finish;
    end

    //==========================================================================
    // Waveform Dump (optional)
    //==========================================================================
    initial begin
        $dumpfile("tb_reg_map_refacto_full.vcd");
        $dumpvars(0, tb_reg_map_refacto_full);
    end

endmodule
