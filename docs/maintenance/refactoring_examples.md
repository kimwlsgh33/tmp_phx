# AVR-TChan Refactoring Examples

This document provides concrete examples of code refactoring following our coding rules.

## 1. UART Module Refactoring

### 1.1 Register Definition Improvements
#### Before:
```c
#define UCSRA1 UCSR1A
#define UCSRB1 UCSR1B
#define RXC1   RXC
```

#### After:
```c
/* UART1 Definitions */
#define UART1_UCSRA     UCSR1A
#define UART1_UCSRB     UCSR1B
#define UART1_UCSRC     UCSR1C
#define UART1_RXC       RXC1    /* Receive Complete */
```

### 1.2 Variable Declaration Alignment
#### Before:
```c
static uint8_t rxBuffer[UART_BUFF_SIZE];
static uint8_t rxFront = 0;
static uint8_t rxTail = 0;
static uint8_t rxLength = 0;
```

#### After:
```c
static uint8_t g_rxBuffer[UART_BUFF_SIZE];
static uint8_t g_rxFront  = 0;
static uint8_t g_rxTail   = 0;
static uint8_t g_rxLength = 0;
```

### 1.3 Function Formatting
#### Before:
```c
int uart_init(uint32_t baud) {
UCSR1A=0x02;
UCSR1B=0xD8;
UCSR1C=0x06;
UBRR1H=((F_CPU/8/baud)-1)>>8;
UBRR1L=(F_CPU/8/baud)-1;
return 0;
}
```

#### After:
```c
int initialize_uart(uint32_t baud)
{
  // U2X: Double the USART Transmission Speed
  UART1_UCSRA = (1 << UART1_U2X);    // U2X = 1

  // Enable RX/TX and their interrupts
  UART1_UCSRB = (1 << UART1_RXCIE) | (1 << UART1_TXCIE) | 
                (1 << UART1_RXEN)  | (1 << UART1_TXEN);
    
  // Set frame format: 8 data bits, 1 stop bit, no parity
  UART1_UCSRC = UART_CONFIG_8N1;

  // Set baud rate
  uint16_t ubrr = (F_CPU / 4 / baud - 1) / 2;
  UART1_UBRRH = (uint8_t)(ubrr >> 8);
  UART1_UBRRL = (uint8_t)ubrr;

  return 0;
}
```

### 1.4 UART Refactoring Example

#### Before (Old Style)
```c
// Global variables without prefix
static uint8_t _rx_buff[UART_BUFF_SIZE];
static uint8_t _tx_buff[UART_BUFF_SIZE];

// Function names without verb_noun format
void uart2_init(uint32_t baud) {
    UCSRA = (1 << U2X);  // Direct register access
    // ... rest of initialization
}

// Minimal documentation
int uart2_getchar(uint8_t *c) {
    if (rx_length > 0) {
        *c = _rx_buff[rx_front++];
        return 1;
    }
    return 0;
}
```

#### After (Improved Style)
```c
/**
 * @file uart2.c
 * @brief UART2 Implementation for ATMEGA microcontroller
 */

// Global variables with g_ prefix
static uint8_t g_rxBuffer[UART_BUFF_SIZE];
static uint8_t g_txBuffer[UART_BUFF_SIZE];

// Function names in verb_noun format with documentation
/**
 * Initialize UART2 with specified baud rate
 * @param baud Baud rate (use BAUD_* defines)
 * @return 0 on success, -1 on error
 */
int initialize_uart2(uint32_t baud) {
    UART2_UCSRA = (1 << UART2_U2X);  // Using defined registers
    // ... rest of initialization
}

/**
 * Read a character from the receive buffer
 * @param c Pointer to store received character
 * @return 1 if character read, 0 if buffer empty
 */
int read_uart2_char(uint8_t *c) {
    if (g_rxLength > 0) {
        *c = g_rxBuffer[g_rxFront++];
        return 1;
    }
    return 0;
}
```

#### Key Improvements
1. Added comprehensive file and function documentation
2. Used consistent naming conventions
3. Centralized register definitions
4. Improved error handling
5. Added type safety
6. Better code organization

## 2. File Renaming Examples

### 2.1 Module Files
#### Before:
```
SM1.h
SM2.h
SM1_t3.c
SM2_t4.c
```

#### After:
```
stepper_motor1.h
stepper_motor2.h
stepper_motor_timer3.c
stepper_motor_timer4.c
```

### 2.2 Utility Files
#### Before:
```
putil.h
types.h
```

#### After:
```
port_utils.h
mcu_types.h
```

## 3. Motor Control Module Refactoring

### Before

```c
typedef struct {
    uint8_t state;         // Current state
    uint8_t prevState;     // Previous state
    int32_t targetPos;     // Target position
    int32_t currentPos;    // Current position
    uint16_t targetSpeed;  // Target speed
    uint16_t currentSpeed; // Current speed
    uint8_t accel;        // Acceleration
} StepperMotorCtrl;
```

### After

```c
typedef struct {
    // State management
    uint8_t st_current;    // Current motor state
    uint8_t st_previous;   // Previous motor state
    
    // Position control
    int32_t pos_target;    // Target position
    int32_t pos_current;   // Current position
    
    // Speed control
    uint16_t spd_target;   // Target speed
    uint16_t spd_current;  // Current speed
    
    // Configuration
    uint8_t cfg_accel;     // Acceleration rate
} SMCtrl;
```

### Key Improvements
1. **Consistent Prefixes**: Added standard prefixes (`st_`, `pos_`, `spd_`, `cfg_`) for better code organization
2. **Grouped Fields**: Related fields are grouped together with comments
3. **Concise Structure Name**: Renamed to `SMCtrl` following the new naming convention
4. **Better Documentation**: Added clear comments for each field group

## 4. Error Handling Examples

### 3.1 Buffer Overflow Protection
#### Before:
```c
ISR(USART1_RX_vect) {
  char data = UDR1;
  rxBuffer[rxTail] = data;
  rxTail = (rxTail + 1) % UART_BUFF_SIZE;
  rxLength++;
}
```

#### After:
```c
ISR(UART1_RX_VECT)
{
  uint8_t c       = UART1_UDR;
  uint8_t tmpTail = (g_rxTail + 1) % UART_BUFF_SIZE;

  // Check for buffer overflow
  if (tmpTail != g_rxFront) {
    g_rxBuffer[g_rxTail] = c;
    g_rxTail             = tmpTail;
    g_rxLength++;
  }
}

```

## 5. State Machine Variable Naming (2024/12)

### Context
The state machine variables in `RecycleCtrl` component did not follow the established naming conventions, making it difficult to track state-related variables and their purposes.

### Changes Made
#### Before:
```c
static int state;
static int completed;
static int tid_op;
static RcState st;
static int opcEventUpdated;
static RcOpcEvent opcEvent;
```

#### After:
```c
static int st_currentState;
static int st_completed;
static int tid_operation;
static RcState st_recyclerState;
static int ev_opcEventUpdated;
static RcOpcEvent ev_opcEvent;
```

### Impact
1. Improved code readability by clearly identifying:
   - State variables with `st_` prefix
   - Event variables with `ev_` prefix
   - More descriptive timer IDs
2. Better consistency with naming conventions
3. Easier tracking of state-related variables
4. Reduced potential for state management bugs

### Files Affected
- `/src/RecycleCtrl/core/recycle_control.c`

### Related Rules
See [Naming Conventions](/docs/development/rules/naming/README.md) for complete guidelines.

## 6. State Machine Variable Naming

### Context
State machine variables in the RecycleCtrl project need clear prefixes to distinguish between state variables and event variables.

### Before:
```c
static int state;              // Current state
static int completed;          // Completion flag
static RcState st;            // Recycler state
static int opcEventUpdated;    // Event update flag
static RcOpcEvent opcEvent;    // Operation complete event
```

### After:
```c
static int st_currentState;    // Current state with clear prefix
static int st_completed;       // State completion flag
static RcState st_recyclerState;  // Recycler state structure
static int ev_opcEventUpdated;    // Event update flag
static RcOpcEvent ev_opcEvent;    // Operation complete event
```

### Impact
- Improved code readability by clearly distinguishing state and event variables
- Consistent naming across the codebase
- Easier maintenance and debugging of state machine logic

### Files Affected
- `/src/RecycleCtrl/core/recycle_control.c`

### Related Rules
See [Naming Conventions](/docs/development/rules/naming/README.md) for complete guidelines.

## 7. Variable Naming Standardization

### State Machine Variables

#### Before
```c
static char gd_state = 'C';
static int tid_op = -1;
static int open_position = 280;
```

#### After
```c
static char st_doorState = 'C';
static int tid_doorOperation = -1;
static int st_openPosition = 280;
```

#### Impact Analysis
- Improved code readability by clearly indicating variable types
- Consistent naming across all state machine components
- Better maintainability through clear variable purposes
- No functional changes, only naming improvements

#### Files Affected
- `src/RecycleCtrl/core/recycle_control.c`
- `src/RecycleCtrl/core/recycle_control_protocol.c`
- `src/RecycleCtrl/core/recycle_main.c`
- `src/RecycleCtrl/stepper/garbage_door_motor.c`
