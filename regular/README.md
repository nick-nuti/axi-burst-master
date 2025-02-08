Regular AXI Burst master IP design (more-stable than "small" design because ports are flopped; features one-stage pipeline)

![image](https://github.com/user-attachments/assets/87070ace-ca45-4420-bbac-751830da1108)

![image](https://github.com/user-attachments/assets/cdc76fdb-4175-40df-b89d-4b85cb6dd578)

Regarding input parameters:
---
- WRITE_EN : only enables the write portion of the AXI Burst master
- READ_EN : only enables the read portion of the AXI Burst master
- NOTE: if both WRITE_EN and READ_EN are 0 then the design will not function

NOTE:
-----
- IP assumes DESIGNER IS HANDLING THE USER_START PULSE!!! This is because this is a pipelined design
- Master read stall was taken out due to complexity. Requires two stages of flops to properly handle read data stall (not in my requirements so I took this out)

Hardware size (out of context synthesis runs without implementation optimizations):
-----
- if WRITE_EN=1 and READ_EN=1 then pre-optimization synthesis in vivado shows LUT: 190 and FF: 194
- if WRITE_EN=1 and READ_EN=0 then pre-optimization synthesis in vivado shows LUT: 178 and FF: 129 (this MUST be optimized)
- if WRITE_EN=0 and READ_EN=1 then pre-optimization synthesis in vivado shows LUT: 28 and FF: 45
