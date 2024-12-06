# AVR-TChan Coding Rules

## 1. File Naming Conventions
- Use lowercase with underscores (snake_case)
- Be descriptive and avoid abbreviations
- Include module prefix where applicable
- Do not include version numbers in filenames

## 2. Code Formatting
### 2.1 Indentation and Spacing
- Use 2 spaces for indentation
- Align related variable declarations
- One blank line between functions
- No trailing whitespace

### 2.2 Variable Naming
- Use descriptive names in snake_case
- Prefix global variables with `g_`
- Use type-specific naming conventions where applicable

### 2.3 Register Definitions
- Centralize register definitions in dedicated header files
- Use consistent naming patterns for registers and bits
- Include descriptive comments for register bits
- Group related registers and definitions together

### 2.4 Header Organization
- Group and order includes logically:
  1. System headers
  2. Library headers
  3. Project headers
- Use include guards
- Minimize header dependencies

## 3. Code Organization
### 3.1 Function Structure
- Single responsibility principle
- Clear error handling
- Consistent return value conventions
- Document non-obvious behavior

### 3.2 Module Organization
- Separate interface from implementation
- Group related functionality
- Use consistent file structure within modules

## 4. Documentation
### 4.1 Code Comments
- Document function purpose and parameters
- Explain complex algorithms
- Keep comments up to date with code
- Use consistent comment style

### 4.2 Header Documentation
- Include brief module description
- Document public interfaces
- Include usage examples where helpful
- List dependencies and requirements

## 5. Error Handling
- Check buffer boundaries
- Validate parameters
- Use consistent error codes
- Document error conditions

## 6. Hardware Access
- Use defined constants for hardware registers
- Abstract hardware access where possible
- Document hardware dependencies
- Include timing considerations
