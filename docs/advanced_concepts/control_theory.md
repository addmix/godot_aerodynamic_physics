# Control Theory
What are PIDs?

PID is an a acronym representing the control algorithm used, meaning:

- Proportional
- Integral
- Derivative

A PID controller takes in a value, representing the error of a system, and outputs a command that aims to reduce the error.

- Proportional gain gives an output that is directly proportional to the error, though the magnitude of the output is changed by the gain
- Integral tracks how much the error has accumulated over time, and gives an output proportional to that accumulated error.
- Derivative gain gives an output that is proportional to the velocity of the error. This can be thought of as a "damping" force, that opposes movement.