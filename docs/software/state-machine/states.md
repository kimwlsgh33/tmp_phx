# System States

## Main System States

### Uninitialized ('u')
- Initial power-up state
- No calibration performed
- Hardware not initialized
- System checks pending

### Initialization ('i')
- System startup sequence
- Hardware initialization
- Sensor calibration
- Position calibration
- System verification

### Ready ('R')
- System ready for operation
- All subsystems initialized
- Waiting for commands
- Monitoring active

### Running ('r')
- Active operation state
- Processing recycling operations
- Monitoring sensors
- Executing movement commands
- System control active

## Error States

### Hardware Errors
- Motor failures
- Sensor failures
- Communication errors
- Hardware faults

### Operational Errors
- Position errors
- Timing errors
- Protocol errors
- System faults

## State Monitoring
- Current state tracking
- Error condition monitoring
- System health checks
- Performance monitoring

For more information:
- [State Overview](overview.md)
- [State Transitions](transitions.md)
- [State Persistence](persistence.md)
