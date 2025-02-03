Regular AXI Burst master IP design (more-stable than "small" design because ports are flopped; features one-stage pipeline)

![image](https://github.com/user-attachments/assets/105d4a8a-d31b-4cdd-89c7-c938de39227c)

![image](https://github.com/user-attachments/assets/cdc76fdb-4175-40df-b89d-4b85cb6dd578)

Optimization:
---
- Converting FSM to one-hot reduced the FF usage from 194 to 129

Regarding input parameters:
---
- WRITE_EN : only enables the write portion of the AXI Burst master
- READ_EN : only enables the read portion of the AXI Burst master
- NOTE: if both WRITE_EN and READ_EN are 0 then the design will not function

NOTE:
-----
- IP assumes DESIGNER IS HANDLING THE USER_START PULSE!!! This is because this is a pipelined design

Hardware size (out of context synthesis runs without implementation optimizations):
-----
- if WRITE_EN=1 and READ_EN=1 then pre-optimization synthesis in vivado shows LUT: 143 and FF: 129
- if WRITE_EN=1 and READ_EN=0 then pre-optimization synthesis in vivado shows LUT: 178 and FF: 129 (this MUST be optimized)
- if WRITE_EN=0 and READ_EN=1 then pre-optimization synthesis in vivado shows LUT: 28 and FF: 45
