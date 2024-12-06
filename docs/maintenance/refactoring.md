# Code Refactoring Guide

This document provides an overview of refactoring processes in the AVR-TChan project. For detailed information, refer to:
- [Coding Rules](../development/rules/coding_rules.md) - Comprehensive coding standards and guidelines
- [Refactoring Examples](refactoring_examples.md) - Concrete examples of code improvements

## Refactoring Process Overview

1. Create a new branch for refactoring
2. Follow the coding rules for the specific type of change
3. Update documentation to reflect changes
4. Test thoroughly before merging

## Recent Refactoring Activities

### State Machine Variable Naming (2024/12)
- Standardized state machine variable naming in RecycleCtrl
- Added clear prefixes for state (`st_`) and event (`ev_`) variables
- Improved code readability and maintainability
- See [Refactoring Examples](refactoring_examples.md#2-state-machine-variable-naming) for details

### UART Module Refactoring
- Centralized register definitions in `uart_registers.h`
- Improved code formatting and documentation
- Enhanced error handling
- See [Refactoring Examples](refactoring_examples.md#1-uart-module-refactoring) for details

### UART Module Refactoring (2024/12)

### Overview
The UART module underwent significant refactoring to improve code quality, documentation, and maintainability.

### Key Changes

1. **Naming Conventions**
   - Global variables prefixed with `g_`:
     - `_rx_buff` → `g_rxBuffer`
     - `_tx_buff` → `g_txBuffer`

2. **Code Organization**
   - Centralized register definitions in `uart_registers.h`
   - Consistent buffer handling across all UART instances
   - Improved error handling and overflow protection

3. **Documentation Improvements**
   - Added comprehensive module descriptions
   - Detailed function documentation with parameters and return values
   - Clear version history and changelog
   - Added usage examples in header files

4. **Type Safety**
   - Consistent use of `uint8_t` and `uint32_t`
   - Clear parameter types in function declarations
   - Buffer size constraints documented

### Files Affected
- `uart.c` and `uart.h`: Core UART functionality
- `uart1.c`, `uart2.c`, `uart3.c`: Instance-specific implementations
- `uart_registers.h`: Centralized register definitions
- Associated header files

### Testing Considerations
- Verify baud rate calculations
- Test buffer overflow conditions
- Check interrupt handling
- Validate error reporting

### Future Improvements
- Consider adding debug/diagnostic functions
- Implement common error code system
- Add parameter validation in initialization
- Consider buffer size configuration options

### Documentation Improvements (2024/12)

### Overview
Comprehensive documentation update for the UART module following coding rules and best practices.

### Documentation Changes

1. **Header Files**
   - Added comprehensive module descriptions
   - Included practical usage examples
   - Improved function documentation with parameters and return values
   - Added hardware dependency notes
   - Better organized include guards and sections

2. **Register Definitions**
   - Added detailed register map overview in uart_registers.h
   - Improved register and bit field descriptions
   - Added hardware abstraction layer documentation
   - Better organized by UART instance
   - Added clear comments for interrupt control macros

3. **API Documentation**
   - Added usage examples with code snippets
   - Improved error condition documentation
   - Added buffer management notes
   - Included timing considerations
   - Better type safety documentation

### Files Updated
- `uart.h`: Core UART interface documentation
- `uart_registers.h`: Register definitions and hardware layer
- `uart[1-3].h`: Instance-specific interfaces
- `software/uart_module.md`: Technical documentation
- `maintenance/refactoring_examples.md`: Code examples

### Documentation Standards Applied
- Clear and consistent formatting
- Comprehensive module descriptions
- Detailed function documentation
- Practical usage examples
- Hardware dependencies documented
- Error conditions explained
- Type safety emphasized

### Next Steps
- Consider adding API reference documentation
- Add more specific use cases and examples
- Include troubleshooting guides
- Add performance considerations

### Motor Control Module Refactoring (2024/12)

### Overview
The motor control module underwent significant refactoring to standardize naming conventions and improve code maintainability.

### Key Changes

1. **Variable Prefixes**
   - State variables: `st_` prefix (e.g., `st_current`)
   - Position variables: `pos_` prefix (e.g., `pos_target`)
   - Speed variables: `spd_` prefix (e.g., `spd_current`)
   - Flag variables: `flg_` prefix (e.g., `flg_enabled`)
   - Interrupt variables: `int_` prefix (e.g., `int_counter`)
   - Configuration variables: `cfg_` prefix (e.g., `cfg_accel`)

2. **Structure Naming**
   - Added descriptive suffixes (e.g., `SMCtrl`, `MACtrl`)
   - Grouped related fields within structures
   - Added comprehensive field documentation

3. **State Definitions**
   - Standardized state names (e.g., `STATE_IDLE`, `STATE_MOVING`)
   - Added state transition documentation
   - Grouped related states together

### Affected Files
- `stepper_motor_control.h`
- `moving_actuator.h`
- `stepper_motor_timer3.c`

### Benefits
- Improved code readability
- Enhanced maintainability
- Consistent naming across motor control modules
- Better documentation of state transitions
- Clearer structure organization

See [Naming Conventions](../development/guidelines/code/naming_conventions.md) for detailed guidelines.

### File Naming Convention Updates
- Converted to snake_case
- Made names more descriptive
- Removed version numbers from filenames
- See [Refactoring Examples](refactoring_examples.md#2-file-renaming-examples) for details

### Directory Structure Reorganization
The following changes were made to improve code organization by grouping related files into logical subdirectories:

1. Core Directory (`src/RecycleCtrl/core/`):
   - Main application files:
     - `main.c`
     - `recycle_control.{c,h}`
     - `recycle_main.{c,h}`
     - `recycle_control_protocol.{c,h}`
   - Core type definitions:
     - `mcu_types.h`

2. UART Directory (`src/RecycleCtrl/uart/`):
   - Common UART interface:
     - `uart.{c,h}`
   - Hardware-specific UART implementations:
     - `uart1.{c,h}`
     - `uart2.{c,h}`
     - `uart3.{c,h}`

3. Stepper Directory (`src/RecycleCtrl/stepper/`):
   - Common stepper motor interfaces:
     - `stepper_motor1.h`
     - `stepper_motor2.h`
     - `stepper_motor_control.h`
     - `motor_common.h`
   - Timer-specific implementations:
     - `stepper_motor_timer3.c`
     - `stepper_motor_timer4.c`
   - Module-specific implementations:
     - `gd_stepper_motor2.c`
     - `ma_stepper_motor1.c`
     - `garbage_door.h`
     - `moving_actuator.h`

4. Utils Directory (`src/RecycleCtrl/utils/`):
   - Hardware utilities:
     - `port_utils.h`
     - `timer.h`
     - `timer1.c`
   - System utilities:
     - `console.{c,h}`
     - `build_options.h`

Key benefits of this reorganization:
- Improved code organization by grouping related files
- Better separation of concerns between different components
- Clearer dependencies between modules
- Easier navigation of the codebase
- Simplified maintenance and future development

Note: After this reorganization, you may need to update include paths in the build system and source files to reflect the new directory structure.

### Note on Abbreviations
Common abbreviations in the codebase:
- SM/sm: Stepper Motor
- t3/t4: Timer 3/Timer 4 (AVR hardware timers)
- GD: (to be determined) module with stepper motor control
- MA: (to be determined) module with stepper motor control
- RC: Recycle Control

When expanding abbreviations, it's crucial to:
1. Verify the actual meaning within the project context
2. Preserve hardware-specific information (like timer numbers)
3. Preserve module-specific prefixes when present
4. Document the meaning of abbreviations for future reference

### Note on Version Numbers in Filenames
- Version numbers in filenames can lead to confusion and maintenance issues
- Instead of encoding versions in filenames:
  - Use git tags and version control for tracking versions
  - Document version changes in commit messages
  - Keep a changelog if needed
  - Use semantic versioning in the project configuration

### Note on Hardware-Specific Naming
When naming files that control specific hardware components:
1. Use clear numerical indicators (1, 2, 3) for different instances
2. Keep names consistent across related components (timer1.c matches uart1.c pattern)
3. Avoid mixing naming patterns (like _t1 vs 1) for similar components

### Tracking Progress
To keep track of the refactoring progress:

1. Use git status to see renamed files:
```bash
git status
```

2. Review changes before committing:
```bash
git diff --name-status
```

3. Commit changes with descriptive message:
```bash
git commit -m "refactor: rename stepper motor files to follow naming conventions"
```

### Testing After Refactoring
After renaming files:

1. Verify all includes are updated:
```bash
grep -r "SM1\|SM2\|GD_sm2\|MA_sm1" src/RecycleCtrl/
```

2. Check project builds successfully:
```bash
make clean && make
```

3. Run any available tests to ensure functionality is preserved

### Best Practices
- Work in small, related groups of files
- Test compilation after each group is complete
- Document any special cases or dependencies
- Update project documentation to reflect new names
