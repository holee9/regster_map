# Register Map Simulation Guide

## 프로젝트 개요
- **목적**: 원본 reg_map.sv와 리팩토링된 reg_map_refacto.sv 비교 테스트
- **테스트벤치**: tb_reg_map_compare.sv
- **시뮬레이터**: Vivado XSim 2024.2

## 시뮬레이션 실행 방법

### 방법 1: PowerShell 스크립트 (권장)
```powershell
cd f:\github_work\register_map
.\run_simulation.ps1
```

### 방법 2: Batch 파일
```cmd
cd f:\github_work\register_map
run_simulation.bat
```

### 방법 3: 수동 실행
```powershell
# 1. Vivado 경로 설정
$env:PATH = "C:\xilinx\Vivado\2024.2\bin;" + $env:PATH

# 2. 작업 디렉토리로 이동
cd f:\github_work\register_map\build\reg_map.sim\sim_1\behav\xsim

# 3. 이전 시뮬레이션 정리 (선택사항)
Remove-Item -Recurse -Force xsim.dir -ErrorAction SilentlyContinue

# 4. 컴파일
.\compile.bat

# 5. Elaboration
.\elaborate.bat

# 6. 시뮬레이션 실행
xsim tb_reg_map_compare_behav -runall | Tee-Object -FilePath simulation_result.log
```

## 출력 파일
시뮬레이션 결과는 다음 위치에 저장됩니다:
```
f:\github_work\register_map\build\reg_map.sim\sim_1\behav\xsim\simulation_result.log
```

## 결과 해석

### 정상 동작 지표
- **Total Tests**: 294개 (고정값)
- **Pass Rate**: 높을수록 좋음 (목표: 95%+)
- **Data Mismatches**: 낮을수록 좋음 (목표: 0개)

### 현재 상태 (2025-12-05)
```
Total Tests     : 294
Passed          : 23
Failed          : 271
Data Matches    : 11
Data Mismatches : 281
Pass Rate       : 7%
```

**문제**: 원본 reg_map.sv가 모든 레지스터 읽기에서 0x0000 반환
- Refactored 모듈은 정상 작동 (모든 값 정확히 반환)
- 원본 모듈의 레지스터 읽기 로직 전체가 비활성화된 상태

## 시뮬레이션 단계별 설명

### 1. Compilation (compile.bat)
- **역할**: SystemVerilog 소스 파일을 xvlog로 컴파일
- **입력 파일**:
  - `source/p_define.sv`
  - `source/p_define_refacto.sv`
  - `source/reg_map.sv` (원본 모듈)
  - `source/reg_map_refacto.sv` (리팩토링 모듈)
  - `simulation/tb_reg_map_compare.sv` (테스트벤치)
- **출력**: xsim.dir/work 라이브러리

### 2. Elaboration (elaborate.bat)
- **역할**: 컴파일된 모듈을 링크하고 시뮬레이션 실행 파일 생성
- **출력**: xsim.dir/tb_reg_map_compare_behav 스냅샷

### 3. Simulation (xsim)
- **역할**: 테스트벤치 실행 및 결과 출력
- **동작**:
  - 294개 테스트 케이스 자동 실행
  - 원본/리팩토링 모듈 출력 비교
  - 일치/불일치 로그 생성

## 트러블슈팅

### 문제 1: "xvlog is not recognized"
**원인**: Vivado 경로가 PATH에 없음
**해결**:
```powershell
$env:PATH = "C:\xilinx\Vivado\2024.2\bin;" + $env:PATH
```

### 문제 2: "Could not open file xsim.dir for writing"
**원인**: 이전 시뮬레이션이 완전히 종료되지 않음
**해결**:
```powershell
Get-Process -Name "xsim*" | Stop-Process -Force
Remove-Item -Recurse -Force xsim.dir
```

### 문제 3: "Cannot find design unit"
**원인**: 컴파일 실패 또는 xsim.dir 손상
**해결**:
```powershell
Remove-Item -Recurse -Force xsim.dir
.\compile.bat
.\elaborate.bat
```

## Vivado 버전별 경로

### Vivado 2024.2 (현재 사용 중)
```
C:\xilinx\Vivado\2024.2\bin
```

### Vivado 2023.1
```
C:\xilinx\Vivado\2023.1\bin
```

### 다른 버전 확인
```powershell
Get-ChildItem C:\xilinx\Vivado -Directory | Select-Object Name
```

## 파일 구조
```
register_map/
├── run_simulation.bat           # Batch 실행 스크립트
├── run_simulation.ps1           # PowerShell 실행 스크립트 (권장)
├── README_SIMULATION.md         # 이 파일
├── source/
│   ├── p_define.sv
│   ├── p_define_refacto.sv
│   ├── reg_map.sv              # 원본 모듈 (문제 발생 중)
│   ├── reg_map_refacto.sv      # 리팩토링 모듈 (정상 동작)
│   └── reg_map_interface.sv
├── simulation/
│   └── tb_reg_map_compare.sv   # 비교 테스트벤치
└── build/
    └── reg_map.sim/
        └── sim_1/
            └── behav/
                └── xsim/
                    ├── compile.bat
                    ├── elaborate.bat
                    └── simulation_result.log  # 결과 파일
```

## 다음 단계

### 우선순위 1: 원본 모듈 수정
원본 `reg_map.sv`의 레지스터 읽기 로직을 수정하여 정상 동작하도록 해야 합니다.

### 우선순위 2: 테스트 확장
리팩토링 모듈에 Phase 1 기능 추가 후 테스트 추가

### 우선순위 3: 자동화
CI/CD 파이프라인에 시뮬레이션 자동 실행 추가

## 참고사항
- 시뮬레이션 시간: 약 40,505ns (40.5μs)
- 테스트 커버리지: Phase 0 기능 (5%)
- 매크로 기반 자동화: 150+ 레지스터 테스트
