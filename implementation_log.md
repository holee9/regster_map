# Implementation Log - Reset Signals

## Date: 2025-12-05

## Task: TODO 1.1 - System Control & Reset (Part 1 of 3)

### Objective
Implement 3 reset-related signals from TODO 1.1 in `reg_map_refacto.sv` based on original `reg_map.sv` implementation.

---

## Implemented Signals

### 1. system_rst
- **Type**: Wire (combinational)
- **Source**: Register 0x0001 (SYS_CMD_REG), Bit 4
- **Function**: Global system reset signal
- **Implementation**:
  ```systemverilog
  assign system_rst = reg_sys_cmd_reg[4];
  ```

### 2. org_reset_fsm
- **Type**: Wire (combinational)
- **Source**: Register 0x0001 (SYS_CMD_REG), Bit 0
- **Function**: Original FSM reset signal (direct from register)
- **Implementation**:
  ```systemverilog
  assign org_reset_fsm = reg_sys_cmd_reg[0];
  ```

### 3. reset_fsm
- **Type**: Register (sequential)
- **Source**: Edge-detected from `org_reset_fsm`
- **Function**: FSM reset with edge detection (rising edge sets, falling edge clears)
- **Clock Domain**: fsm_clk (20MHz)
- **Implementation**:
  ```systemverilog
  // Edge detection register
  always @(posedge fsm_clk or negedge rst) begin
      if (!rst) sig_reset_fsm_1d <= 1'b0;
      else sig_reset_fsm_1d <= org_reset_fsm;
  end
  
  // Edge detection logic
  assign hi_reset_fsm = org_reset_fsm && (~sig_reset_fsm_1d);  // Rising edge
  assign lo_reset_fsm = (~org_reset_fsm) && sig_reset_fsm_1d;  // Falling edge
  
  // reset_fsm register
  always @(posedge fsm_clk or negedge rst) begin
      if (!rst) reset_fsm <= 1'b1;
      else begin
          if (lo_reset_fsm)      reset_fsm <= 1'b0;
          else if (hi_reset_fsm) reset_fsm <= 1'b1;
      end
  end
  ```

---

## Architecture Details

### Register Source
- **Register Address**: 0x0001 (SYS_CMD_REG)
- **Register Bits Used**:
  - Bit 0: `org_reset_fsm`
  - Bit 4: `system_rst`

### Internal Signals Added
```systemverilog
logic [15:0] reg_sys_cmd_reg;      // SYS_CMD_REG register
logic        sig_reset_fsm_1d;     // Delayed reset_fsm for edge detection
logic        hi_reset_fsm;         // Rising edge detection
logic        lo_reset_fsm;         // Falling edge detection
```

### Output Ports Added
```systemverilog
output logic system_rst,           // Global system reset
output logic org_reset_fsm,        // Original FSM reset signal
output logic reset_fsm             // Edge-detected FSM reset
```

---

## Verification Status

### Compilation
- ✅ No syntax errors
- ✅ Successfully passed static analysis

### Original Reference
- ✅ Matches original implementation in `reg_map.sv` lines 6669-6710
- ✅ Bit positions verified: bit 0 and bit 4 of SYS_CMD_REG
- ✅ Edge detection logic identical to original
- ✅ Clock domain correctly assigned to fsm_clk (20MHz)
- ✅ Reset behavior matches: `reset_fsm` defaults to 1'b1 on reset

---

## Code Location

### Modified File
`f:\github_work\register_map\source\reg_map_refacto.sv`

### Key Sections Modified
1. **Output Port Declaration** (Lines 89-92)
2. **Internal Signal Declaration** (Lines 123-127)
3. **Signal Assignment Logic** (Lines 155-161)
4. **Edge Detection Logic** (Lines 198-205)
5. **reset_fsm Register Logic** (Lines 207-218)

### Original Reference
`f:\github_work\register_map\source\reg_map.sv` (Lines 6669-6710)

---

## Progress Update

### TODO 1.1 Status
- ✅ **3 of 11 outputs implemented** (27.3% complete)
- ⏳ Remaining 8 outputs:
  - en_pwr_dwn
  - en_pwr_off
  - get_dark
  - get_bright
  - cmd_get_bright
  - dummy_get_image
  - burst_get_image
  - exp_ack

### Phase 1 Overall Progress
- Previous: 5% (Phase 0 complete)
- Current: ~8% (3 of ~37 total Phase 1 outputs)
- Target: 30% (Phase 1 complete)

---

## Implementation Notes

### Design Decisions
1. **Edge Detection**: Used same two-stage approach as original
   - `sig_reset_fsm_1d` stores previous state
   - `hi_reset_fsm` detects 0→1 transition
   - `lo_reset_fsm` detects 1→0 transition

2. **Reset Behavior**: Maintained original reset values
   - `sig_reset_fsm_1d` initializes to 1'b0
   - `reset_fsm` initializes to 1'b1 (active high on reset)

3. **Clock Domain**: All sequential logic on fsm_clk (20MHz)
   - Consistent with original implementation
   - Matches FSM state machine clock domain

### Best Practices Applied
- ✅ Direct reference to original implementation
- ✅ Preserved exact bit positions from register
- ✅ Maintained clock domain separation
- ✅ Added comprehensive comments
- ✅ No syntax errors or warnings

---

## Next Steps

1. Implement remaining 8 outputs from TODO 1.1 (System Control & Reset)
2. Continue with TODO 1.2 (Operation Mode Control - 9 outputs)
3. Progress through TODO 1.3 (GATE Control - 17 outputs)
4. Target completion of Phase 1 (30% milestone)
5. Run comparison testbench to verify new signals

---

## Testing Recommendations

### Unit Testing
- Write directed test for each signal
- Verify bit extraction from SYS_CMD_REG
- Test edge detection timing (rising/falling)
- Confirm reset behavior

### Integration Testing
- Run `tb_reg_map_compare.sv` to verify against original
- Test signal interactions with FSM states
- Verify clock domain crossing (if any downstream modules use these signals)

### Expected Behavior
- Writing 0x0001 to address 0x0001 should activate `org_reset_fsm` and edge-detect to `reset_fsm`
- Writing 0x0010 to address 0x0001 should activate `system_rst`
- Writing 0x0011 to address 0x0001 should activate both signals

---

## References

### Documentation Files
- `vivado_env_rule.md`: Vivado simulation environment setup
- `todo_list.md`: Complete refactoring plan and analysis
- `work_rule.md`: 12 essential rules learned from debugging

### Original Code
- Original module: `source/reg_map.sv` (8096 lines)
- Refactored module: `source/reg_map_refacto.sv` (777 lines)
- Parameter definitions: `source/p_define_refacto.sv`

---

## File Statistics

### Before Implementation
- Total lines: 732
- Output signals: 6 (reg_read_out, read_data_en, state_led_ctr, reg_map_sel, plus 2 internal)

### After Implementation
- Total lines: 777 (+45 lines)
- Output signals: 9 (added system_rst, org_reset_fsm, reset_fsm)
- Internal signals: +4 (reg_sys_cmd_reg, sig_reset_fsm_1d, hi_reset_fsm, lo_reset_fsm)
- Sequential blocks: +2 (edge detection, reset_fsm register)

---

## Conclusion

Successfully implemented the first 3 reset signals from TODO 1.1, establishing the foundation for System Control & Reset functionality. The implementation:
- Matches original behavior exactly
- Uses proper clock domains
- Includes edge detection for precise reset control
- Is ready for integration testing

This represents the first concrete step in Phase 1 refactoring, moving from 5% to ~8% completion.
