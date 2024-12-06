# Event Management Architecture

## Overview
This document describes the event management system architecture for the RecycleCtrl project. The event manager serves as a central hub for handling state changes, component communication, and system events.

## System Components

### Event Manager Core
- Located in `src/core/event/`
- Provides centralized event handling and distribution
- Manages event priorities and queuing
- Handles subscriber registration and notification

### Event Types
```c
typedef enum {
    EVT_PRIORITY_LOW,
    EVT_PRIORITY_MEDIUM,
    EVT_PRIORITY_HIGH,
    EVT_PRIORITY_CRITICAL
} evt_priority_t;

typedef struct {
    uint8_t event_id;
    evt_priority_t priority;
    void* data;
    uint16_t data_size;
} evt_t;
```

## Event Flow
1. Publishers emit events using `evt_publish()`
2. Event Manager processes events based on priority
3. Subscribers receive events through registered callbacks
4. Events are logged for debugging and monitoring

## Integration Points

### State Machine Integration
- State changes trigger events
- Events can cause state transitions
- State machines subscribe to relevant events

### Hardware Integration
- Sensor readings generate events
- Motor control responds to events
- Error conditions raise events

### Communication Integration
- UART messages generate events
- Events trigger outbound communications
- Protocol handlers subscribe to relevant events

## Benefits
1. **Decoupling**: Components communicate through events rather than direct calls
2. **Consistency**: Standardized event handling across the system
3. **Reliability**: Improved error handling and event tracking
4. **Extensibility**: Easy to add new event types and handlers
5. **Debugging**: Centralized event logging and monitoring

## Implementation Guidelines
1. Use event IDs consistently across components
2. Handle event priorities appropriately
3. Clean up event data when processed
4. Log critical events for debugging
5. Maintain event documentation

## Error Handling
1. Queue overflow protection
2. Invalid event detection
3. Subscriber error handling
4. Priority inversion prevention
5. Timeout handling

## Performance Considerations
1. Event queue optimization
2. Memory management for event data
3. Priority-based processing
4. Event coalescing for similar events
5. Subscriber notification optimization
