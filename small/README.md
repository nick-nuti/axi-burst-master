Small AXI Burst master IP design (almost everything is combinational; typically would be driven by other logic; timing @ 100MHz can be tight)

![image](https://github.com/user-attachments/assets/fe8a112b-5d13-476f-b81b-7a4ed7a1b7a7)

![image](https://github.com/user-attachments/assets/48c1e23f-b931-443b-b814-f9b38de25944)

Regarding input parameters:
-----
- NEED 2 ADD THE FOLLOWING PARAMS
- FLOP_READ_DATA : allows the developer to choose whether or not to flop READ data out and READ data out enable
- USER_START_HAS_PULSE_CONTROL : addresses whether or not the hardware driving this IP has synchronous control of "user_start". If this value is 0 then the state machine has a state after WRITE_RESPONSE and READ_RESPONSE to catch and hold the system from progressing further and starting another operation. Deactivation of user_start will allow the state machine to go back to idle. If this input parameter is set to 1 then it's recommended to only pulse "user_start" for one clock cycle.

Hardware size:
---
- LUT: 187 FF: 13

Projects that use similar axi IP:
---
- https://github.com/nick-nuti/AXI-Burst-to-ZYNQ-DDR
- https://github.com/nick-nuti/HDMI_OUT_PYNQ_Z2
