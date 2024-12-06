# Timer System Implementation

## Hardware Configuration
- Uses Timer1 on AVR microcontroller (ATmega)
- Base interval: 1ms (1000 ticks per second)
- Clock configuration: System clock/256 prescaler
- Mode: CTC (Clear Timer on Compare match)
- Maximum timers: 16 system timers

## Timer Structure
```c
typedef struct _sys_timer {
    uint8 flag;    // bit7: allocated, bit0: running flag
    uint32 value;  // timer value in milliseconds
} sys_timer;
```

## Core Timer Functions

### Initialization
```c
void timer_init()
```
- Initializes Timer1 hardware and timer utilities
- Sets up CTC mode
- Configures 1ms intervals
- Enables Output Compare Interrupt A

### Timer Management Functions
```c
int timer_alloc()      // Allocates a timer slot
int timer_free()       // Releases a timer slot
int timer_set()        // Sets timer value in milliseconds
int timer_get()        // Gets remaining time
int timer_clear()      // Clears a running timer
timer_isfired()        // Checks if timer has expired
```

## Timer Interrupt Handler

The system uses a timer interrupt service routine (ISR) that:
- Increments global timer count
- Decrements active timer values
- Handles automatic timer expiration

```c
ISR(TIMER1_COMPA_vect)
{
    timerCount++;
    // Decrease active timer values
    for (i = 0; i < MAX_SYS_TIMER; i++) {
        if (timer_list[i].value > 0) {
            timer_list[i].value--;
        }
    }
}
```
