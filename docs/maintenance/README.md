# Maintenance Documentation

This directory contains documentation about system maintenance procedures for the RecycleCtrl system.

## Contents

- [Troubleshooting](troubleshooting.md) - Troubleshooting guide
- [Calibration](calibration.md) - Calibration procedures
- [Updates](updates.md) - System update procedures
- [Recent Maintenance Activities](#recent-maintenance-activities) - Recent maintenance activities

## Directory Structure
```
maintenance/
├── README.md          # This file
├── troubleshooting.md # Troubleshooting
├── calibration.md     # Calibration
├── updates.md         # Updates
└── refactoring_examples.md # Refactoring examples
```

## Recent Maintenance Activities

### 2024 - Naming Convention Standardization
- **Scope**: State machine variables, timer IDs, and event variables across RecycleCtrl
- **Files Affected**:
  - `src/RecycleCtrl/core/recycle_control.c`
  - `src/RecycleCtrl/core/recycle_control_protocol.c`
  - `src/RecycleCtrl/core/recycle_main.c`
  - `src/RecycleCtrl/stepper/garbage_door_motor.c`
- **Changes**:
  - Standardized state variables with `st_` prefix
  - Standardized timer IDs with `tid_` prefix
  - Standardized event variables with `evt_` prefix
  - Updated position/value variables to use descriptive names
- **Documentation**:
  - Updated naming conventions in `docs/development/rules/naming/README.md`
  - Added refactoring examples in `docs/maintenance/refactoring_examples.md`
