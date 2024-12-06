# Documentation Guidelines

## Overview
This guide outlines the documentation standards for the AVR-TChan project, using the UART module as a reference implementation.

## Documentation Structure

### 1. Header Files
Each header file should include:

```c
/**
 * @file filename.h
 * @brief Brief description
 *
 * Detailed module description
 * List of features
 * Usage considerations
 *
 * Usage example:
 * @code
 * // Example code
 * @endcode
 *
 * @note Important notes
 * @warning Critical warnings
 *
 * @author Team name
 * @date YYYY/MM/DD
 */
```

### 2. Function Documentation
Document functions using:

```c
/**
 * @brief Short description
 *
 * Detailed description if needed
 *
 * @param param_name Description
 * @return Description of return value
 * @note Additional information
 * @warning Critical considerations
 */
```

### 3. Register Definitions
Document hardware registers with:

```c
/* Register group description */
#define REG_NAME    REG    /* Detailed description */
#define BIT_NAME    BIT    /* Bit function */

/* Control Register Bits */
#define CTRL_BIT    (1<<N) /* Control bit purpose */
```

## Example Implementation

### Header Organization
```c
// 1. File documentation
/**
 * @file uart.h
 * ...
 */

// 2. Include guard
#ifndef __UART_H__
#define __UART_H__

// 3. System includes
#include <stdint.h>

// 4. Project includes
#include "uart_registers.h"

// 5. Definitions and types
#define UART_BUFFER_SIZE 128

// 6. Function prototypes with documentation
/**
 * @brief Initialize UART
 */
int initialize_uart(uint32_t baud);

#endif
```

### Register Documentation
```c
/**
 * UART Register Definitions
 * Primary UART interface for debugging
 */
#define UART_UCSRA     UCSRA /* Control and Status Register A */
#define UART_RXCIE     RXCIE /* RX Complete Interrupt Enable */
```

## Best Practices

1. **Module Documentation**
   - Provide overview and features
   - Include usage examples
   - Document dependencies
   - List hardware requirements

2. **Function Documentation**
   - Clear parameter descriptions
   - Return value explanations
   - Error conditions
   - Usage notes

3. **Register Documentation**
   - Register purpose
   - Bit field descriptions
   - Timing considerations
   - Access restrictions

4. **Code Examples**
   - Practical use cases
   - Complete, working examples
   - Error handling
   - Common patterns

## Reference Implementation
The UART module (`src/RecycleCtrl/uart/`) serves as a reference implementation of these documentation guidelines:

- `uart.h`: Core interface documentation
- `uart_registers.h`: Hardware abstraction
- `uart[1-3].h`: Instance documentation

## Maintenance
- Keep documentation up to date
- Update examples when API changes
- Add new use cases as discovered
- Document known limitations
