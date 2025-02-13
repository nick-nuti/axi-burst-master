Small AXI Burst master IP design (almost everything is combinational; typically would be driven by other logic; timing @ 100MHz can be tight)

![image](https://github.com/user-attachments/assets/21d6c73b-5f46-4407-a125-4bf1cf8ab192)

![image](https://github.com/user-attachments/assets/48c1e23f-b931-443b-b814-f9b38de25944)

Regarding input parameters:
-----
- FLOP_READ_DATA : allows the developer to choose whether or not to flop READ data out and READ data out enable
- USER_START_HAS_PULSE_CONTROL : addresses whether or not the hardware driving this IP has synchronous control of "user_start". If this value is 0 then the state machine has a state after WRITE_RESPONSE and READ_RESPONSE to catch and hold the system from progressing further and starting another operation. Deactivation of user_start will allow the state machine to go back to idle. If this input parameter is set to 1 then it's recommended to only pulse "user_start" for one clock cycle. (you should really set this to 0 if you're having a CPU drive this directly...)

Hardware size:
---
- LUT: 187 FF: 13
- if FLOP_READ_DATA=0 and USER_START_HAS_PULSE_CONTROL=0 then pre-optimization synthesis in vivado shows LUT: 186 and FF: 13
- if FLOP_READ_DATA=0 and USER_START_HAS_PULSE_CONTROL=1 then pre-optimization synthesis in vivado shows LUT: 210 and FF: 12
- if FLOP_READ_DATA=1 and USER_START_HAS_PULSE_CONTROL=0 then pre-optimization synthesis in vivado shows LUT: 117 and FF: 80
- if FLOP_READ_DATA=1 and USER_START_HAS_PULSE_CONTROL=1 then pre-optimization synthesis in vivado shows LUT: 148 and FF: 77

Projects that use similar axi IP:
---
- https://github.com/nick-nuti/AXI-Burst-to-ZYNQ-DDR
- https://github.com/nick-nuti/HDMI_OUT_PYNQ_Z2
