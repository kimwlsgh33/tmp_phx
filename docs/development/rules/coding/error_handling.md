# Error Handling Guidelines

This document outlines the principles and best practices for error handling in the AVR-TChan project.

## Return Type Selection

When designing functions, choose return types based on these principles:

### 1. Functions That Cannot Fail

Functions that cannot fail should either:
- Return `void` if they perform an action but don't produce a value
  ```c
  void init_state_manager(void);
  void clear_error_flags(uint16_t flags);
  ```
- Return their value directly if they produce a value
  ```c
  rc_system_state_t get_current_state(void);
  uint16_t get_error_flags(void);
  const char* get_state_string(rc_system_state_t state);
  ```

### 2. Functions That Can Fail

Functions that can fail should return `error_code_t`:
```c
error_code_t transition_to_state(rc_system_state_t newState);
error_code_t register_state_validator(rc_state_validator_t validator);
```

### 3. Type Conversion Functions

Functions that map between types should return the target type:
```c
error_code_t map_flags_to_error(uint16_t flags);
```

## Error Code Categories

Error codes are organized by component and follow this pattern:
- Common errors: `0x10XX`
- Event manager errors: `0x20XX`
- State manager errors: `0x30XX`

Each component should define its error codes in `error_codes.h`.

## Examples

### Good Practice
```c
// Function that can fail due to invalid state
error_code_t transition_to_state(rc_system_state_t newState) {
    if (newState >= RC_STATE_COUNT) {
        return ERR_STATE_INVALID_STATE;
    }
    // ... perform transition
    return ERR_SUCCESS;
}

// Function that cannot fail - returns void
void clear_error_flags(uint16_t flags) {
    g_stateContext.errorFlags &= ~flags;
}

// Function that returns a value - no error possible
uint16_t get_error_flags(void) {
    return g_stateContext.errorFlags;
}
```

### Bad Practice
```c
// DON'T: Return error code when function cannot fail
error_code_t clear_flags(uint16_t flags) {
    flags = 0;
    return ERR_SUCCESS;  // Unnecessary error code
}

// DON'T: Return boolean for complex error conditions
bool validate_state(state_t state) {
    // Better to return specific error codes
    return state < MAX_STATES;
}
```

## Memory Management

- Cleanup functions (e.g., destructors, free operations) should return `void`
- Memory allocation functions should return NULL or a specific error code if they can fail

## Error Propagation

- Functions should return the most specific error code possible
- Error codes should be propagated up the call stack when they cannot be handled
- Each layer may translate lower-level error codes to more appropriate ones for its context

## Documentation

All functions that return error codes must document:
- All possible error codes they might return
- The conditions under which each error code is returned

Example:
```c
/**
 * @brief Register a state transition validator
 * @param validator Function pointer to validator
 * @return error_code_t Error code indicating success or failure
 *         - ERR_SUCCESS if validator registered successfully
 *         - ERR_STATE_NULL_VALIDATOR if validator is NULL
 *         - ERR_STATE_VALIDATOR_FULL if max validators reached
 */
error_code_t register_state_validator(rc_state_validator_t validator);
```
