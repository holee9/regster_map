# Vivado Simulation Environment Rules

## 작업 날짜: 2025년 12월 5일

## 1. Vivado XSim 환경 설정

### 1.1 기본 정보
- **Vivado 버전**: 2024.2.2
- **설치 경로**: `C:\xilinx\Vivado\2024.2\`
- **실행 파일들**:
  - `xvlog.bat`: SystemVerilog/Verilog 컴파일러
  - `xelab.bat`: Elaboration (시뮬레이션 실행 파일 생성)
  - `xsim.bat`: 시뮬레이션 실행

### 1.2 시뮬레이션 작업 디렉토리 구조
```
register_map/
├── source/           # RTL 소스 코드
│   ├── reg_map.sv
│   ├── reg_map_refacto.sv
│   ├── p_define.sv
│   └── p_define_refacto.sv
├── simulation/       # 테스트벤치 및 시뮬레이션 파일
│   ├── tb_*.sv
│   ├── compile.log
│   ├── elaborate.log
│   ├── simulation_result.log
│   └── xsim.dir/    # 시뮬레이션 빌드 파일 (자동 생성)
└── build/           # Vivado 프로젝트 파일
```

## 2. 컴파일 단계 (Compilation)

### 2.1 기본 컴파일 명령
```powershell
cd f:\github_work\register_map\simulation
C:\xilinx\Vivado\2024.2\bin\xvlog.bat --sv <testbench.sv> <source_files.sv>
```

### 2.2 실전 컴파일 예제
```powershell
C:\xilinx\Vivado\2024.2\bin\xvlog.bat --sv `
    tb_reg_map_compare.sv `
    ..\source\reg_map.sv `
    ..\source\reg_map_refacto.sv `
    ..\source\reg_map_interface.sv `
    ..\source\p_define.sv `
    ..\source\p_define_refacto.sv `
    2>&1 | Tee-Object -FilePath compile.log
```

### 2.3 컴파일 시 주의사항
1. **SystemVerilog 플래그**: `--sv` 반드시 추가
2. **파일 순서**: 의존성 있는 파일 순서 고려 (define 파일 먼저)
3. **경로**: 상대 경로 사용 시 현재 디렉토리 확인
4. **로그 저장**: `2>&1 | Tee-Object -FilePath compile.log`로 로그 저장

### 2.4 컴파일 성공 확인
- 마지막 메시지: `INFO: [VRFC 10-311] analyzing module <module_name>`
- 경고(WARNING)는 무시 가능하지만, 에러(ERROR)는 반드시 해결

## 3. Elaboration 단계

### 3.1 기본 Elaboration 명령
```powershell
C:\xilinx\Vivado\2024.2\bin\xelab.bat -debug typical <top_module_name> -s <snapshot_name>
```

### 3.2 Xilinx Primitive 사용 시 필수 옵션
```powershell
C:\xilinx\Vivado\2024.2\bin\xelab.bat `
    -debug typical `
    tb_reg_map_compare `
    -L unisims_ver `
    -s sim_compare `
    2>&1 | Tee-Object -FilePath elaborate.log
```

### 3.3 Elaboration 필수 규칙
1. **-L unisims_ver**: Xilinx primitive (USR_ACCESSE2, BUFG 등) 사용 시 필수
2. **-debug typical**: 디버깅 정보 포함 (waveform 생성용)
3. **-s <snapshot_name>**: 시뮬레이션 스냅샷 이름 지정
4. **Top module 이름**: 테스트벤치 모듈 이름 정확히 입력

### 3.4 Elaboration 성공 확인
- 마지막 메시지: `Built simulation snapshot <snapshot_name>`
- `xsim.dir/<snapshot_name>/` 디렉토리 생성 확인

### 3.5 자주 발생하는 Elaboration 에러

#### 에러 1: Module not found
```
ERROR: [VRFC 10-2063] Module <USR_ACCESSE2> not found
```
**해결**: `-L unisims_ver` 옵션 추가

#### 에러 2: Multiple concurrent drivers
```
ERROR: [VRFC 10-3823] variable 'signal_name' might have multiple concurrent drivers
```
**해결**: 
- 신호가 여러 `initial` 블록이나 `always` 블록에서 할당되는지 확인
- input/output 방향 확인 (input을 testbench에서 할당, output을 wire로 선언)
- 예: `gate_gpio_data`를 input으로 선언했으나 실제는 output → wire로 변경

## 4. 시뮬레이션 실행 단계

### 4.1 기본 시뮬레이션 명령
```powershell
C:\xilinx\Vivado\2024.2\bin\xsim.bat <snapshot_name> -runall
```

### 4.2 실전 시뮬레이션 예제
```powershell
C:\xilinx\Vivado\2024.2\bin\xsim.bat sim_compare -runall `
    2>&1 | Tee-Object -FilePath simulation_result.log
```

### 4.3 시뮬레이션 옵션
- `-runall`: `$finish` 호출까지 실행
- `-R`: Elaboration 없이 기존 snapshot 재실행
- `-gui`: GUI 모드로 실행 (waveform 확인용)

### 4.4 시뮬레이션 종료 확인
- 정상 종료: `$finish called at time : XXXXX ns`
- 강제 종료: Ctrl+C (비정상)

## 5. 전체 시뮬레이션 플로우

### 5.1 표준 3단계 프로세스
```powershell
# 1단계: 컴파일
cd f:\github_work\register_map\simulation
C:\xilinx\Vivado\2024.2\bin\xvlog.bat --sv `
    tb_reg_map_compare.sv `
    ..\source\reg_map.sv `
    ..\source\reg_map_refacto.sv `
    ..\source\p_define.sv `
    2>&1 | Tee-Object -FilePath compile.log

# 2단계: Elaboration
C:\xilinx\Vivado\2024.2\bin\xelab.bat `
    -debug typical `
    tb_reg_map_compare `
    -L unisims_ver `
    -s sim_compare `
    2>&1 | Tee-Object -FilePath elaborate.log

# 3단계: 시뮬레이션 실행
C:\xilinx\Vivado\2024.2\bin\xsim.bat sim_compare -runall `
    2>&1 | Tee-Object -FilePath simulation_result.log
```

### 5.2 코드 수정 후 재실행
```powershell
# 테스트벤치만 수정한 경우: 1~3단계 모두 재실행
# RTL 코드 수정한 경우: 1~3단계 모두 재실행
# 수정 없이 재실행: 3단계만 실행
C:\xilinx\Vivado\2024.2\bin\xsim.bat sim_compare -R -runall
```

## 6. 테스트벤치 작성 규칙

### 6.1 신호 선언 규칙

#### 입력 신호 (Testbench → DUT)
```systemverilog
// logic 또는 reg 사용
logic         eim_clk;
logic         eim_rst;
reg  [15:0]   reg_data;
```

#### 출력 신호 (DUT → Testbench)
```systemverilog
// wire 사용 (assign 불가)
wire [15:0]   orig_reg_read_out;
wire          orig_read_data_en;
```

#### 양방향 신호
```systemverilog
// inout 사용 또는 별도 제어 로직 필요
```

### 6.2 Multiple Driver 방지
```systemverilog
// 잘못된 예: input을 initial에서 할당
logic [15:0] gate_gpio_data;  // 모듈의 output인데 logic로 선언
initial begin
    gate_gpio_data = 16'h0000;  // ERROR: multiple drivers
end

// 올바른 예: output은 wire로 선언
wire [15:0] gate_gpio_data;  // 모듈의 output을 wire로 선언
// 할당 불가 (모듈에서 drive)
```

### 6.3 클럭 생성
```systemverilog
// 파라미터로 주기 정의
parameter EIM_CLK_PERIOD = 10;  // 10ns = 100MHz
parameter FSM_CLK_PERIOD = 50;  // 50ns = 20MHz

// 클럭 생성
initial begin
    eim_clk = 0;
    forever #(EIM_CLK_PERIOD/2) eim_clk = ~eim_clk;
end
```

### 6.4 리셋 시퀀스
```systemverilog
task reset_dut();
    begin
        eim_rst = 1;
        rst = 1;
        @(posedge eim_clk);
        @(posedge eim_clk);
        eim_rst = 0;
        rst = 0;
        @(posedge eim_clk);
    end
endtask
```

## 7. 디버깅 팁

### 7.1 로그 파일 분석
```powershell
# 에러만 확인
Select-String -Path compile.log -Pattern "ERROR"

# 경고 확인
Select-String -Path elaborate.log -Pattern "WARNING"

# 특정 신호 추적
Select-String -Path simulation_result.log -Pattern "MISMATCH"
```

### 7.2 시뮬레이션 결과 분석
```powershell
# 통과/실패 통계
Select-String -Path simulation_result.log -Pattern "Pass Rate"

# 특정 테스트 결과 확인
Select-String -Path simulation_result.log -Pattern "Test #50"
```

### 7.3 Common Issues 체크리스트
- [ ] `--sv` 플래그 포함?
- [ ] `-L unisims_ver` 추가? (Xilinx primitive 사용 시)
- [ ] 신호 방향 (input/output) 정확?
- [ ] Multiple driver 없음?
- [ ] 클럭 주기 올바름?
- [ ] 리셋 시퀀스 정상?
- [ ] 파일 경로 올바름?

## 8. 성능 최적화

### 8.1 컴파일 시간 단축
- 변경되지 않은 파일은 재컴파일 불필요 (Vivado가 자동 처리)
- 큰 디자인의 경우 incremental compilation 활용

### 8.2 시뮬레이션 속도 향상
- 불필요한 `$display` 최소화
- Waveform 덤프 최소화 (`-debug typical` 대신 `-debug off`)
- 시뮬레이션 시간 제한 설정

### 8.3 로그 파일 관리
```powershell
# 오래된 로그 삭제
Remove-Item *.log -Force

# xsim.dir 캐시 정리 (문제 발생 시)
Remove-Item -Recurse -Force xsim.dir/
```

## 9. 치명적 실수 방지 체크리스트

### 9.0 ⚠️ CRITICAL: 자동화 도구 실행 시 필수 규칙

**교훈**: 2회 연속 동일한 실수 발생 - 토큰 낭비 방지 필수!

**실수 사례 1: 중복 디렉토리 변경**
```powershell
# 잘못된 명령 (이미 simulation 디렉토리에 있는데 또 cd 시도)
cd simulation; xvlog --sv ...

# 오류 메시지
cd : 'F:\github_work\register_map\simulation\simulation' 경로는 존재하지 않음
```

**실수 사례 2: Vivado PATH 미설정**
```powershell
# 잘못된 명령 (PATH 설정 없이 바로 xvlog 실행)
xvlog --sv ...

# 오류 메시지
xvlog : 'xvlog' 용어가 cmdlet, 함수, 스크립트 파일 또는 실행할 수 있는 프로그램 이름으로 인식되지 않습니다
```

**필수 실행 규칙**:
1. **현재 디렉토리 확인 먼저**
   ```powershell
   # 현재 위치 확인
   Get-Location
   # 출력: F:\github_work\register_map\simulation
   ```

2. **Vivado PATH 설정 필수**
   ```powershell
   # 모든 시뮬레이션 명령 전에 PATH 설정
   $env:PATH += ";C:\Xilinx\Vivado\2024.2\bin"
   ```

3. **한 줄 명령어 형식 (권장)**
   ```powershell
   # PATH 설정 + 명령어 실행을 한 줄로
   $env:PATH += ";C:\Xilinx\Vivado\2024.2\bin"; xvlog --sv <files>; xelab <options>; xsim <snapshot>
   ```

4. **출력 제한 필수 (토큰 효율성)**
   ```powershell
   # 컴파일/Elaboration: 마지막 3줄만
   xvlog ... 2>&1 | Select-Object -Last 3
   xelab ... 2>&1 | Select-Object -Last 3
   
   # 시뮬레이션: 마지막 50줄만
   xsim ... 2>&1 | Select-Object -Last 50
   ```

**체크리스트 (명령 실행 전 필독)**:
- [ ] 현재 디렉토리가 `F:\github_work\register_map\simulation`인가?
- [ ] PATH에 `C:\Xilinx\Vivado\2024.2\bin` 추가했는가?
- [ ] `Select-Object -Last N`으로 출력 제한했는가?
- [ ] 불필요한 `cd` 명령이 없는가?
- [ ] 이전 실패 명령을 그대로 반복하지 않는가?

### 9.1 컴파일 전
- [ ] 작업 디렉토리가 `simulation/`인가? (Get-Location으로 확인)
- [ ] Vivado PATH가 설정되어 있는가? (`$env:PATH` 확인)
- [ ] 모든 소스 파일 경로가 올바른가?
- [ ] SystemVerilog 파일에 `--sv` 플래그 있는가?

### 9.2 Elaboration 전
- [ ] 컴파일이 성공했는가?
- [ ] Top module 이름이 정확한가?
- [ ] Xilinx primitive 사용 시 `-L unisims_ver` 있는가?

### 9.3 시뮬레이션 전
- [ ] Elaboration이 성공했는가?
- [ ] Snapshot 이름이 올바른가?
- [ ] 로그 파일 경로가 올바른가?

### 9.4 결과 분석 전
- [ ] `$finish` 호출로 정상 종료했는가?
- [ ] 로그 파일이 생성되었는가?
- [ ] 예상한 테스트 개수가 실행되었는가?

## 10. 자주 사용하는 PowerShell 명령

### 10.1 로그 분석
```powershell
# 마지막 N줄 보기
Get-Content simulation_result.log -Tail 50

# 패턴 검색 및 개수 세기
(Select-String -Path simulation_result.log -Pattern "PASS").Count

# 여러 패턴 동시 검색
Select-String -Path simulation_result.log -Pattern "PASS|FAIL|MISMATCH"
```

### 10.2 파일 관리
```powershell
# 로그 파일 백업
Copy-Item simulation_result.log simulation_result_$(Get-Date -Format 'yyyyMMdd_HHmmss').log

# 빌드 아티팩트 정리
Remove-Item -Recurse -Force xsim.dir/, xsim.log, *.jou, *.pb
```

## 11. 요약: 필수 암기 사항

### 11.1 자동화 도구용 한 줄 명령어 (토큰 효율성 최대화)

**⚠️  이 명령을 매번 그대로 사용 (변형 금지)**:
```powershell
# 현재 위치가 F:\github_work\register_map\simulation일 때
$env:PATH += ";C:\Xilinx\Vivado\2024.2\bin"; xvlog --sv ..\source\p_define_refacto.sv ..\source\reg_map_interface.sv ..\source\reg_map.sv ..\source\reg_map_refacto.sv .\tb_reg_map_compare.sv 2>&1 | Select-Object -Last 3; xelab -L unisims_ver -top tb_reg_map_compare -snapshot tb_reg_map_compare_snap 2>&1 | Select-Object -Last 3; xsim tb_reg_map_compare_snap -R 2>&1 | Select-Object -Last 50
```

**핵심 포인트**:
- PATH 설정 포함
- 컴파일/Elaboration: Last 3
- 시뮬레이션: Last 50
- 세미콜론(;)으로 체인
- **절대 변형하지 말 것!**

### 11.2 3단계 명령어 (수동 실행 시)
```powershell
# PATH 설정 먼저
$env:PATH += ";C:\Xilinx\Vivado\2024.2\bin"

# 1. Compile
xvlog.bat --sv testbench.sv sources.sv 2>&1 | Select-Object -Last 3

# 2. Elaborate
xelab.bat -debug typical top_module -L unisims_ver -s snapshot_name 2>&1 | Select-Object -Last 3

# 3. Simulate
xsim.bat snapshot_name -runall 2>&1 | Select-Object -Last 50
```

### 11.3 신호 선언 규칙
- **Input → DUT**: `logic` 또는 `reg`
- **Output ← DUT**: `wire`
- **한 신호는 한 곳에서만 할당**

### 11.4 에러 발생 시 확인 순서
1. **현재 디렉토리 확인** (`Get-Location`)
2. **PATH 설정 확인** (`$env:PATH | Select-String Vivado`)
3. 컴파일 로그 확인 (`compile.log`)
4. Elaboration 로그 확인 (`elaborate.log`)
5. 신호 방향 및 multiple driver 확인
6. Xilinx primitive 사용 시 `-L unisims_ver` 확인
7. 파일 경로 및 이름 확인

### 11.5 절대 금지 사항
- ❌ 이미 simulation 디렉토리에서 `cd simulation` 실행
- ❌ PATH 설정 없이 xvlog/xelab/xsim 실행
- ❌ Select-Object 없이 전체 출력
- ❌ 실패한 명령을 수정 없이 재실행
- ❌ 실험적 Vivado 프로젝트 명령 시도

---

**작성자**: GitHub Copilot  
**최초 작성**: 2025년 12월 5일  
**최종 업데이트**: 2025년 12월 5일 (Section 9.0 추가)  
**버전**: 1.1  
**적용 프로젝트**: register_map refactoring  
**중요 교훈**: 2회 연속 동일 실수 - 자동화 도구는 규칙 준수 필수!
