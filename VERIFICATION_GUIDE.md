# Register Map Verification Guide

## 개요
이 가이드는 `reg_map_refacto.sv` (리팩토링 버전)이 `reg_map.sv` (원본)과 동일하게 동작하는지 Vivado에서 파형으로 검증하는 방법을 설명합니다.

---
## ✅ 검증 완료 이력

### TODO 1.1 검증 완료 (2025-12-18)
- **테스트벤치**: `tb_reg_map_verify.sv`
- **검증 방법**: SPI 통신을 통한 레지스터 write/read 및 출력 신호 비교
- **검증 결과**: ✅ PASS - 모든 match 플래그 정상, 원본과 리팩토링 버전 출력 일치
- **주요 이슈 해결**:
  - Reset polarity 불일치 수정 (reg_map: active low, SPI 모듈: active high)
  - SPI read 타이밍 조정 (reg_read_index를 slave_rw_out & spi_active로 연결)
  - 3개 클럭 도메인 설정 (100MHz system, 50MHz SPI Master, 5MHz task timing)
- **검증 신호**: system_rst, reset_fsm, gate_mode, gate_size, csi2_interface
- **파형 파일**: `simulation/tb_reg_map_verify.wdb`

---

## 검증 대상 (TODO 1.1 구현 신호)

### 1. System Control Signals
- `system_rst` - System reset ✅ 검증완료
- `reset_fsm` - FSM reset ✅ 검증완료

### 2. Gate Control Signals  
- `gate_mode1`, `gate_mode2` - Gate operation modes ✅ 검증완료
- `gate_cs1`, `gate_cs2` - Chip select signals ✅ 검증완료
- `gate_sel` - Gate selection ✅ 검증완료
- `gate_ud` - Up/Down control ✅ 검증완료
- `gate_stv_mode` - STV mode ✅ 검증완료
- `gate_oepsn` - OE PSN control ✅ 검증완료
- `gate_lr1`, `gate_lr2` - Left/Right control ✅ 검증완료
- `gate_size[15:0]` - Gate size configuration ✅ 검증완료

### 3. CSI2 Interface Signals
- `max_v_count[15:0]` - Vertical line count ✅ 검증완료
- `max_h_count[15:0]` - Horizontal pixel count ✅ 검증완료
- `csi2_word_count[15:0]` - CSI2 word count ✅ 검증완료

### 4. Register Read Interface
- `reg_read_out[15:0]` - Read data output ✅ 검증완료
- `read_data_en` - Read data enable ✅ 검증완료

## Vivado에서 시뮬레이션 실행하기

### 방법 1: GUI에서 직접 실행
```
1. Vivado 실행
2. Tools > Run Tcl Script... 선택
3. build/run_sim.tcl 실행
4. Simulation > Run Simulation > Run Behavioral Simulation 클릭
```

### 방법 2: 터미널에서 실행 후 GUI 오픈
```powershell
# 프로젝트 루트에서
cd build\reg_map.sim\sim_1\behav\xsim
.\compile.bat
.\elaborate.bat
.\simulate.bat

# 그 다음 Vivado GUI에서:
# File > Open Waveform Configuration
# tb_reg_map_verify_behav.wcfg 선택 (생성된 경우)
```

### 방법 3: 명령어로 바로 GUI 열기
```powershell
cd build\reg_map.sim\sim_1\behav\xsim
xsim tb_reg_map_verify_behav -gui
```

## 파형에서 확인할 포인트

### 핵심 비교 신호들
파형 뷰어에서 다음 신호들을 추가하세요:

```
tb_reg_map_verify/
├── clk                    # 클럭
├── reset                  # 리셋
├── spi_*                  # SPI 통신 신호들
│
├── [Original Outputs]     # 원본 모듈 출력
│   ├── orig_reg_read_out[15:0]
│   ├── orig_read_data_en
│   ├── orig_en_pwr_dwn
│   ├── orig_en_pwr_off
│   ├── orig_system_rst
│   ├── orig_reset_fsm
│   ├── orig_gate_mode1
│   ├── orig_gate_mode2
│   ├── orig_gate_cs1
│   ├── orig_gate_cs2
│   ├── orig_gate_sel
│   ├── orig_gate_ud
│   ├── orig_gate_stv_mode
│   ├── orig_gate_oepsn
│   ├── orig_gate_lr1
│   ├── orig_gate_lr2
│   ├── orig_gate_size[15:0]
│   ├── orig_max_v_count[15:0]
│   ├── orig_max_h_count[15:0]
│   └── orig_csi2_word_count[15:0]
│
├── [Refactored Outputs]   # 리팩토링 모듈 출력
│   ├── refac_reg_read_out[15:0]
│   ├── refac_read_data_en
│   ├── refac_en_pwr_dwn
│   ├── refac_en_pwr_off
│   ├── refac_system_rst
│   ├── refac_reset_fsm
│   ├── refac_gate_mode1
│   ├── refac_gate_mode2
│   ├── refac_gate_cs1
│   ├── refac_gate_cs2
│   ├── refac_gate_sel
│   ├── refac_gate_ud
│   ├── refac_gate_stv_mode
│   ├── refac_gate_oepsn
│   ├── refac_gate_lr1
│   ├── refac_gate_lr2
│   ├── refac_gate_size[15:0]
│   ├── refac_max_v_count[15:0]
│   ├── refac_max_h_count[15:0]
│   └── refac_csi2_word_count[15:0]
│
└── [Comparison Flags]     # 비교 결과 플래그
    ├── match_read_data    # ✓ 읽기 데이터 일치 여부
    ├── match_pwr_dwn      # ✓ Power down 일치 여부
    ├── match_pwr_off      # ✓ Power off 일치 여부
    ├── match_system_rst   # ✓ System reset 일치 여부
    ├── match_reset_fsm    # ✓ FSM reset 일치 여부
    ├── match_gate_mode    # ✓ Gate mode 일치 여부
    ├── match_gate_size    # ✓ Gate size 일치 여부
    ├── match_csi2_interface # ✓ CSI2 interface 일치 여부
    └── all_match          # ✓✓ 전체 일치 여부 (가장 중요!)
```

## 테스트 시퀀스

테스트벤치는 다음 순서로 레지스터 write/read 테스트를 실행합니다:

### TEST 1: SYS_CMD_REG (0x0001) Write & Read
```
동작: Write 0x0001, 그 다음 Read
확인: system_rst 신호 활성화 및 read 데이터 일치
결과: ✅ PASS - orig/refac 출력 동일, read 값 0x0001 확인
```

### TEST 2: OP_MODE_REG (0x0002) Write & Read  
```
동작: Write 0x0010, 그 다음 Read
확인: reset_fsm 신호 활성화 및 read 데이터 일치
결과: ✅ PASS - orig/refac 출력 동일, read 값 0x0010 확인
```

### TEST 3: SET_GATE (0x0003) Write & Read
```
동작: Write 0x0003, 그 다음 Read
확인: gate_mode1/mode2, gate_cs1/cs2 등 gate 신호 변화
결과: ✅ PASS - orig/refac 출력 동일, read 값 0x0003 확인
```

### TEST 4: GATE_SIZE (0x0004) Write & Read
```
동작: Write 0x0004, 그 다음 Read
확인: gate_size[15:0] 값 변화 및 read 데이터 일치
결과: ✅ PASS - orig/refac 출력 동일, read 값 0x0004 확인
```

### TEST 5: MAX_V_COUNT (0x00D0) Write & Read
```
동작: Write 0x001E (30), 그 다음 Read
확인: max_v_count[15:0] 값 변화 및 CSI2 interface 신호
결과: ✅ PASS - orig/refac 출력 동일, read 값 0x001E 확인
```

### 검증 완료 사항
- ✅ SPI 통신 정상 동작 (5MHz SCLK, 200ns period)
- ✅ Write 후 즉시 Read 시 정확한 데이터 반환
- ✅ 모든 레지스터 주소 p_define.sv 매크로 사용
- ✅ Reset polarity 정상 (reg_map: active low, SPI: active high)
- ✅ 3개 클럭 도메인 동작 (100MHz, 50MHz, 5MHz)
- ✅ 원본/리팩토링 모듈 출력 신호 완전 일치

## 검증 Pass 기준

### ✅ 성공 조건 (모두 충족됨)
1. **all_match 신호가 항상 '1'**: ✅ 확인됨 - 전체 시뮬레이션 동안 유지
2. **각 match_* 플래그들이 모두 '1'**: ✅ 확인됨
   - match_system_rst = 1
   - match_reset_fsm = 1  
   - match_gate_mode = 1
   - match_gate_size = 1
   - match_csi2_interface = 1
3. **reg_read_out 값 일치**: ✅ 확인됨 - 모든 read 테스트에서 기대값 반환
4. **모든 출력 신호 타이밍 일치**: ✅ 확인됨 - 동일 클럭 사이클에 변화

### 검증 완료 세부사항
- **콘솔 출력**: 모든 read 값이 예상값과 일치
- **파형 분석**: orig_* 와 refac_* 신호들 완전 동일
- **비교 플래그**: all_match가 시뮬레이션 전체 기간 동안 HIGH 유지
- **Reset 검증**: Active low reset 정상 동작 확인

### 해결된 주요 이슈
1. ✅ Reset polarity 불일치 → 분리된 reset_n/reset 신호 사용
2. ✅ SPI read 타이밍 문제 → reg_read_index를 slave_rw_out & spi_active로 연결
3. ✅ MISO 출력 없음 → read_en 타이밍 조정으로 해결
4. ✅ Read 값 0x0000 반환 → Reset 문제 해결 후 정상 동작

## 파형 저장하기

✅ **검증 완료 파형 저장됨**:
```
파일: simulation/tb_reg_map_verify.wdb
위치: f:\github_work\regster_map\simulation\
용도: TODO 1.1 검증 완료 증거 자료
```

Vivado에서 파형 다시 열기:
```powershell
cd f:\github_work\regster_map\simulation
xsim --gui tb_reg_map_verify.wdb
```

또는 Vivado GUI에서:
```
1. File > Open Waveform Database...
2. simulation/tb_reg_map_verify.wdb 선택
```

추가 파형 저장 방법:
```
1. File > Simulation Waveform > Save Configuration As...
2. 파일명: verification_todo_1_1_pass_YYYYMMDD.wcfg
3. 저장 위치: simulation/waveforms/
```

## 트러블슈팅

### 문제: "module not found" 에러
**해결**: 
```powershell
cd build\reg_map.sim\sim_1\behav\xsim
.\compile.bat
```

### 문제: 파형이 보이지 않음
**해결**: 
- Scope 창에서 tb_reg_map_verify 선택
- Objects 창에서 신호 드래그하여 Wave 창에 추가

### 문제: all_match가 '0'
**해결**:
1. 어느 match_* 플래그가 '0'인지 확인
2. 해당 신호들의 orig_ vs refac_ 값 비교
3. 리팩토링 코드에서 해당 로직 수정 필요

## 다음 단계

### TODO 1.1 검증 완료 ✅
- [x] System control signals (system_rst, reset_fsm)
- [x] Gate control signals (gate_mode, gate_size, gate_cs, etc.)
- [x] CSI2 interface signals (max_v_count, max_h_count, csi2_word_count)
- [x] Register read interface (reg_read_out, read_data_en)
- [x] SPI 통신 검증
- [x] 원본/리팩토링 모듈 출력 일치 확인
- [x] 파형 검증 완료

### TODO 1.2 다음 구현 대상
구현해야 할 신호들:
- Back Bias 관련 신호 (up_back_bias, dn_back_bias)
- Flush 관련 신호 (en_flush 관련)
- AED 관련 신호 (en_aed 관련)
- Panel stable 신호

구현 후 검증 절차:
1. `tb_reg_map_verify.sv`에 해당 신호 비교 로직 추가
2. 테스트 케이스 추가 (해당 레지스터 write/read)
3. Vivado 시뮬레이션 실행
4. 파형으로 orig_* vs refac_* 비교
5. 이 가이드 문서 업데이트

### TODO 1.3 이후 구현 대상
- ROIC Clock 관련 신호들
- TI ROIC Deserializer 관련 신호들
- Sequence LUT 관련 신호들
- 기타 TODO 리스트의 나머지 신호들

---
**검증 방법론**:
1. 각 TODO 단계마다 해당 신호들만 먼저 구현
2. Testbench 업데이트 (비교 신호 추가)
3. 시뮬레이션으로 검증
4. PASS 후 다음 단계 진행
5. 문서 업데이트 및 이력 관리

---
**Note**: 
- TODO 1.1 검증이 완료되어 리팩토링 버전의 기본 동작이 검증되었습니다.
- 다음 단계 구현 시 이 검증 방법을 반복하여 점진적으로 전체 기능을 검증합니다.
- 각 단계의 파형 파일을 저장하여 회귀 테스트에 활용할 수 있습니다.
