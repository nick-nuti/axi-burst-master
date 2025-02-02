Regular AXI Burst master IP design (more-stable than "small" design because ports are flopped; features one-stage pipeline)

![image](https://github.com/user-attachments/assets/105d4a8a-d31b-4cdd-89c7-c938de39227c)

![image](https://github.com/user-attachments/assets/cdc76fdb-4175-40df-b89d-4b85cb6dd578)

NOTE:
-----
- IP assumes DESIGNER IS HANDLING THE USER_START PULSE!!! This is because this is a pipelined design

Hardware size:
-----
(NOTE: sizes are with 64 bit data size and 32 bit address size)
- LUT: 150 FF: 194
