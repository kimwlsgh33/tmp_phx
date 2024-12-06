# UART Module Documentation

## Overview
The UART (Universal Asynchronous Receiver-Transmitter) module provides serial communication capabilities for the AVR-TChan project. It supports multiple UART instances with buffered I/O and interrupt-driven operation.

## Features
- Multiple UART instances (UART0-UART3)
- Configurable baud rates from 9600 to 250000
- Interrupt-driven operation
- Circular buffer implementation
- Error handling and overflow protection

## Module Structure

### Core Components
- `uart.h/c`: Common UART definitions and utilities
- `uart_registers.h`: Centralized register definitions
- `uart[1-3].h/c`: Instance-specific implementations

### Buffer Management
- Fixed-size circular buffers (128 bytes)
- Separate RX and TX buffers
- Overflow protection
- Interrupt-safe operation

## API Reference

### Initialization
```c
int initialize_uart(uint32_t baud);
int initialize_uart1(uint32_t baud);
int initialize_uart2(uint32_t baud);
int initialize_uart3(uint32_t baud);
```
Initializes UART with specified baud rate. Returns 0 on success.

### Data Transfer
```c
int read_uart_char(uint8_t *c);
int write_uart_char(uint8_t c);
```
Read/write single characters. Returns 1 on success, 0 on buffer empty/full.

## Error Handling
- Buffer overflow protection
- Frame error detection
- Data overrun detection
- Parity error checking

## Usage Example
```c
#include "uart.h"

void setup_communication(void) {
    // Initialize UART0 at 9600 baud
    initialize_uart(BAUD_9600);
    
    // Send a character
    write_uart_char('A');
    
    // Receive a character
    uint8_t received;
    if (read_uart_char(&received)) {
        // Process received data
    }
}
```

## Configuration
- Buffer sizes defined in each UART instance
- Baud rates defined in uart.h
- Register definitions in uart_registers.h

## Interrupt Handling
- RX Complete (RXC)
- TX Complete (TXC)
- Data Register Empty (UDRE)

## Dependencies
- AVR IO headers
- Port utilities
- F_CPU definition required

## Version History
- 1.2 (2024/01): Improved naming and documentation
- 1.1 (2015/12): Updated interrupt handling
- 1.0 (2015/12): Initial implementation
