# Naming Conventions

## Overview
This document outlines the naming conventions used throughout the RecycleCtrl project. Consistent naming helps maintain code readability, reduces confusion, and makes the codebase more maintainable.

## File Naming

### Source Files
- Use lowercase with underscores: `recycler_control.c`
- Header files use the same name as their source: `recycler_control.h`
- State machine files append `_sm`: `motor_control_sm.c`
- Test files append `_test`: `motor_control_test.c`

### Documentation Files
- Use lowercase with hyphens: `naming-conventions.md`
- README files are uppercase: `README.md`
- Category-specific files use descriptive names: `safety-guidelines.md`

## Variable Naming

### General Variables
- Use descriptive names that indicate purpose
- Local variables: camelCase
  ```c
  int motorSpeed = 0;
  uint8_t sensorValue = 0;
  ```
- Global variables: prefix with `g_`
  ```c
  uint32_t g_systemTime = 0;
  bool g_isInitialized = false;
  ```

### Timer Variables
- Timer IDs: prefix with `tid_` and use descriptive names
  ```c
  // Operation timers
  uint8_t tid_operation;         // Main operation timer
  uint8_t tid_stateUpdate;       // State update timer
  
  // Component-specific timers
  uint8_t tid_sensorPolling;     // Sensor polling timer
  uint8_t tid_motorControl;      // Motor control timer
  ```
- Timer values: suffix with `_ms` or `_s`
  ```c
  uint32_t timeout_ms = 1000;
  uint16_t delay_s = 5;
  ```

### State Machine Variables
- State variables: prefix with `st_`
  ```c
  // Simple state variables
  uint8_t st_currentState;
  uint8_t st_previousState;
  
  // Complex state structures
  RcState st_recyclerState;    // State structure for recycler
  MotorState st_motorState;    // State structure for motor control
  
  // State flags and counters
  bool st_completed;           // State completion flag
  int st_retryCount;          // State retry counter
  ```

### Motor Control Variables
- Position variables: prefix with `pos_`
  ```c
  int32_t pos_current;      // Current position
  int32_t pos_target;       // Target position
  ```
- Configuration variables: prefix with `cfg_`
  ```c
  int32_t cfg_speed;        // Configured speed
  int32_t cfg_acceleration; // Configured acceleration
  ```

### State Machine Variables

#### State Variables
- Prefix: `st_`
- Examples:
  - `st_currentState`: Current state of a state machine
  - `st_doorState`: Door position state
  - `st_completed`: Completion status
  - `st_opcEvent`: Event from OPC
  - `st_simulationState`: State in simulation mode

#### Timer Variables
- Prefix: `tid_` (Timer ID)
- Examples:
  - `tid_mainLoop`: Main loop timer
  - `tid_doorOperation`: Door operation timer
  - `tid_ledBlink`: LED blinking timer

#### Event Variables
- Prefix: `evt_`
- Examples:
  - `evt_stateChange`: State change event
  - `evt_doorComplete`: Door operation complete event

#### Position/Value Variables
- Use descriptive names without special prefixes
- Examples:
  - `openPosition`: Position when fully open
  - `closePosition`: Position when fully closed
  - `currentSpeed`: Current speed value

### Event Variables
- Event flags: prefix with `ev_`
  ```c
  // Event flags
  uint8_t ev_buttonPress;
  uint8_t ev_sensorTrigger;
  
  // Event structures
  RcOpcEvent ev_opcEvent;        // Operation complete event
  bool ev_opcEventUpdated;       // Event update flag
  ```

### Constants and Defines
- Use uppercase with underscores
  ```c
  #define MAX_MOTOR_SPEED 255
  #define SENSOR_THRESHOLD 1000
  ```
- Enumeration values: prefix with component abbreviation
  ```c
  typedef enum {
      RC_STATE_IDLE,
      RC_STATE_RUNNING,
      RC_STATE_ERROR
  } RecyclerState;
  ```

## Function Naming

### General Functions
- Use verb_noun format to clearly indicate the action and its target
- Start with the module prefix for module-specific functions
- Keep names concise but descriptive

Format: `[module_]verb_noun`

Examples:
```c
// General functions
init_system();          // Initialize system
get_status();          // Get status
set_parameter();       // Set a parameter
update_config();       // Update configuration

// Module-specific functions
timer1_init();         // Initialize timer1
timer1_get_count();    // Get timer count
uart1_write_byte();    // Write byte to UART1
motor_set_speed();     // Set motor speed
```

Common verbs to use:
- `init`: Initialize a component
- `get`: Retrieve a value
- `set`: Modify a value
- `clear`: Reset or clear state
- `update`: Modify state
- `read`: Read from source
- `write`: Write to target
- `enable`: Enable feature
- `disable`: Disable feature
- `start`: Begin operation
- `stop`: End operation
- `alloc`: Allocate resource
- `free`: Release resource

### State Machine Functions
- State handlers: suffix with `_state`
  ```c
  void handle_idle_state(void);
  void process_error_state(void);
  ```
- Event handlers: prefix with `on_`
  ```c
  void on_button_press(void);
  void on_sensor_trigger(void);
  ```

### Timer Functions
- Timer callbacks: suffix with `_timer_cb`
  ```c
  void update_sensor_timer_cb(void);
  void check_status_timer_cb(void);
  ```

### Motor Control Functions
- Use component prefix for all related functions
  ```c
  int ma_init(void);        // Moving Actuator init
  void ma_process(void);    // Moving Actuator process
  int ma_get_position(void); // Moving Actuator position getter
  ```

## Interface Naming
- Interface files: suffix with `_if`
  ```c
  motor_interface.h
  sensor_if.h
  ```
- Interface functions: prefix with component name
  ```c
  motor_set_speed(uint8_t speed);
  sensor_get_reading(uint8_t sensorId);
  ```

## Type Definitions
- Structures: suffix with `_t`
  ```c
  typedef struct {
      uint8_t speed;
      uint8_t direction;
  } motor_config_t;
  ```
- Custom types: use PascalCase
  ```c
  typedef enum {
      SensorTypeAnalog,
      SensorTypeDigital
  } SensorType;
  ```

## Error Codes
- Use uppercase with component prefix
  ```c
  #define MOTOR_ERR_TIMEOUT    0x01
  #define SENSOR_ERR_INVALID   0x02
  #define SYS_ERR_INIT_FAILED  0x03
  ```
- Group related errors in enum
  ```c
  typedef enum {
      ERR_SUCCESS = 0,
      ERR_INVALID_PARAM = -1,
      ERR_NOT_INITIALIZED = -2,
      ERR_TIMEOUT = -3
  } ErrorCode;
  ```

## Configuration Variables
- Configuration constants: prefix with `CFG_`
  ```c
  #define CFG_MAX_SENSORS 8
  #define CFG_TIMEOUT_MS 5000
  ```
- Configuration structures: suffix with `_cfg`
  ```c
  typedef struct {
      uint16_t sample_rate_hz;
      uint8_t filter_level;
  } sensor_cfg_t;
  ```

## Component-Specific Prefixes
- Motor Control (MC_): `MC_init()`, `MC_STATUS_OK`
- Recycler Control (RC_): `RC_process()`, `RC_STATE_IDLE`
- Garbage Door (GD_): `GD_open()`, `GD_POSITION_CLOSED`
- Monitor Actuator (MA_): `MA_move()`, `MA_STATUS_READY`

## Best Practices

### General Guidelines
1. Be consistent with existing code
2. Use meaningful and descriptive names
3. Avoid abbreviations unless widely understood
4. Document any deviations from these conventions
5. Use appropriate prefixes for component isolation
6. Maintain consistent capitalization within each category

### Length Guidelines
- Variable names: 2-32 characters
- Function names: 2-64 characters
- Avoid abbreviations unless widely understood (e.g., `num`, `max`, `min`)
- Keep names meaningful but concise

### Consistency Rules
- Use singular form for single items, plural for collections
  ```c
  sensor_t sensor;           // Single sensor
  sensor_t sensors[MAX_SENSORS];  // Array of sensors
  ```
- Boolean variables should ask a question
  ```c
  bool is_initialized;
  bool has_error;
  bool should_update;
  ```

### Documentation
- All public functions must have descriptive comments
- Use consistent comment style for function documentation
  ```c
  /**
   * @brief   Initialize the motor controller
   * @param   speed Initial speed value (0-255)
   * @return  0 on success, error code otherwise
   */
  int motor_init(uint8_t speed);
  ```

### Namespacing
- Use component prefixes consistently
- Group related functionality under common prefixes
  ```c
  motor_init();
  motor_start();
  motor_stop();
  
  sensor_init();
  sensor_read();
  sensor_calibrate();
  ```

### Control Structure Naming
- Use descriptive suffixes for control structures
  ```c
  typedef struct _ma_ctrl {  // Moving Actuator Control
      int st_motorState;     // State prefixed with st_
      int32_t pos_current;   // Position prefixed with pos_
      int32_t cfg_speed;     // Config prefixed with cfg_
  } MACtrl;
  ```
