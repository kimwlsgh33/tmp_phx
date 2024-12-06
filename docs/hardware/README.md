# Hardware Documentation

This directory contains documentation about the hardware components and interfaces of the RecycleCtrl system.

## Contents

### Motors
- [Overview](motors/overview.md) - Motor system overview
- [Controllers](motors/controllers.md) - Motor controller implementations
- [Features](motors/features.md) - Motor control features
- [Safety](motors/safety.md) - Motor safety features

### Timers
- [Overview](timers/overview.md) - Timer system overview
- [Implementation](timers/implementation.md) - Timer implementation details
- [Usage](timers/usage.md) - Timer usage and best practices

## Directory Structure
```
hardware/
├── README.md          # This file
├── motors/           # Motor control documentation
│   ├── overview.md    # System overview
│   ├── controllers.md # Controller implementations
│   ├── features.md    # Control features
│   └── safety.md      # Safety features
│
└── timers/           # Timer system documentation
    ├── overview.md    # System overview
    ├── implementation.md # Implementation details
    └── usage.md      # Usage and best practices
```

## Hardware Components Overview

### Motor Control System
The motor control system is responsible for precise movement control in the recycling system. It includes stepper motors, controllers, and safety features. See the [motors documentation](motors/overview.md) for details.

### Timer System
The timer system provides critical timing services for various operations including state machine control, polling intervals, and motion control. See the [timers documentation](timers/overview.md) for details.
