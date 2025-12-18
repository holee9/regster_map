# Work Memory - reg_map Refactoring

## 작업 규칙
- 쓸데없는 설명 금지
- 작업 지시 받기 전까지 대기
- 이 파일 계속 업데이트
- **"기억" 명령 받으면 이 파일 내용 읽고 숙지**

## 현재 상태 (2025-12-18)

### 리팩토링 구조 핵심 원칙
1. **BRAM 중심**: register_memory[512] 단일 배열
2. **2단계 분리**:
   - Write: case에서 register_memory[addr] <= reg_data (line 970)
   - Buffer: 별도 always에서 register_memory → reg_xxx (line 520-680)
3. **심플 구조**: default case가 대부분 처리, Read-Only만 명시
4. **원본 복제 아님**: P&R 가능한 단순 구조

### 발견된 이슈

#### 버퍼링 구조 - 문제 없음
- **Write**: register_memory에만 쓰기 (default case)
- **Buffer**: 별도 always 블록에서 register_memory 읽어서 reg_xxx 업데이트
- **구조**: 2단계 분리, 중복 없음
- **상태**: ✅ 올바른 리팩토링 구조
- reg_read_out, read_data_en, state_led_ctr, reg_map_sel
- system_rst, org_reset_fsm, reset_fsm
- max_v_count, max_h_count, csi2_word_count
- ti_roic_sync, ti_roic_tp_sel, ti_roic_str, ti_roic_reg_addr/data
- ti_roic_deser_* (12 signals)
- up/dn_back_bias
- seq_lut_addr, seq_lut_data, seq_lut_wr_en, seq_lut_control, seq_lut_config_done
- acq_mode, acq_expose_size
- get_dark, get_bright, cmd_get_bright, dummy_get_image, burst_get_image
- en_panel_stable, en_16bit_adc, en_test_pattern_col/row, en_test_roic_col/row
- exp_ack
- gate_* (17 signals)
- dn/up_aed_gate_xao_* (12 signals)

### 미구현 (54 ports) - [x] 표시됨
- en_pwr_dwn, en_pwr_off, en_aed, aed_test_mode1/2
- en_back_bias, en_flush
- aed_th, nega_aed_th, posi_aed_th
- sel_aed_roic, sel_aed_test_roic, num_trigger, ready_aed_read, aed_dark_delay
- cycle_width[23:0], mux_image_height, dsp_image_height, frame_rpt
- readout_count, saturation_flush_repeat
- roic_burst_cycle, start_roic_burst_clk, end_roic_burst_clk
- ld_io_delay_tab, io_delay_tab[4:0]
- up_switch_sync, dn_switch_sync

### 발견된 이슈

#### GATE Control & FSM 도메인 신호 - 최종 심플화 완료
- **1차**: up_set_gate, up_gate_size 펄스 방식 제거
- **2차**: fsm_rst_index 조건 제거
  - reg_op_mode_reg: if (fsm_rst_index) 조건 제거
  - reg_set_gate: if (fsm_rst_index) 조건 제거
  - reg_gate_size: if (fsm_rst_index) 조건 제거
- **3차**: buf_set_gate, buf_gate_size 중간 버퍼 제거
  - 2-stage (eim_clk → fsm_clk) → 1-stage로 축소
- **최종 구조**: fsm_clk에서 register_memory 직접 읽기 (CDC)
  - reg_op_mode_reg, reg_set_gate, reg_gate_size 동일 패턴
  - 44줄 → 18줄로 축소
- **상태**: ✅ 완료

#### p_define.sv 모든 레지스터 정의 확인
- **검증**: p_define.sv의 모든 ADDR_* 정의가 p_define_refacto.sv에 존재
- **방법**: 매크로(DEFREG, DEFGATE_GROUP, DEFROIC_ACLK 등) 사용
- **결과**: 160개 이상 모든 레지스터 주소 정의 완료
- **상태**: ✅ 완료

#### TB 포괄적 검증 - 완료
- **237개 레지스터 Write/Read 테스트**
  - 24개 섹션으로 구분
  - System Control, Timing, GATE, ROIC, TI ROIC, AED 등
  - test_reg_write_read task로 자동 검증
  
- **60+ 출력 신호 토글 테스트 (Section 28)**
  - test_output_toggle task: 2개 값 순차 쓰기 → 신호 변화 확인
  - get_signal_value function: 40개 신호 값 반환
  - GATE Control 비트별 토글 (15개)
  - CSI2, Back Bias, TI ROIC, OP_MODE, SYS_CMD 등
  - GATE GPIO 패턴 테스트 (0x0000→0xFFFF→0x5555→0xAAAA)
  - SEQ LUT, EXPOSE_SIZE 멀티밸류 테스트

- **40+ 입력 신호 Readback 테스트 (Section 29)**
  - test_input_readback task: 입력 설정 → 레지스터 읽기 → 비교
  - test_fsm_state_readback task: FSM 상태 검증
  - ti_roic_deser_align_done: 16개 테스트 (패턴 + 개별 비트)
  - FSM States: 8개 상태 테스트 (RESET~IDLE)
  - FSM Status Bits: 5개 비트 테스트 (ready_to_get, aed_ready, etc)
  - ti_roic_deser_align_shift: 12개 테스트

- **모든 테스트에 PASS/FAIL 판정**
  - 레지스터 write/read 비교
  - 신호 토글 전후 값 비교
  - 입력 신호 readback 비교
  - 통계 요약 (Section 30)

- **상태**: ✅ 완료

## 작업 진행
- 완료:
  - GATE control 3단계 심플화 (44줄→18줄)
  - p_define 160+ 레지스터 검증
  - TB 339+ 테스트 (237 write/read + 60+ toggle + 42 readback)
  - TB reset timing 1us
  - 코드 가독성 개선 (주석 간결화, 포트 선언 정리)
- 대기: 명령 대기 중


