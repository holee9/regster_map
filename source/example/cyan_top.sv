`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: cyan_top.sv
// Date: 2024.05.19
// Designer: drake.lee
// Description: xdaq fpga top file - Converted from VHDL to SystemVerilog
// Revision History:
//    2024.05.19 - Initial
//    2024.06.24 - CSI2 2pixel, 4lane fixed
///////////////////////////////////////////////////////////////////////////////


// Package definitions for arrays (converted from xpackage)
//package xpackage_sv;
//    typedef logic [31:0] array32[11:0]; // Changed to static arrayy
//endpackage

// import xpackage_sv::*;

module cyan_top (
    // system signal
    input   logic        nRST,
    input   logic        MCLK_100M_p,
    input   logic        MCLK_100M_n,

    // mipi csi2 interface
    output  logic        mipi_phy_if_clk_hs_p,
    output  logic        mipi_phy_if_clk_hs_n,
    output  logic        mipi_phy_if_clk_lp_p,
    output  logic        mipi_phy_if_clk_lp_n,
    output  logic [3:0]  mipi_phy_if_data_hs_p,
    output  logic [3:0]  mipi_phy_if_data_hs_n,
    output  logic [3:0]  mipi_phy_if_data_lp_p,
    output  logic [3:0]  mipi_phy_if_data_lp_n,
    
    // register map control signal
    input   logic        SCLK,
    input   logic        SSB,
    input   logic        MOSI,
    output  logic        MISO,

    // ROIC Driving Signals
    output  logic        ROIC_TP_SEL,
    output  logic        ROIC_SYNC,
    output  logic        ROIC_MCLK0,
    output  logic        ROIC_MCLK1,

    output  logic [11:0] RF_SPI_SEN,
    output  logic        RF_SPI_SCK,
    // output  logic [11:0] RF_SPI_SDI,
    output  logic [0:0]  RF_SPI_SDI,
    input   logic [11:0] RF_SPI_SDO,

    output  logic        SWITCH_SYNC,
    
    output  logic        AED_TRIG,

    // output  logic        DCLK_R,
    input   logic [11:0] R_ROIC_DCLKo_p,
    input   logic [11:0] R_ROIC_DCLKo_n,

    input   logic [11:0] R_ROIC_FCLKo_p,
    input   logic [11:0] R_ROIC_FCLKo_n,

    input   logic [11:0] R_DOUTA_H,
    input   logic [11:0] R_DOUTA_L,

    // input   logic [11:0] R_DOUTB_H,
    // input   logic [11:0] R_DOUTB_L,

    // // TI ROIC interface
    // input   logic [11:0]  TI_FCLK_p,
    // input   logic [11:0]  TI_FCLK_n,

    // input   logic [11:0]  TI_DCLK_p,
    // input   logic [11:0]  TI_DCLK_n,

    // input   logic [11:0]  TI_DOUT_p,
    // input   logic [11:0]  TI_DOUT_n,

    // Gate Driving Signals
    output  logic        GF_STV_L,
    output  logic        GF_STV_R,
    
    output  logic [5:0] GF_XAO,

    // output  logic        GF_CS1,
    // output  logic        GF_CS2,

    output  logic        GF_LR,

    output  logic        GF_CPV,
    output  logic        GF_OE,
    // output  logic        GF_OE1,
    // output  logic        GF_OE2,
    
    // Bias Signals
    output  logic        ROIC_VBIAS,
    output  logic        ROIC_AVDD1,
    output  logic        ROIC_AVDD2,

    // Trigger Signals
    input   logic        PREP_REQ,
    input   logic        EXP_REQ,

    output  logic        PREP_ACK,
    output  logic        EXP_ACK,

    // Signals control
    output  logic        STATE_LED1

);

    // Define roic_data_in to match VHDL's array32
    typedef logic [31:0] array32 [11:0];
    array32 roic_data_in;
    
    // Clock signals
    logic s_clk_100mhz;
    // logic s_clk_25mhz;
    logic s_axi_clk_200M;
    logic s_dphy_clk_200M;
    logic s_clk_20mhz;
    logic s_clk_10mhz;
    logic s_clk_5mhz;

    // Module signals
    logic s_roic_reset;
    logic s_roic_aclk;
    logic s_roic_sync;
    // logic s_gate_oe2;
    logic s_back_bias;

    logic s_roic_cs0;
    logic s_roic_sck0;
    logic s_roic_sdo0;
    logic s_roic_sdo1;
    logic [11:0] s_roic_sdi_0;

    logic eim_clk;
    logic eim_rst;
    logic sys_rst;
    logic drv_rst;
    logic rst;
    logic fsm_drv_rst;
    logic sig_dclk;

    logic col_end;
    logic row_end;

    logic FSM_rst_index;
    logic FSM_init_index;
    logic FSM_back_bias_index;
    logic FSM_flush_index;
    logic FSM_aed_read_index;
    logic FSM_exp_index;
    logic FSM_read_index;
    logic FSM_idle_index;

    logic ready_to_get_image;
    logic aed_ready_done;
    logic aed_ready_done_dark;
    logic s_panel_stable_exist;
    logic s_exp_read_exist;
    logic valid_posi_flag;
    logic valid_nega_flag;

    logic [15:0] row_cnt;
    logic [15:0] col_cnt;

    logic en_pwr_off;
    logic en_pwr_dwn;
    logic system_rst;
    logic reset_FSM;
    logic org_reset_FSM;
    logic dummy_get_image;
    logic exist_get_image;
    logic burst_get_image;
    logic get_dark;
    logic get_bright;
    logic cmd_get_bright;
    logic en_aed;

    logic disable_aed_read_xao;
    logic on_aed_trigger;

    logic [15:0] aed_th;
    logic [15:0] nega_aed_th;
    logic [15:0] posi_aed_th;
    logic [15:0] sel_aed_roic;
    logic [15:0] num_trigger;
    logic [15:0] sel_aed_test_roic;
    
    logic [15:0] ready_aed_read;
    logic [15:0] aed_dark_delay;

    logic en_back_bias;
    logic en_flush;
    logic en_panel_stable;

    logic [23:0] cycle_width;
    logic [15:0] image_height;
    logic [15:0] dsp_image_height;
    logic [15:0] aed_read_image_height;
    logic [7:0]  frame_rpt;
    logic [7:0]  saturation_flush_repeat;
    logic [15:0] max_h_count;
    logic [15:0] max_v_count;
    logic [15:0] csi2_word_count;
    logic [10:0] readout_width;
    logic [15:0] readout_count;
    logic [15:0] gate_size;

    logic [15:0] roic_burst_cycle;
    logic [15:0] start_roic_burst_clk;
    logic [15:0] end_roic_burst_clk;

    logic [15:0] up_back_bias;
    logic [15:0] down_back_bias;
    logic [15:0] up_back_bias_opr;
    logic [15:0] down_back_bias_opr;
                                                                
    logic [15:0] up_gate_stv1;
    logic [15:0] down_gate_stv1;
                                                                
    logic [15:0] up_gate_stv2;
    logic [15:0] down_gate_stv2;
                                                                
    logic [15:0] up_gate_cpv1;
    logic [15:0] down_gate_cpv1;
                                                                
    logic [15:0] up_gate_cpv2;
    logic [15:0] down_gate_cpv2;
                                                                
    logic [15:0] up_gate_oe1;
    logic [15:0] down_gate_oe1;
                                                                
    logic [15:0] up_gate_oe2;
    logic [15:0] down_gate_oe2;

    logic [15:0] up_roic_sync;

    logic [15:0] up_aed_gate_xao_0;
    logic [15:0] up_aed_gate_xao_1;
    logic [15:0] up_aed_gate_xao_2;
    logic [15:0] up_aed_gate_xao_3;
    logic [15:0] up_aed_gate_xao_4;
    logic [15:0] up_aed_gate_xao_5;
    logic [15:0] dn_aed_gate_xao_0;
    logic [15:0] dn_aed_gate_xao_1;
    logic [15:0] dn_aed_gate_xao_2;
    logic [15:0] dn_aed_gate_xao_3;
    logic [15:0] dn_aed_gate_xao_4;
    logic [15:0] dn_aed_gate_xao_5;
    logic [15:0] aed_detect_line_0;
    logic [15:0] aed_detect_line_1;
    logic [15:0] aed_detect_line_2;
    logic [15:0] aed_detect_line_3;
    logic [15:0] aed_detect_line_4;
    logic [15:0] aed_detect_line_5;

    logic [15:0] up_roic_aclk_0;
    logic [15:0] up_roic_aclk_1;
    logic [15:0] up_roic_aclk_2;
    logic [15:0] up_roic_aclk_3;
    logic [15:0] up_roic_aclk_4;
    logic [15:0] up_roic_aclk_5;
    logic [15:0] up_roic_aclk_6;
    logic [15:0] up_roic_aclk_7;
    logic [15:0] up_roic_aclk_8;
    logic [15:0] up_roic_aclk_9;
    logic [15:0] up_roic_aclk_10;
    
    logic [15:0] burst_break_pt_0;
    logic [15:0] burst_break_pt_1;
    logic [15:0] burst_break_pt_2;
    logic [15:0] burst_break_pt_3;

    logic en_16bit_adc;
    logic en_test_pattern_col;
    logic en_test_pattern_row;
    logic en_test_roic_col;
    logic en_test_roic_row;
    logic aed_test_mode1;
    logic aed_test_mode2;
    logic gate_stv_1_1;
    logic sig_gate_cpv;
    logic sig_gate_lr1;
    logic sig_gate_lr2;
    logic gate_cpv_init;

    logic valid_aed_read_skip;
    logic roic_data_read_index;
    logic valid_read_out;
    logic valid_roic_out;
    logic valid_roic_burst_clk;
    logic valid_roic_reg_out;
    logic valid_roic_header_out;    
    // logic exr_valid_roic_data;
    logic valid_roic_data;
    
    // Array signals
    logic valid_aed_test_data;
    logic [15:0] trigger_data_1;
    logic [15:0] trigger_data_2;
    logic [15:0] trigger_data_3;

    logic [15:0] roic_reg_set_0;
    logic [15:0] roic_reg_set_1;
    logic [15:0] roic_reg_set_1_dual;
    logic [15:0] roic_reg_set_2;
    logic [15:0] roic_reg_set_3;
    logic [15:0] roic_reg_set_4;
    logic [15:0] roic_reg_set_5;
    logic [15:0] roic_reg_set_6;
    logic [15:0] roic_reg_set_7;
    logic [15:0] roic_reg_set_8;
    logic [15:0] roic_reg_set_9;
    logic [15:0] roic_reg_set_10;
    logic [15:0] roic_reg_set_11;
    logic [15:0] roic_reg_set_12;
    logic [15:0] roic_reg_set_13;
    logic [15:0] roic_reg_set_14;
    logic [15:0] roic_reg_set_15;

    logic ack_tx_end;
    logic up_roic_reg;

    logic [15:0] r_roic_temperature;
    logic [63:0] r_roic_reg_in_a;
    logic [63:0] r_roic_reg_in_b;

    logic roic_set_cs0 = 1'b0;
    logic roic_set_cs1 = 1'b0;
    logic roic_set_cs2 = 1'b0;
    logic roic_set_cs3 = 1'b0;
    logic roic_set_cs4 = 1'b0;
    logic roic_set_cs5 = 1'b0;
    logic roic_set_cs6 = 1'b0;
    logic roic_set_cs7 = 1'b0;
    logic roic_set_cs8 = 1'b0;
    logic roic_set_cs9 = 1'b0;
    logic roic_set_cs10 = 1'b0;
    logic roic_set_cs11 = 1'b0;
    logic roic_set_sck = 1'b0;
    logic roic_set_sdo = 1'b0;
    
    logic roic_init_cs0 = 1'b0;
    logic roic_init_cs1 = 1'b0;
    logic roic_init_cs2 = 1'b0;
    logic roic_init_cs3 = 1'b0;
    logic roic_init_cs4 = 1'b0;
    logic roic_init_cs5 = 1'b0;
    logic roic_init_cs6 = 1'b0;
    logic roic_init_cs7 = 1'b0;
    logic roic_init_cs8 = 1'b0;
    logic roic_init_cs9 = 1'b0;
    logic roic_init_cs10 = 1'b0;
    logic roic_init_cs11 = 1'b0;
    logic roic_init_sck = 1'b0;
    logic roic_init_sdo = 1'b0;

    logic LD_IO_DELAY_TAB;
    logic [4:0] IO_DELAY_TAB;
    logic [7:0] sel_roic_reg;

    logic vsync;
    logic hsync;

    logic s_pwr_init_step1;
    logic s_pwr_init_step2;
    logic s_pwr_init_step3;
    logic s_pwr_init_step4;
    logic s_pwr_init_step5;
    logic s_pwr_init_step6;

    logic valid_tx_1d = 1'b0;
    logic valid_tx_2d = 1'b0;
    logic init_rst;
    logic FSM_read_index_1d = 1'b0;
    logic FSM_read_index_2d = 1'b0;
    logic hi_FSM_read_index;
    // logic [23:0] led_on_cnt = 24'h000000;
    
    logic [15:0] aed_ready_cnt_d_chk = 16'h0000;
    logic [15:0] aed_ready_cnt_b_chk = 16'h0000;
    logic valid_aed_dark_get_dark = 1'b0;
    
    logic gate_xao;
    logic gate_xao_0;
    logic gate_xao_1;
    logic gate_xao_2;
    logic gate_xao_3;
    logic gate_xao_4;
    
    logic [31:0] chk_reg_0;
    logic [31:0] chk_reg_1;
    logic [31:0] chk_reg_2;
    logic [31:0] chk_reg_3;
    logic [31:0] chk_reg_4;
    logic [31:0] chk_reg_5;
    logic [31:0] chk_reg_6;
    logic [31:0] chk_reg_7;
    logic [31:0] chk_reg_8;
    logic [31:0] chk_reg_9;
    logic [31:0] chk_reg_A;
    logic [31:0] chk_reg_B;
    logic [15:0] chk_reg_C;
    logic [15:0] chk_reg_D;
    logic [15:0] chk_reg_E;
    logic [15:0] chk_reg_F;
    
    logic on_aed_dark_trigger;

    // SPI signals
    localparam int header = 2;
    localparam int payload = 16;
    localparam int addrsz = 14;
    localparam int pktsz = 32; // (header + addrsz + payload) size of SPI packet

    logic s_spi_start_flag;
    logic s_addr_dv;
    logic s_rw_out;

    logic s_reg_read_index;
    
    logic [15:0] s_reg_addr;
    logic [15:0] s_reg_data;
    logic s_reg_addr_index;
    logic s_reg_data_index;
    
    logic [15:0] reg_read_out;
    logic read_data_en;
    
    logic [15:0] s_reg_address;

    logic [23:0] s_read_rx_data_a;
    logic [23:0] s_read_rx_data_b;
    logic [23:0] s_read_rx_data_c;
    logic [23:0] s_read_rx_data_d;
    logic s_read_frame_start;
    logic s_read_frame_reset;
    logic s_read_axis_tready;
    logic s_read_axis_tlast;
    // logic s_read_data_valid;
    logic s_read_axis_tvalid;

    logic [23:0] s_test_cnt;
    logic [7:0] s_state_led_ctr;

    // MIPI signals
    logic s_reset;
    logic s_csi2_reset;
    logic s_clk_lock;
    logic s_csi_done;
    logic [0:0] s_axis_video_tuser;
    logic [23:0] s_axis_tdata_a;
    logic [23:0] s_axis_tdata_b;
    logic [23:0] s_axis_tdata_c;
    logic [23:0] s_axis_tdata_d;

    logic reg_roic_sync;
    logic ti_roic_sync;
    logic ti_roic_tp_sel;
    logic [1:0]  ti_roic_str;
    logic [15:0] ti_roic_reg_addr;
    logic [15:0] ti_roic_reg_data;
    logic gen_sync_start;
    
    // TI ROIC deser signals
    logic ti_roic_deser_reset;
    logic ti_roic_deser_dly_tap_ld;
    logic [4:0] ti_roic_deser_dly_tap_in;
    logic ti_roic_deser_dly_data_ce;
    logic ti_roic_deser_dly_data_inc;
    logic ti_roic_deser_align_mode;
    logic ti_roic_deser_align_start;
    logic [4:0] ti_roic_deser_shift_set[11:0];
    logic [4:0] ti_roic_deser_align_shift[11:0];
    logic [11:0] ti_roic_deser_align_done;


    // clk_ctrl module instantiation
    clk_ctrl clk_inst0 (
        .reset          (1'b0),
        .clk_in1_p      (MCLK_100M_p),
        .clk_in1_n      (MCLK_100M_n),
        .locked         (s_clk_lock),
        // .c0             (s_clk_100mhz),     // 100MHz
        // .c1             (s_clk_25mhz),      // 25MHz
        // .axi_clk        (s_axi_clk_200M),   // 200MHz
        .dphy_clk       (s_dphy_clk_200M),  // 200MHz
        // .roic_mclk      (s_clk_20mhz),           // 20MHz
        // .spi_clk        (s_clk_10mhz)
        .c0             (s_clk_100mhz),     // 100MHz
        .c1             (s_clk_20mhz),      // 25MHz
        .axi_clk        (s_axi_clk_200M)   // 200MHz
    );

    // assign s_dphy_clk_200M = s_axi_clk_200M; // Use 200MHz clock for DPHY
    assign eim_clk = s_clk_100mhz; // Use 100MHz clock for EIM
    assign s_clk_10mhz = s_test_cnt[0]; // Example usage of test counter for 10MHz clock
    assign s_clk_5mhz = s_test_cnt[1]; // Example usage of test counter for 10MHz clock

    // MIPI CSI2 TX module instantiation
    mipi_csi2_tx_top inst_mipi_csi2_tx (
        .reset                  (s_csi2_reset),
        .axi_clk_200M           (s_axi_clk_200M),
        .dphy_clk_200M          (s_dphy_clk_200M),
        .clk_100M               (s_clk_100mhz),
        .eim_clk                (eim_clk),
        .locked_i               (s_clk_lock),
        .read_frame_start       (s_read_frame_start),
        .read_frame_reset       (s_read_frame_reset),
        .s_axis_tdata_a         (s_axis_tdata_a),
        .s_axis_tdata_b         (s_axis_tdata_b),
        .s_axis_tdata_c         (s_axis_tdata_c),  // Using A data for C
        .s_axis_tdata_d         (s_axis_tdata_d),  // Using B data for D
        .s_axis_tlast           (s_read_axis_tlast),
        .s_axis_tready          (s_read_axis_tready),
        .s_axis_tvalid          (s_read_axis_tvalid),
        .s_axis_tstrb           (3'b000),            // All bits active
        .s_axis_tkeep           (3'b111),            // All bits kept
        .mipi_phy_if_clk_hs_p   (mipi_phy_if_clk_hs_p),
        .mipi_phy_if_clk_hs_n   (mipi_phy_if_clk_hs_n),
        .mipi_phy_if_clk_lp_p   (mipi_phy_if_clk_lp_p),
        .mipi_phy_if_clk_lp_n   (mipi_phy_if_clk_lp_n),
        .mipi_phy_if_data_hs_p  (mipi_phy_if_data_hs_p),
        .mipi_phy_if_data_hs_n  (mipi_phy_if_data_hs_n),
        .mipi_phy_if_data_lp_p  (mipi_phy_if_data_lp_p),
        .mipi_phy_if_data_lp_n  (mipi_phy_if_data_lp_n),
        .csi2_word_count        (csi2_word_count),
        .m_axis_video_tuser     (s_axis_video_tuser),
        .done                   (s_csi_done),
        .interrupt              (),
        .status                 (),
        .system_rst_out         ()
    );

    // init module instantiation
    init init_inst (
        // .fsm_clk            (s_clk_25mhz),
        .fsm_clk            (s_clk_20mhz),
        .en_pwr_off         (en_pwr_off),
        .en_pwr_dwn         (en_pwr_dwn),
        .init_rst           (init_rst),
        .pwr_init_step1     (s_pwr_init_step1),
        .pwr_init_step2     (s_pwr_init_step2),
        .pwr_init_step3     (s_pwr_init_step3),
        .pwr_init_step4     (s_pwr_init_step4),
        .pwr_init_step5     (s_pwr_init_step5),
        .pwr_init_step6     (s_pwr_init_step6),
        .roic_reset         (s_roic_reset)
    );


    // SPI slave instantiation 
    // Note: Placeholder, actual implementation needs to be provided    
    spi_slave #(
        .header     (header),
        .payload    (payload),
        .addrsz     (addrsz),
        .pktsz      (pktsz)
    )
    host_if_inst (
        .clk               (s_clk_100mhz),
        .reset             (s_reset),
        .SCLK              (SCLK),
        .SSB               (SSB),
        .MOSI              (MOSI),
        .MISO              (s_miso),
        .spi_start_flag    (s_spi_start_flag),
        .read_data         (reg_read_out[payload-1:0]),
        .read_en           (read_data_en),
        .reg_addr          (s_reg_addr[addrsz-1:0]),
        .addr_valid        (s_addr_dv),
        .wr_data           (s_reg_data[payload-1:0]),
        .wr_data_valid     (s_reg_data_index),
        .rw_out            (s_rw_out)
    );

    assign s_reg_address = ({2'b00,s_reg_addr[addrsz-1:0]});

    // reg_map_gemini reg_map_inst (
    //     .eim_clk                    (s_clk_100mhz),
    //     .eim_rst                    (sys_rst),
    //     .fsm_clk                    (s_clk_20mhz),
    //     .rst                        (rst),
    //     .sys_clk                    (s_clk_100mhz),
    //     .sys_rst                    (sys_rst),
    //     .prep_req                   (PREP_REQ),
    //     .exp_req                    (EXP_REQ),
    //     .row_cnt                    (row_cnt),
    //     .col_cnt                    (col_cnt),
    //     .row_end                    (row_end),
    //     .fsm_rst_index              (FSM_rst_index),
    //     .fsm_init_index             (FSM_init_index),
    //     .fsm_back_bias_index        (FSM_back_bias_index),
    //     .fsm_flush_index            (FSM_flush_index),
    //     .fsm_aed_read_index         (FSM_aed_read_index),
    //     .fsm_exp_index              (FSM_exp_index),
    //     .fsm_read_index             (FSM_read_index),
    //     .fsm_idle_index             (FSM_idle_index),
    //     .gate_gpio_data             (),
    //     .ready_to_get_image         (ready_to_get_image),
    //     .valid_aed_read_skip        (valid_aed_read_skip),
    //     .aed_ready_done             (aed_ready_done),
    //     .panel_stable_exist         (s_panel_stable_exist),
    //     .exp_read_exist             (s_exp_read_exist),
    //     .ack_tx_end                 (ack_tx_end),
    //     .up_roic_reg                (up_roic_reg),
    //     .roic_temperature           (r_roic_temperature),
    //     .roic_reg_in_a              (r_roic_reg_in_a),
    //     .roic_reg_in_b              (r_roic_reg_in_b),
    //     .l_roic_temperature         (l_roic_temperature),
    //     .l_roic_reg_in_a            (l_roic_reg_in_a),
    //     .l_roic_reg_in_b            (l_roic_reg_in_b),
    //     .reg_read_index             (s_reg_read_index),
    //     .reg_addr                   (s_reg_address),
    //     .reg_data                   (s_reg_data),
    //     .reg_addr_index             (s_reg_addr_index),
    //     .reg_data_index             (s_reg_data_index),
    //     .reg_read_out               (reg_read_out),
    //     .read_data_en               (read_data_en),
    //     .en_pwr_dwn                 (en_pwr_dwn),
    //     .en_pwr_off                 (en_pwr_off),
    //     .system_rst                 (system_rst),
    //     .reset_fsm                  (reset_FSM),
    //     .org_reset_fsm              (org_reset_FSM),
    //     .dummy_get_image            (dummy_get_image),
    //     .exist_get_image            (exist_get_image),
    //     .burst_get_image            (burst_get_image),
    //     .get_dark                   (get_dark),
    //     .get_bright                 (get_bright),
    //     .cmd_get_bright             (cmd_get_bright),
    //     .en_aed                     (en_aed),
    //     .aed_th                     (aed_th),
    //     .nega_aed_th                (nega_aed_th),
    //     .posi_aed_th                (posi_aed_th),
    //     .sel_aed_roic               (sel_aed_roic),
    //     .num_trigger                (num_trigger),
    //     .sel_aed_test_roic          (sel_aed_test_roic),
    //     .ready_aed_read             (ready_aed_read),
    //     .aed_dark_delay             (aed_dark_delay),
    //     .en_back_bias               (en_back_bias),
    //     .en_flush                   (en_flush),
    //     .en_panel_stable            (en_panel_stable),
    //     .readout_width              (readout_width),
    //     .cycle_width                (cycle_width),
    //     .mux_image_height           (image_height),
    //     .dsp_image_height           (dsp_image_height),
    //     .aed_read_image_height      (aed_read_image_height),
    //     .frame_rpt                  (frame_rpt),
    //     .saturation_flush_repeat    (saturation_flush_repeat),
    //     .readout_count              (readout_count),
    //     .max_v_count                (max_v_count),
    //     .max_h_count                (max_h_count),
    //     .csi2_word_count            (csi2_word_count),
    //     .roic_burst_cycle           (roic_burst_cycle),
    //     .start_roic_burst_clk       (start_roic_burst_clk),
    //     .end_roic_burst_clk         (end_roic_burst_clk),
    //     .gate_mode1                 (),
    //     .gate_mode2                 (),
    //     .gate_cs1                   (),
    //     .gate_cs2                   (),
    //     .gate_sel                   (),
    //     .gate_ud                    (),
    //     .gate_stv_mode              (),
    //     .gate_oepsn                 (),
    //     .gate_lr1                   (sig_gate_lr1),
    //     .gate_lr2                   (sig_gate_lr2),
    //     .stv_sel_h                  (),
    //     .stv_sel_l1                 (),
    //     .stv_sel_r1                 (),
    //     .stv_sel_l2                 (),
    //     .stv_sel_r2                 (),
    //     .up_back_bias               (up_back_bias),
    //     .dn_back_bias               (down_back_bias),
    //     .up_back_bias_opr           (up_back_bias_opr),
    //     .dn_back_bias_opr           (down_back_bias_opr),
    //     .up_gate_stv1               (up_gate_stv1),
    //     .dn_gate_stv1               (down_gate_stv1),
    //     .up_gate_stv2               (up_gate_stv2),
    //     .dn_gate_stv2               (down_gate_stv2),
    //     .up_gate_cpv1               (up_gate_cpv1),
    //     .dn_gate_cpv1               (down_gate_cpv1),
    //     .up_gate_cpv2               (up_gate_cpv2),
    //     .dn_gate_cpv2               (down_gate_cpv2),
    //     .up_gate_oe1                (up_gate_oe1),
    //     .dn_gate_oe1                (down_gate_oe1),
    //     .up_gate_oe2                (up_gate_oe2),
    //     .dn_gate_oe2                (down_gate_oe2),
    //     .dn_aed_gate_xao_0          (dn_aed_gate_xao_0),
    //     .dn_aed_gate_xao_1          (dn_aed_gate_xao_1),
    //     .dn_aed_gate_xao_2          (dn_aed_gate_xao_2),
    //     .dn_aed_gate_xao_3          (dn_aed_gate_xao_3),
    //     .dn_aed_gate_xao_4          (dn_aed_gate_xao_4),
    //     .dn_aed_gate_xao_5          (dn_aed_gate_xao_5),
    //     .up_aed_gate_xao_0          (up_aed_gate_xao_0),
    //     .up_aed_gate_xao_1          (up_aed_gate_xao_1),
    //     .up_aed_gate_xao_2          (up_aed_gate_xao_2),
    //     .up_aed_gate_xao_3          (up_aed_gate_xao_3),
    //     .up_aed_gate_xao_4          (up_aed_gate_xao_4),
    //     .up_aed_gate_xao_5          (up_aed_gate_xao_5),
    //     .aed_detect_line_0          (aed_detect_line_0),
    //     .aed_detect_line_1          (aed_detect_line_1),
    //     .aed_detect_line_2          (aed_detect_line_2),
    //     .aed_detect_line_3          (aed_detect_line_3),
    //     .aed_detect_line_4          (aed_detect_line_4),
    //     .aed_detect_line_5          (aed_detect_line_5),
    //     .up_roic_sync               (up_roic_sync),
    //     .up_roic_aclk_0             (up_roic_aclk_0),
    //     .up_roic_aclk_1             (up_roic_aclk_1),
    //     .up_roic_aclk_2             (up_roic_aclk_2),
    //     .up_roic_aclk_3             (up_roic_aclk_3),
    //     .up_roic_aclk_4             (up_roic_aclk_4),
    //     .up_roic_aclk_5             (up_roic_aclk_5),
    //     .up_roic_aclk_6             (up_roic_aclk_6),
    //     .up_roic_aclk_7             (up_roic_aclk_7),
    //     .up_roic_aclk_8             (up_roic_aclk_8),
    //     .up_roic_aclk_9             (up_roic_aclk_9),
    //     .up_roic_aclk_10            (up_roic_aclk_10),
    //     .burst_break_pt_0           (burst_break_pt_0),
    //     .burst_break_pt_1           (burst_break_pt_1),
    //     .burst_break_pt_2           (burst_break_pt_2),
    //     .burst_break_pt_3           (burst_break_pt_3),
    //     .roic_reg_set_0             (roic_reg_set_0),
    //     .roic_reg_set_1             (roic_reg_set_1),
    //     .roic_reg_set_1_dual        (roic_reg_set_1_dual),
    //     .roic_reg_set_2             (roic_reg_set_2),
    //     .roic_reg_set_3             (roic_reg_set_3),
    //     .roic_reg_set_4             (roic_reg_set_4),
    //     .roic_reg_set_5             (roic_reg_set_5),
    //     .roic_reg_set_6             (roic_reg_set_6),
    //     .roic_reg_set_7             (roic_reg_set_7),
    //     .roic_reg_set_8             (roic_reg_set_8),
    //     .roic_reg_set_9             (roic_reg_set_9),
    //     .roic_reg_set_10            (roic_reg_set_10),
    //     .roic_reg_set_11            (roic_reg_set_11),
    //     .roic_reg_set_12            (roic_reg_set_12),
    //     .roic_reg_set_13            (roic_reg_set_13),
    //     .roic_reg_set_14            (roic_reg_set_14),
    //     .roic_reg_set_15            (roic_reg_set_15),
    //     // TI-ROIC Register signals
    //     .ti_roic_sync               (reg_roic_sync),
    //     .ti_roic_tp_sel             (ti_roic_tp_sel),
    //     .ti_roic_str                (ti_roic_str),
    //     .ti_roic_reg_addr           (ti_roic_reg_addr),
    //     .ti_roic_reg_data           (ti_roic_reg_data),
    //     // TI-ROIC Deserializer signals
    //     .ti_roic_deser_reset        (ti_roic_deser_reset),
    //     .ti_roic_deser_dly_tap_ld   (ti_roic_deser_dly_tap_ld),
    //     .ti_roic_deser_dly_tap_in   (ti_roic_deser_dly_tap_in),
    //     .ti_roic_deser_dly_data_ce  (ti_roic_deser_dly_data_ce),
    //     .ti_roic_deser_dly_data_inc (ti_roic_deser_dly_data_inc),
    //     .ti_roic_deser_align_mode   (ti_roic_deser_align_mode),
    //     .ti_roic_deser_align_start  (ti_roic_deser_align_start),
    //     .ti_roic_deser_shift_set    (ti_roic_deser_shift_set),
    //     .ti_roic_deser_align_shift  (ti_roic_deser_align_shift),
    //     .ti_roic_deser_align_done   (ti_roic_deser_align_done),
    //     .ld_io_delay_tab            (LD_IO_DELAY_TAB),
    //     .io_delay_tab               (IO_DELAY_TAB),
    //     .sel_roic_reg               (sel_roic_reg),
    //     .gate_size                  (gate_size),
    //     .en_16bit_adc               (en_16bit_adc),
    //     .en_test_pattern_col        (en_test_pattern_col),
    //     .en_test_pattern_row        (en_test_pattern_row),
    //     .en_test_roic_col           (en_test_roic_col),        
    //     .en_test_roic_row           (en_test_roic_row),
    //     .aed_test_mode1             (aed_test_mode1),
    //     .aed_test_mode2             (aed_test_mode2),
    //     .exp_ack                    (EXP_ACK)
    // );    
    
    roic_gate_drv_gemini roic_gate_drv_inst (
        // .fsm_clk          (s_clk_25mhz),
        .fsm_clk          (s_clk_20mhz),
        .fsm_drv_rst      (fsm_drv_rst),
        .rst              (rst),
        .row_cnt          (row_cnt),
        .col_cnt          (col_cnt),
        .aed_read_image_height  (aed_read_image_height),
        .gate_size              (gate_size),
        .fsm_back_bias_index    (FSM_back_bias_index),
        .fsm_flush_index        (FSM_flush_index),
        .fsm_aed_read_index     (FSM_aed_read_index),
        .fsm_read_index         (FSM_read_index),
        .col_end                (col_end),
        .disable_aed_read_xao   (disable_aed_read_xao),
        .up_back_bias     (up_back_bias),
        .dn_back_bias     (down_back_bias),
        .up_back_bias_opr (up_back_bias_opr),
        .dn_back_bias_opr (down_back_bias_opr),
        .up_gate_stv1     (up_gate_stv1),
        .dn_gate_stv1     (down_gate_stv1),
        .up_gate_stv2     (up_gate_stv2),
        .dn_gate_stv2     (down_gate_stv2),
        .up_gate_cpv1     (up_gate_cpv1),
        .dn_gate_cpv1     (down_gate_cpv1),
        .up_gate_cpv2     (up_gate_cpv2),
        .dn_gate_cpv2     (down_gate_cpv2),
        .up_gate_oe1      (up_gate_oe1),
        .dn_gate_oe1      (down_gate_oe1),
        .up_gate_oe2      (up_gate_oe2),
        .dn_gate_oe2      (down_gate_oe2),
        .up_aed_gate_xao_0(up_aed_gate_xao_0),
        .dn_aed_gate_xao_0(dn_aed_gate_xao_0),
        .up_aed_gate_xao_1(up_aed_gate_xao_1),
        .dn_aed_gate_xao_1(dn_aed_gate_xao_1),
        .up_aed_gate_xao_2(up_aed_gate_xao_2),
        .dn_aed_gate_xao_2(dn_aed_gate_xao_2),
        .up_aed_gate_xao_3(up_aed_gate_xao_3),
        .dn_aed_gate_xao_3(dn_aed_gate_xao_3),
        .up_aed_gate_xao_4(up_aed_gate_xao_4),
        .dn_aed_gate_xao_4(dn_aed_gate_xao_4),
        .up_aed_gate_xao_5(up_aed_gate_xao_5),
        .dn_aed_gate_xao_5(dn_aed_gate_xao_5),
        .up_roic_sync     (up_roic_sync),
        .up_roic_aclk_0   (up_roic_aclk_0),
        .up_roic_aclk_1   (up_roic_aclk_1),
        .up_roic_aclk_2   (up_roic_aclk_2),
        .up_roic_aclk_3   (up_roic_aclk_3),
        .up_roic_aclk_4   (up_roic_aclk_4),
        .up_roic_aclk_5   (up_roic_aclk_5),
        .up_roic_aclk_6   (up_roic_aclk_6),
        .up_roic_aclk_7   (up_roic_aclk_7),
        .up_roic_aclk_8   (up_roic_aclk_8),
        .up_roic_aclk_9   (up_roic_aclk_9),
        .up_roic_aclk_10  (up_roic_aclk_10),
        .burst_break_pt_0 (burst_break_pt_0),
        .burst_break_pt_1 (burst_break_pt_1),
        .burst_break_pt_2 (burst_break_pt_2),
        .burst_break_pt_3 (burst_break_pt_3),
        .aed_detect_line_0(aed_detect_line_0),
        .aed_detect_line_1(aed_detect_line_1),
        .aed_detect_line_2(aed_detect_line_2),
        .aed_detect_line_3(aed_detect_line_3),
        .aed_detect_line_4(aed_detect_line_4),
        .aed_detect_line_5(aed_detect_line_5),
        .back_bias        (s_back_bias),
        .gate_stv_1_1     (gate_stv_1_1),
        .gate_cpv         (sig_gate_cpv),
        .gate_oe1         (GF_OE),
        .gate_oe2         (),
        // .gate_oe1         (GF_OE1),
        // .gate_oe2         (GF_OE2),
        .gate_xao_0       (gate_xao_0),
        .gate_xao_1       (gate_xao_1),
        .gate_xao_2       (gate_xao_2),        
        .gate_xao_3       (gate_xao_3),
        .gate_xao_4       (gate_xao_4),
        .gate_xao_5       (gate_xao),
        .roic_sync        (s_roic_sync),
        .roic_aclk        (s_roic_aclk),
        .valid_aed_read_skip(valid_aed_read_skip),
        .roic_data_read_index(roic_data_read_index),
        .valid_read_out   ()
    );

    // ctrl_FSM module instantiation
    ctrl_FSM ctrl_FSM_inst (
        // .fsm_clk                    (s_clk_25mhz),
        .fsm_clk                    (s_clk_20mhz),
        .rst                        (rst),
        .fsm_drv_rst                (fsm_drv_rst),
        .reset_FSM                  (reset_FSM),
        .burst_get_image            (burst_get_image),
        .get_dark                   (get_dark),
        .get_bright                 (get_bright),
        .cmd_get_bright             (cmd_get_bright),
        .cycle_width                (cycle_width),
        .image_height               (image_height),
        .dsp_image_height           (dsp_image_height),
        .frame_rpt                  (frame_rpt),
        .saturation_flush_repeat    (saturation_flush_repeat),
        .readout_count              (readout_count),
        .ready_aed_read             (ready_aed_read),
        .aed_dark_delay             (aed_dark_delay),
        .en_aed                     (en_aed),
        .aed_read_image_height      (aed_read_image_height),
        .disable_aed_read_xao       (disable_aed_read_xao),
        .on_aed_dark_trigger        (on_aed_dark_trigger),
        .on_aed_trigger             (AED_TRIG),
        .en_back_bias               (en_back_bias),
        .en_flush                   (en_flush),
        .en_panel_stable            (en_panel_stable),
        .col_end                    (col_end),
        .row_end                    (row_end),
        .FSM_rst_index              (FSM_rst_index),
        .FSM_init_index             (FSM_init_index),
        .FSM_back_bias_index        (FSM_back_bias_index),
        .FSM_flush_index            (FSM_flush_index),
        .FSM_aed_read_index         (FSM_aed_read_index),
        .FSM_exp_index              (FSM_exp_index),
        .FSM_read_index             (FSM_read_index),
        .FSM_idle_index             (FSM_idle_index),
        .ready_to_get_image         (ready_to_get_image),
        .aed_ready_done             (aed_ready_done),
        .aed_ready_done_dark        (aed_ready_done_dark),
        .panel_stable_exist         (s_panel_stable_exist),
        .exp_read_exist             (s_exp_read_exist),
        .valid_posi_flag            (valid_posi_flag),
        .valid_nega_flag            (valid_nega_flag),
        .row_cnt                    (row_cnt),
        .col_cnt                    (col_cnt),
        .valid_read_out             (valid_read_out),
        .gate_cpv_init              (gate_cpv_init)
    );    
    
 
    assign s_roic_sdi_0 = RF_SPI_SDO[0]; 
    
    // Data valid signals
    // assign exr_valid_roic_data = valid_roic_data;

    assign ti_roic_sync = (reg_roic_sync || hi_FSM_read_index) ? 1'b1 : 1'b0;

// ====================================================================

    assign MISO = s_miso;

    // assign s_read_axis_tvalid = s_read_data_valid;

    assign s_axis_video_tuser[0] = s_read_frame_start;
    assign s_axis_tdata_a = s_read_rx_data_a;
    assign s_axis_tdata_b = s_read_rx_data_b;
    assign s_axis_tdata_c = s_read_rx_data_a;
    assign s_axis_tdata_d = s_read_rx_data_b;

    assign s_reg_addr_index = (s_rw_out == 1'b0 && s_addr_dv == 1'b1) ? 1'b1 : 1'b0;
    assign s_reg_read_index = (s_rw_out == 1'b1 && s_addr_dv == 1'b1) ? 1'b1 : 1'b0;
    
    // assign DCLK_R = sig_dclk;

    always_ff @(posedge s_clk_20mhz) begin
        FSM_read_index_1d <= FSM_read_index;
        FSM_read_index_2d <= FSM_read_index_1d;
    end

    // assign hi_FSM_read_index = ~FSM_read_index_1d & FSM_read_index_2d;
    assign hi_FSM_read_index = ~FSM_read_index_2d & FSM_read_index_1d;

    assign GF_CPV = sig_gate_cpv | gate_cpv_init;
    assign GF_STV_R = sig_gate_lr1 ? gate_stv_1_1 : 1'bz;
    assign GF_STV_L = ~sig_gate_lr1 ? gate_stv_1_1 : 1'bz;

    // assign GF_CS1 = 1'b1;
    // assign GF_CS2 = 1'b1;

    assign GF_LR = 1'b1;

    assign GF_XAO[5] = en_aed ? gate_xao_0 : 1'b1;
    assign GF_XAO[4] = en_aed ? gate_xao_1 : 1'b1;
    assign GF_XAO[3] = en_aed ? gate_xao_2 : 1'b1;
    assign GF_XAO[2] = en_aed ? gate_xao_3 : 1'b1;
    assign GF_XAO[1] = en_aed ? gate_xao_4 : 1'b1;
    assign GF_XAO[0] = en_aed ? gate_xao   : 1'b1;


    assign s_reset = !nRST;

    // always_ff @(posedge s_clk_25mhz) begin
    always_ff @(posedge s_clk_20mhz) begin
        if (system_rst == 1'b1 || init_rst == 1'b1 || s_reset == 1'b1) begin
            rst <= 1'b0;
        end else begin
            rst <= 1'b1;
        end
    end

    always_ff @(posedge s_clk_100mhz) begin
        if (system_rst == 1'b1 || s_reset == 1'b1) begin
            s_csi2_reset <= 1'b1;
        end else begin
            s_csi2_reset <= 1'b0;
        end
    end

    // always_ff @(posedge s_clk_25mhz) begin
    always_ff @(posedge s_clk_20mhz) begin
        if (FSM_rst_index == 1'b1 || ~rst) begin
            fsm_drv_rst <= 1'b0;
        end else begin
            fsm_drv_rst <= 1'b1;
        end
    end

    always_ff @(posedge s_clk_100mhz) begin
        sys_rst <= rst;
    end

    always_ff @(posedge s_clk_100mhz) begin
        drv_rst <= fsm_drv_rst;
    end

    always_ff @(posedge eim_clk) begin
        eim_rst <= rst;
    end

    assign PREP_ACK = 1'b0;

    assign ROIC_TP_SEL  = ti_roic_tp_sel;
    assign ROIC_MCLK0    = s_clk_20mhz;
    assign ROIC_MCLK1    = s_clk_20mhz;
    assign ROIC_SYNC    = ti_roic_sync;

    assign ROIC_VBIAS = s_back_bias;
    assign ROIC_AVDD1 = s_pwr_init_step1;
    assign ROIC_AVDD2 = s_pwr_init_step2;

    // assign RF_SPI_SCK = s_roic_sck0;
    // assign RF_SPI_SDI[0] = s_roic_sdo0;

    // TI ROIC module interface
    //--------------------------------------------------------------------------
    // Configuration Parameters
    //--------------------------------------------------------------------------
    localparam int WORD_SIZE     = 24;     // 24-bit data word width
    
    //--------------------------------------------------------------------------
    // Clock and Reset Signals
    //--------------------------------------------------------------------------
    // logic mclk;                      // 20MHz master clock for system
    // logic clk_reset;                 // System clock domain reset
    logic deser_reset;               // Deserializer reset
    
    //--------------------------------------------------------------------------
    // Deserializer Control Interface 
    //--------------------------------------------------------------------------
    logic ld_dly_tap;                // Load delay tap value signal
    logic in_delay_data_ce;          // Delay element clock enable
    logic in_delay_data_inc;         // Delay increment/decrement control
    logic [4:0] in_delay_tap_in;     // Delay tap value input (0-31)
    logic [4:0] in_delay_tap_out [11:0];    // Delay tap value output monitor
      //--------------------------------------------------------------------------
    // Bit Alignment Signals
    //--------------------------------------------------------------------------
    logic [4:0] extra_shift [11:0];         // Additional bit alignment shift amount
    logic align_to_fclk;             // Select mode: 0=pattern detection, 1=manual
    logic align_start;               // Start alignment process
    logic [4:0] shift_out [11:0];           // Selected shift amount output
    logic [11:0] align_done;                // Alignment completion flag

    //--------------------------------------------------------------------------
    // Internal Signals
    //--------------------------------------------------------------------------
    logic [11:0] bit_clk;                   // High-speed bit clock
    logic [11:0] clk_div_out;               // Divided clock (÷4) 
    logic [11:0] clk_div_12;                // Further divided clock (÷12)    
    
    logic [11:0] data_read_req;             // Data read request signal

    // Output signals for data validation
    logic [11:0] valid_read_enable;         // Enable signal for reading reordered data

    (* mark_debug="true" *) logic [23:0] ila_reordered_data [0:0];
    logic [23:0] reordered_data_a [11:0];     // Reordered data output from ti_roic_top
    logic [23:0] reordered_data_b [11:0];     // Reordered data output from ti_roic_top
    logic [11:0] reordered_valid;           // Reordered data valid flag
    logic [11:0] channel_detected;          // First channel detection signal
    logic valid_read_mem;
    logic [23:0] roic_read_data;

    logic s_rf_spi_sen;
    logic [191:0] sdoutWord;
    logic s_spiReady;
    logic s_spidut_en_1d;
    logic s_spidut_en_2d;

    assign RF_SPI_SEN = {12{s_rf_spi_sen}};

    /**
     * @brief TI ROIC SPI for register set .
     */
    roic_spi ti_roic_spi_inst (
        .reset      (deser_reset),
        .clk        (s_clk_5mhz),
        .address    (ti_roic_reg_addr[7:0]),
        .data       (ti_roic_reg_data),
        .DUT_EN     (ti_roic_reg_addr[15]),
        // .spiReady   (ti_roic_reg_addr[8]),
        .spiReady   (s_spiReady),
        .DUT_SDOUT  (RF_SPI_SDO[0]),
        .DUT_SCLK   (RF_SPI_SCK),
        .DUT_SDATA  (RF_SPI_SDI[0]),
        .DUT_SEN    (s_rf_spi_sen),
        .sdoutWord  (sdoutWord)
    );

    always_ff @(posedge s_clk_5mhz or posedge deser_reset) begin
        if (deser_reset) begin
            s_spidut_en_1d <= 1'b0;
            s_spidut_en_2d <= 1'b0;
        end else begin
            s_spidut_en_1d <= ti_roic_reg_addr[15];
            s_spidut_en_2d <= s_spidut_en_1d;
        end
    end
    assign s_spiReady = s_spidut_en_1d & ~s_spidut_en_2d;
    

    ti_roic_tg roic_tg_gen_int(
        .clk            (s_clk_20mhz),
        .rst            (deser_reset),
        .str            (ti_roic_str),
        .sync           (ti_roic_sync),
        .tp_sel         (ti_roic_tp_sel),
        .reg_addr       (ti_roic_reg_addr[7:0]),
        .reg_data       (ti_roic_reg_data),
        .sync_start     (gen_sync_start),
        .readout_width  (readout_width),
        .IRST           (),
        .SHR            (),
        .SHS            (),
        .LPF1           (),
        .LPF2           (),
        .TDEF           (),
        .GATE_ON        (),
        .DF_SM0         (),
        .DF_SM1         (),
        .DF_SM2         (),
        .DF_SM3         (),
        .DF_SM4         (),
        .DF_SM5         ()
    );


    assign deser_reset = ti_roic_deser_reset;
    assign ld_dly_tap = ti_roic_deser_dly_tap_ld;
    assign in_delay_data_ce = ti_roic_deser_dly_data_ce;
    assign in_delay_data_inc = ti_roic_deser_dly_data_inc;
    assign in_delay_tap_in = ti_roic_deser_dly_tap_in;
    assign align_to_fclk = ti_roic_deser_align_mode;
    assign align_start = ti_roic_deser_align_start;

    always_comb begin
        // Default values for shift_out and align_done
        for (int i = 0; i < 12; i++) begin
            extra_shift[i] = ti_roic_deser_shift_set[i];
            ti_roic_deser_align_shift[i] = shift_out[i];
            ti_roic_deser_align_done[i] = align_done[i];
        end
    end

    // assign extra_shift = ti_roic_deser_shift_set;
    // assign ti_roic_deser_align_shift = shift_out;
    // assign ti_roic_deser_align_done = align_done;
    logic s_fclk_p;
    logic s_fclk_n;

    assign s_fclk_p = R_ROIC_FCLKo_p[0] & R_ROIC_FCLKo_p[1] & R_ROIC_FCLKo_p[2] & R_ROIC_FCLKo_p[3] & R_ROIC_FCLKo_p[4] & R_ROIC_FCLKo_p[5] & R_ROIC_FCLKo_p[6] & R_ROIC_FCLKo_p[7] & R_ROIC_FCLKo_p[8] & R_ROIC_FCLKo_p[9] & R_ROIC_FCLKo_p[10] & R_ROIC_FCLKo_p[11];
    assign s_fclk_n = R_ROIC_FCLKo_n[0] & R_ROIC_FCLKo_n[1] & R_ROIC_FCLKo_n[2] & R_ROIC_FCLKo_n[3] & R_ROIC_FCLKo_n[4] & R_ROIC_FCLKo_n[5] & R_ROIC_FCLKo_n[6] & R_ROIC_FCLKo_n[7] & R_ROIC_FCLKo_n[8] & R_ROIC_FCLKo_n[9] & R_ROIC_FCLKo_n[10] & R_ROIC_FCLKo_n[11]; 

            ti_roic_top #(
                .DATA_WIDTH    (WORD_SIZE),     // 24-bit data width
                .IOSTANDARD    ("LVDS_25"),     // LVDS_25 standard for test environment
                .REFCLK_FREQ   (200.0),         // 200MHz reference clock frequency
                .PATTERN_1     (24'hFFF000),    // First alignment pattern
                .PATTERN_2     (24'hFF0000)     // Second alignment pattern
            ) ti_roic_top_inst_0 (
                // Control and reset inputs
                .clk_reset          (s_reset),
                .data_reset         (deser_reset),

                // LVDS differential inputs
                .clk_in_p           (R_ROIC_DCLKo_p[0]),
                .clk_in_n           (R_ROIC_DCLKo_n[0]),
                .data_in_p          (R_DOUTA_H[0]),
                .data_in_n          (R_DOUTA_L[0]),
                
                // Delay control interface
                .ld_dly_tap         (ld_dly_tap),
                .delay_data_ce      (in_delay_data_ce),
                .delay_data_inc     (in_delay_data_inc),
                .delay_tap_in       (in_delay_tap_in),
                .delay_tap_out      (in_delay_tap_out[0]),
                
                // Bit alignment control        
                .align_to_fclk      (align_to_fclk),
                .align_start        (align_start),
                .extra_shift        (extra_shift[0]),
                
                // Data reordering control
                .sync               (ti_roic_sync),

                .data_read_req      (data_read_req[0]),
                
                .data_read_clk      (s_axi_clk_200M),
                // Output signals
                .bit_clk            (bit_clk[0]),
                .clk_div_out        (clk_div_out[0]),
                .clk_div_12         (clk_div_12[0]),
                .shift_out          (shift_out[0]),
                .align_done         (align_done[0]),
                .valid_read_enable  (valid_read_enable[0]),
                .reordered_data_a   (reordered_data_a[0]),
                .reordered_data_b   (reordered_data_b[0]),
                .reordered_valid    (reordered_valid[0]),
                .channel_detected   (channel_detected[0])
            );
            
        assign ila_reordered_data[0] = reordered_data_a[0];


    genvar i;
    generate
        for (i = 1; i < 12; i++) begin : gen_ti_roic_top
            ti_roic_top #(
                .DATA_WIDTH    (WORD_SIZE),     // 24-bit data width
                .IOSTANDARD    ("LVDS_25"),     // LVDS_25 standard for test environment
                .REFCLK_FREQ   (200.0),         // 200MHz reference clock frequency
                .PATTERN_1     (24'hFFF000),    // First alignment pattern
                .PATTERN_2     (24'hFF0000)     // Second alignment pattern
            ) ti_roic_top_inst (
                // Control and reset inputs
                .clk_reset          (s_reset),
                .data_reset         (deser_reset),
                
                // // LVDS differential inputs
                // .clk_in_p           (TI_DCLK_p[i]),
                // .clk_in_n           (TI_DCLK_n[i]),
                // .data_in_p          (TI_DOUT_p[i]),
                // .data_in_n          (TI_DOUT_n[i]),
                // LVDS differential inputs
                .clk_in_p           (R_ROIC_DCLKo_p[i]),
                .clk_in_n           (R_ROIC_DCLKo_n[i]),
                .data_in_p          (R_DOUTA_H[i]),
                .data_in_n          (R_DOUTA_L[i]),
                
                // Delay control interface
                .ld_dly_tap         (ld_dly_tap),
                .delay_data_ce      (in_delay_data_ce),
                .delay_data_inc     (in_delay_data_inc),
                .delay_tap_in       (in_delay_tap_in),
                .delay_tap_out      (in_delay_tap_out[i]),
                
                // Bit alignment control        
                .align_to_fclk      (align_to_fclk),
                .align_start        (align_start),
                .extra_shift        (extra_shift[i]),
                
                // Data reordering control
                .sync               (ti_roic_sync),

                .data_read_req      (data_read_req[i]),
                
                .data_read_clk      (s_axi_clk_200M),
                // Output signals
                .bit_clk            (bit_clk[i]),
                .clk_div_out        (clk_div_out[i]),
                .clk_div_12         (clk_div_12[i]),
                .shift_out          (shift_out[i]),
                .align_done         (align_done[i]),
                .valid_read_enable  (valid_read_enable[i]),
                .reordered_data_a   (reordered_data_a[i]),
                .reordered_data_b   (reordered_data_b[i]),
                .reordered_valid    (reordered_valid[i]),
                .channel_detected   (channel_detected[i])
            );
        end
    endgenerate

    //========================================================================
    // IDELAYCTRL Instance for Deser_by8_group
    //========================================================================
    (* IODELAY_GROUP = "Deser_by8_group" *)
    IDELAYCTRL idelayctrl_inst (
        .RDY        (),
        .REFCLK     (s_axi_clk_200M),
        .RST        (s_reset)
    );


    // read_data_mux module instantiation
    assign valid_roic_data = |valid_read_enable;
        
    assign valid_read_mem = |reordered_valid;

    read_data_mux read_data_mux_inst (
        .sys_clk                (s_clk_100mhz),
        .sys_rst                (sys_rst),
        .eim_clk                (eim_clk),
        .eim_rst                (eim_rst),
        .csi_done               (s_csi_done),
        .dummy_get_image        (dummy_get_image),
        .exist_get_image        (),  //output
        .get_dark               (get_dark),
        .get_bright             (get_bright),
        .dsp_image_height       (dsp_image_height),
        .max_v_count            (max_v_count),
        .max_h_count            (max_h_count),
        .en_test_pattern_col    (en_test_pattern_col),
        .en_test_pattern_row    (en_test_pattern_row),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .FSM_read_index         (valid_read_out),
        .valid_roic_data        (valid_roic_data),
        .roic_read_data_a       (reordered_data_a),
        .roic_read_data_b       (reordered_data_b),
        .valid_read_mem         (valid_read_mem),
        .read_axis_tready       (s_read_axis_tready),
        .read_axis_tlast        (s_read_axis_tlast),  //output
        .read_data_valid        (s_read_axis_tvalid),  //output
        .read_data_out_a        (s_read_rx_data_a),  //output
        .read_data_out_b        (s_read_rx_data_b),  //output
        .read_frame_start       (s_read_frame_start),  //output
        .read_frame_reset       (s_read_frame_reset),  //output
        .read_addr_cnt          (s_read_addr_cnt),  //output
        .read_data_req          (data_read_req),  //output
        .read_vsync             (vsync),        //output
        .read_hsync             (hsync)         //output
    );

    reg_map reg_map_inst (
        .eim_clk                    (s_clk_100mhz),
        .eim_rst                    (sys_rst),
        // .fsm_clk                    (s_clk_25mhz),
        .fsm_clk                    (s_clk_20mhz),
        .rst                        (rst),
        .sys_clk                    (s_clk_100mhz),
        .sys_rst                    (sys_rst),
        .prep_req                   (PREP_REQ),
        .exp_req                    (EXP_REQ),
        .row_cnt                    (row_cnt),
        .col_cnt                    (col_cnt),
        .row_end                    (row_end),
        .fsm_rst_index              (FSM_rst_index),
        .fsm_init_index             (FSM_init_index),
        .fsm_back_bias_index        (FSM_back_bias_index),
        .fsm_flush_index            (FSM_flush_index),
        .fsm_aed_read_index         (FSM_aed_read_index),
        .fsm_exp_index              (FSM_exp_index),
        .fsm_read_index             (FSM_read_index),
        .fsm_idle_index             (FSM_idle_index),
        .gate_gpio_data             (),
        .ready_to_get_image         (ready_to_get_image),
        .valid_aed_read_skip        (valid_aed_read_skip),
        .aed_ready_done             (aed_ready_done),
        .panel_stable_exist         (s_panel_stable_exist),
        .exp_read_exist             (s_exp_read_exist),
        .ack_tx_end                 (ack_tx_end),
        .up_roic_reg                (up_roic_reg),
        .roic_temperature           (r_roic_temperature),
        .roic_reg_in_a              (r_roic_reg_in_a),
        .roic_reg_in_b              (r_roic_reg_in_b),
        .l_roic_temperature         (l_roic_temperature),
        .l_roic_reg_in_a            (l_roic_reg_in_a),
        .l_roic_reg_in_b            (l_roic_reg_in_b),
        .reg_read_index             (s_reg_read_index),
        .reg_addr                   (s_reg_address),
        .reg_data                   (s_reg_data),
        .reg_addr_index             (s_reg_addr_index),
        .reg_data_index             (s_reg_data_index),
        .reg_read_out               (reg_read_out),
        .read_data_en               (read_data_en),
        .en_pwr_dwn                 (en_pwr_dwn),
        .en_pwr_off                 (en_pwr_off),
        .system_rst                 (system_rst),
        .reset_fsm                  (reset_FSM),
        .org_reset_fsm              (org_reset_FSM),
        .dummy_get_image            (dummy_get_image),
        .exist_get_image            (exist_get_image),
        .burst_get_image            (burst_get_image),
        .get_dark                   (get_dark),
        .get_bright                 (get_bright),
        .cmd_get_bright             (cmd_get_bright),
        .en_aed                     (en_aed),
        .aed_th                     (aed_th),
        .nega_aed_th                (nega_aed_th),
        .posi_aed_th                (posi_aed_th),
        .sel_aed_roic               (sel_aed_roic),
        .num_trigger                (num_trigger),
        .sel_aed_test_roic          (sel_aed_test_roic),
        .ready_aed_read             (ready_aed_read),
        .aed_dark_delay             (aed_dark_delay),
        .en_back_bias               (en_back_bias),
        .en_flush                   (en_flush),
        .en_panel_stable            (en_panel_stable),
        .readout_width              (readout_width),
        .cycle_width                (cycle_width),
        .mux_image_height           (image_height),
        .dsp_image_height           (dsp_image_height),
        .aed_read_image_height      (aed_read_image_height),
        .frame_rpt                  (frame_rpt),
        .saturation_flush_repeat    (saturation_flush_repeat),
        .readout_count              (readout_count),
        .max_v_count                (max_v_count),
        .max_h_count                (max_h_count),
        .csi2_word_count            (csi2_word_count),
        .roic_burst_cycle           (roic_burst_cycle),
        .start_roic_burst_clk       (start_roic_burst_clk),
        .end_roic_burst_clk         (end_roic_burst_clk),
        .gate_mode1                 (),
        .gate_mode2                 (),
        .gate_cs1                   (),
        .gate_cs2                   (),
        .gate_sel                   (),
        .gate_ud                    (),
        .gate_stv_mode              (),
        .gate_oepsn                 (),
        .gate_lr1                   (sig_gate_lr1),
        .gate_lr2                   (sig_gate_lr2),
        .stv_sel_h                  (),
        .stv_sel_l1                 (),
        .stv_sel_r1                 (),
        .stv_sel_l2                 (),
        .stv_sel_r2                 (),
        .up_back_bias               (up_back_bias),
        .dn_back_bias               (down_back_bias),
        .up_back_bias_opr           (up_back_bias_opr),
        .dn_back_bias_opr           (down_back_bias_opr),
        .up_gate_stv1               (up_gate_stv1),
        .dn_gate_stv1               (down_gate_stv1),
        .up_gate_stv2               (up_gate_stv2),
        .dn_gate_stv2               (down_gate_stv2),
        .up_gate_cpv1               (up_gate_cpv1),
        .dn_gate_cpv1               (down_gate_cpv1),
        .up_gate_cpv2               (up_gate_cpv2),
        .dn_gate_cpv2               (down_gate_cpv2),
        .up_gate_oe1                (up_gate_oe1),
        .dn_gate_oe1                (down_gate_oe1),
        .up_gate_oe2                (up_gate_oe2),
        .dn_gate_oe2                (down_gate_oe2),
        .dn_aed_gate_xao_0          (dn_aed_gate_xao_0),
        .dn_aed_gate_xao_1          (dn_aed_gate_xao_1),
        .dn_aed_gate_xao_2          (dn_aed_gate_xao_2),
        .dn_aed_gate_xao_3          (dn_aed_gate_xao_3),
        .dn_aed_gate_xao_4          (dn_aed_gate_xao_4),
        .dn_aed_gate_xao_5          (dn_aed_gate_xao_5),
        .up_aed_gate_xao_0          (up_aed_gate_xao_0),
        .up_aed_gate_xao_1          (up_aed_gate_xao_1),
        .up_aed_gate_xao_2          (up_aed_gate_xao_2),
        .up_aed_gate_xao_3          (up_aed_gate_xao_3),
        .up_aed_gate_xao_4          (up_aed_gate_xao_4),
        .up_aed_gate_xao_5          (up_aed_gate_xao_5),
        .aed_detect_line_0          (aed_detect_line_0),
        .aed_detect_line_1          (aed_detect_line_1),
        .aed_detect_line_2          (aed_detect_line_2),
        .aed_detect_line_3          (aed_detect_line_3),
        .aed_detect_line_4          (aed_detect_line_4),
        .aed_detect_line_5          (aed_detect_line_5),
        .up_roic_sync               (up_roic_sync),
        .up_roic_aclk_0             (up_roic_aclk_0),
        .up_roic_aclk_1             (up_roic_aclk_1),
        .up_roic_aclk_2             (up_roic_aclk_2),
        .up_roic_aclk_3             (up_roic_aclk_3),
        .up_roic_aclk_4             (up_roic_aclk_4),
        .up_roic_aclk_5             (up_roic_aclk_5),
        .up_roic_aclk_6             (up_roic_aclk_6),
        .up_roic_aclk_7             (up_roic_aclk_7),
        .up_roic_aclk_8             (up_roic_aclk_8),
        .up_roic_aclk_9             (up_roic_aclk_9),
        .up_roic_aclk_10            (up_roic_aclk_10),
        .burst_break_pt_0           (burst_break_pt_0),
        .burst_break_pt_1           (burst_break_pt_1),
        .burst_break_pt_2           (burst_break_pt_2),
        .burst_break_pt_3           (burst_break_pt_3),
        .roic_reg_set_0             (roic_reg_set_0),
        .roic_reg_set_1             (roic_reg_set_1),
        .roic_reg_set_1_dual        (roic_reg_set_1_dual),
        .roic_reg_set_2             (roic_reg_set_2),
        .roic_reg_set_3             (roic_reg_set_3),
        .roic_reg_set_4             (roic_reg_set_4),
        .roic_reg_set_5             (roic_reg_set_5),
        .roic_reg_set_6             (roic_reg_set_6),
        .roic_reg_set_7             (roic_reg_set_7),
        .roic_reg_set_8             (roic_reg_set_8),
        .roic_reg_set_9             (roic_reg_set_9),
        .roic_reg_set_10            (roic_reg_set_10),
        .roic_reg_set_11            (roic_reg_set_11),
        .roic_reg_set_12            (roic_reg_set_12),
        .roic_reg_set_13            (roic_reg_set_13),
        .roic_reg_set_14            (roic_reg_set_14),
        .roic_reg_set_15            (roic_reg_set_15),
        .state_led_ctr              (s_state_led_ctr),
        // TI-ROIC Register signals
        .ti_roic_sync               (reg_roic_sync),
        .ti_roic_tp_sel             (ti_roic_tp_sel),
        .ti_roic_str                (ti_roic_str),
        .ti_roic_reg_addr           (ti_roic_reg_addr),
        .ti_roic_reg_data           (ti_roic_reg_data),
        // TI-ROIC Deserializer signals
        .ti_roic_deser_reset        (ti_roic_deser_reset),
        .ti_roic_deser_dly_tap_ld   (ti_roic_deser_dly_tap_ld),
        .ti_roic_deser_dly_tap_in   (ti_roic_deser_dly_tap_in),
        .ti_roic_deser_dly_data_ce  (ti_roic_deser_dly_data_ce),
        .ti_roic_deser_dly_data_inc (ti_roic_deser_dly_data_inc),
        .ti_roic_deser_align_mode   (ti_roic_deser_align_mode),
        .ti_roic_deser_align_start  (ti_roic_deser_align_start),
        .ti_roic_deser_shift_set    (ti_roic_deser_shift_set),
        .ti_roic_deser_align_shift  (ti_roic_deser_align_shift),
        .ti_roic_deser_align_done   (ti_roic_deser_align_done),
        //
        .ld_io_delay_tab            (LD_IO_DELAY_TAB),
        .io_delay_tab               (IO_DELAY_TAB),
        .sel_roic_reg               (sel_roic_reg),
        .gate_size                  (gate_size),
        .en_16bit_adc               (en_16bit_adc),
        .en_test_pattern_col        (en_test_pattern_col),
        .en_test_pattern_row        (en_test_pattern_row),
        .en_test_roic_col           (en_test_roic_col),        
        .en_test_roic_row           (en_test_roic_row),
        .aed_test_mode1             (aed_test_mode1),
        .aed_test_mode2             (aed_test_mode2),
        .exp_ack                    (EXP_ACK)
    );    

    // always_ff @(posedge s_clk_25mhz or negedge rst) begin
    always_ff @(posedge s_clk_20mhz or negedge rst) begin
        if (~rst) begin
            s_test_cnt <= '0;
        end else begin
            s_test_cnt <= s_test_cnt + 1'b1;
        end
    end

    // assign STATE_LED1 = s_test_cnt[23];

    always_comb begin
        case (s_state_led_ctr)
            8'h00: STATE_LED1 = s_test_cnt[23];
            8'h01: STATE_LED1 = FSM_idle_index;
            8'h02: STATE_LED1 = FSM_read_index;
            8'h03: STATE_LED1 = FSM_exp_index;
            8'h04: STATE_LED1 = FSM_aed_read_index;
            8'h05: STATE_LED1 = FSM_flush_index;
            8'h06: STATE_LED1 = FSM_back_bias_index;
            8'h07: STATE_LED1 = FSM_init_index;
            8'h08: STATE_LED1 = FSM_rst_index;
            8'h09: STATE_LED1 = valid_read_mem;
            8'h10: STATE_LED1 = align_done[0];
            8'h11: STATE_LED1 = align_done[1];
            8'h12: STATE_LED1 = align_done[2];
            8'h13: STATE_LED1 = align_done[3];
            8'h14: STATE_LED1 = align_done[4];
            8'h15: STATE_LED1 = align_done[5];
            8'h16: STATE_LED1 = align_done[6];
            8'h17: STATE_LED1 = align_done[7];
            8'h18: STATE_LED1 = align_done[8];
            8'h19: STATE_LED1 = align_done[9];
            8'h1A: STATE_LED1 = align_done[10];
            8'h1B: STATE_LED1 = align_done[11];
            8'h20: STATE_LED1 = channel_detected[0];
            8'h21: STATE_LED1 = channel_detected[1];
            8'h22: STATE_LED1 = channel_detected[2];
            8'h23: STATE_LED1 = channel_detected[3];
            8'h24: STATE_LED1 = channel_detected[4];
            8'h25: STATE_LED1 = channel_detected[5];
            8'h26: STATE_LED1 = channel_detected[6];
            8'h27: STATE_LED1 = channel_detected[7];
            8'h28: STATE_LED1 = channel_detected[8];
            8'h29: STATE_LED1 = channel_detected[9];
            8'h2A: STATE_LED1 = channel_detected[10];
            8'h2B: STATE_LED1 = channel_detected[11];
            8'h30: STATE_LED1 = s_read_frame_start;
            8'h31: STATE_LED1 = s_read_frame_reset;
            8'h32: STATE_LED1 = s_read_axis_tvalid;
            8'h33: STATE_LED1 = s_read_axis_tlast;
            8'h34: STATE_LED1 = s_read_axis_tready;
            default: STATE_LED1 = 1'b0;
        endcase
    end

endmodule
