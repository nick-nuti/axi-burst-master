
`timescale 1ps / 1ps

module axi_burst_master #(
    parameter ADDR_W=32,
    parameter DATA_W=64,
    parameter WRITE_EN=1,
    parameter READ_EN=1
)
(
  /**************** Write Address Channel Signals ****************/
  output reg [ADDR_W-1:0]              m_axi_awaddr, // address (done)
  output reg [3-1:0]                   m_axi_awprot = 3'b000, // protection - privilege and securit level of transaction
  output reg                           m_axi_awvalid, // (done)
  input  wire                          m_axi_awready, // (done)
  output reg [3-1:0]                   m_axi_awsize = $clog2(DATA_W/8), //3'b011, // burst size - size of each transfer in the burst 3'b011 for 8 bytes
  output reg [2-1:0]                   m_axi_awburst = 2'b01, // fixed burst = 00, incremental = 01, wrapped burst = 10
  output reg [4-1:0]                   m_axi_awcache = 4'b0000, //4'b0011, // cache type - how transaction interacts with caches
  output reg [8-1:0]                   m_axi_awlen, // number of data transfers in the burst (0-255) (done)
  output reg [1-1:0]                   m_axi_awlock = 1'b0, // lock type - indicates if transaction is part of locked sequence
  output reg [4-1:0]                   m_axi_awqos = 4'b0000, // quality of service - transaction indication of priority level
  output reg [4-1:0]                   m_axi_awregion = 4'b0000, // region identifier - identifies targetted region
  /**************** Write Data Channel Signals ****************/
  output reg [DATA_W-1:0]              m_axi_wdata, // (done)
  output reg [DATA_W/8-1:0]            m_axi_wstrb, // (done)
  output reg                           m_axi_wvalid, // set to 1 when data is ready to be transferred (done)
  input  wire                          m_axi_wready, // (done)
  output reg                           m_axi_wlast, // if awlen=0 then set wlast (done)
  /**************** Write Response Channel Signals ****************/
  input  wire [2-1:0]                  m_axi_bresp, // (done) write response - status of the write transaction (00 = okay, 01 = exokay, 10 = slverr, 11 = decerr)
  input  wire                          m_axi_bvalid, // (done) write response valid - 0 = response not valid, 1 = response is valid
  output reg                           m_axi_bready, // (done) write response ready - 0 = not ready, 1 = ready
  /**************** Read Address Channel Signals ****************/
  output reg [ADDR_W-1:0]              m_axi_araddr, // address
  output reg [3-1:0]                   m_axi_arprot = 3'b000, // protection - privilege and securit level of transaction
  output reg                           m_axi_arvalid, // 
  input  wire                          m_axi_arready, // 
  output reg [3-1:0]                   m_axi_arsize = $clog2(DATA_W/8), //3'b011, // burst size - size of each transfer in the burst 3'b011 for 8 bytes
  output reg [2-1:0]                   m_axi_arburst = 2'b01, // fixed burst = 00, incremental = 01, wrapped burst = 10
  output reg [4-1:0]                   m_axi_arcache = 4'b0000, //4'b0011, // cache type - how transaction interacts with caches
  output reg [8-1:0]                   m_axi_arlen, // number of data transfers in the burst (0-255) (done)
  output reg [1-1:0]                   m_axi_arlock = 1'b0, // lock type - indicates if transaction is part of locked sequence
  output reg [4-1:0]                   m_axi_arqos = 4'b0000, // quality of service - transaction indication of priority level
  output reg [4-1:0]                   m_axi_arregion = 4'b0000, // region identifier - identifies targetted region
  /**************** Read Data Channel Signals ****************/
  output reg                           m_axi_rready, // read ready - 0 = not ready, 1 = ready
  input  wire [DATA_W-1:0]             m_axi_rdata, // 
  input  wire                          m_axi_rvalid, // read response valid - 0 = response not valid, 1 = response is valid
  input  wire                          m_axi_rlast, // =1 when on last read
  /**************** Read Response Channel Signals ****************/
  input  wire [2-1:0]                  m_axi_rresp, // read response - status of the read transaction (00 = okay, 01 = exokay, 10 = slverr, 11 = decerr)
  /**************** System Signals ****************/
  input wire                           aclk,
  input wire                           aresetn,
  /**************** User Control Signals ****************/  
  input  wire                          user_start,
  input  wire                          user_w_r, // 0 = write, 1 = read
  input  wire [8-1:0]                  user_burst_len_in,
  input  wire [DATA_W/8-1:0]           user_data_strb,
  input  wire [DATA_W-1:0]             user_data_in,
  input  wire [ADDR_W-1:0]             user_addr_in,
  output wire                          user_free,
  output reg                           user_stall_w_data, // can this be caused by all of these: m_axi_awready, m_axi_awvalid, m_axi_wvalid, m_axi_wready
  //input  wire                          user_stall_r_data,
  output wire [1:0]                    user_status,
  output wire [DATA_W-1:0]             user_data_out,
  output wire                          user_data_out_valid
);
   
// AXI FSM ---------------------------------------------------
    localparam IDLE             = 5'b00001;
    localparam ADDRESS          = 5'b00010;
    localparam WRITE            = (WRITE_EN) ? 5'b00100 : IDLE;
    localparam WRITE_RESPONSE   = (WRITE_EN) ? 5'b01000 : IDLE;
    localparam READ_RESPONSE    = (READ_EN) ? 5'b10000 : IDLE;

    wire start_wire;
       
    reg [5:0] axi_cs, axi_ns;
    reg [7:0] w_data_counter;
   
    always @ (posedge aclk)
    begin
        if(~aresetn)
        begin
            axi_cs <= IDLE;
        end
       
        else
        begin
            axi_cs <= axi_ns;
        end
    end

    always @ (*)
    begin
        case(axi_cs)
        IDLE:
        begin
            if(start_wire)  axi_ns = ADDRESS;
            else            axi_ns = IDLE;
        end
        
        ADDRESS:
        begin
            if(~user_w_r_ff && WRITE_EN) // WRITE
            begin
                if(m_axi_awready)   axi_ns = WRITE;
                else                axi_ns = ADDRESS;
            end

            else if(user_w_r_ff && READ_EN) // READ
            begin
                if(m_axi_arready)  axi_ns = READ_RESPONSE;
                else               axi_ns = ADDRESS;
            end
        end
       
        WRITE:
        begin
            if((w_data_counter == user_burst_len_ff) && m_axi_wready)
            begin
                axi_ns = WRITE_RESPONSE;
            end
           
            else
            begin
                axi_ns = WRITE;
            end
        end
       
        WRITE_RESPONSE:
        begin
            if(m_axi_bvalid)
            begin
                if(start_wire)  axi_ns = ADDRESS;
                else            axi_ns = IDLE;
            end
            else axi_ns = WRITE_RESPONSE;
        end

        READ_RESPONSE:
        begin
            if(m_axi_rlast)// & m_axi_rvalid & m_axi_rready)
            begin
                if(start_wire)  axi_ns = ADDRESS;
                else            axi_ns = IDLE;
            end
           
            else
            begin
                axi_ns = READ_RESPONSE;
            end
        end
       
        default: axi_ns = IDLE;
        endcase
    end

// FLOPPED USER COMMUNICATION ---------------------------------------------------
    reg                         user_w_r_ff;
    reg [8-1:0]                 user_burst_len_ff;
    reg [DATA_W/8-1:0]          user_data_strb_ff;
    reg [DATA_W-1:0]            user_data_in_ff;
    reg [ADDR_W-1:0]            user_addr_in_ff;
    reg                         user_status_ff; //(done)
    reg [DATA_W-1:0]            user_data_out_ff; //(done)
    reg                         user_data_out_valid_ff; //(done)
    
// System for locking-in next operation via flops
    reg                         ready_flag;
    reg                         start_ff;
    wire                        user_next_feed_in;

    assign start_wire = start_ff;

    always @ (posedge aclk)
    begin
        if(~aresetn)
        begin
            ready_flag          <= 1;
            start_ff            <= 0;
            //
            user_w_r_ff             <= 0;
            user_burst_len_ff       <= 0;
            //user_data_strb_ff       <= 0;
            //user_data_in_ff         <= 0;
            user_addr_in_ff         <= 0;
        end
        
        else
        begin
            if(ready_flag & user_start)
            begin
                ready_flag      <= 0;
                start_ff        <= 1;
                //
                user_w_r_ff         <= user_w_r;
                user_burst_len_ff   <= user_burst_len_in;
                user_addr_in_ff     <= user_addr_in;
                
            end
            
            else if(user_next_feed_in & start_ff)
            begin
                ready_flag      <= 1;
                start_ff        <= 0;
            end
            
            /*
            if(WRITE_EN)
            begin
                user_data_strb_ff   <= (~user_w_r) ? user_data_strb : 0;
                user_data_in_ff     <= (~user_w_r) ? user_data_in : 0;
            end
            */
        end
    end
    
    generate
        if(WRITE_EN)
        begin
            always @ (posedge aclk)
            begin
                if(~aresetn)
                begin
                    user_data_strb_ff       <= 0;
                    user_data_in_ff         <= 0;
                end
                
                else
                begin
                    user_data_strb_ff   <= (~user_w_r) ? user_data_strb : 0;
                    user_data_in_ff     <= (~user_w_r) ? user_data_in : 0;
                end
            end
        end
    endgenerate
    
    assign user_next_feed_in   = (((axi_cs == WRITE_RESPONSE) && (m_axi_bvalid)) || ((axi_cs == READ_RESPONSE) && (m_axi_rlast)) || (axi_cs == IDLE)) ? 1 : 0;
    assign user_free           = (((axi_ns == WRITE_RESPONSE) || (axi_ns == READ_RESPONSE) || (axi_ns == IDLE)) && ~start_ff) ? 1 : 0;
// System for locking-in next operation via flops ^^^

// READ data out, data out enable, status out
    always @ (posedge aclk)
    begin
        if(axi_cs == ADDRESS || axi_cs == IDLE)
        begin
            user_data_out_ff        <= 0;
            user_data_out_valid_ff  <= 0;

            user_status_ff          <= 0;
        end
        
        else if(axi_cs == WRITE_RESPONSE && m_axi_bvalid && WRITE_EN)
        begin
            user_data_out_valid_ff  <= 1;
        
            user_status_ff  <= m_axi_bresp;
        end
        
        else if(axi_cs == READ_RESPONSE && m_axi_rvalid && READ_EN)
        begin
            user_data_out_ff        <= m_axi_rdata;
            user_data_out_valid_ff  <= 1;

            user_status_ff          <= m_axi_rresp;
        end
    end

    assign user_status         = user_status_ff;
    assign user_data_out       = user_data_out_ff;
    assign user_data_out_valid = user_data_out_valid_ff;
// READ data out, data out enable, status out ^^^


// AXI WRITE ---------------------------------------------------
    generate
        if(WRITE_EN)
        begin
            always @ (posedge aclk)
            begin
        //
                if(axi_cs == IDLE || axi_cs == WRITE_RESPONSE) w_data_counter <= 'h0;
               
                else if(axi_cs == WRITE && m_axi_wready && w_data_counter < user_burst_len_ff)
                begin
                    w_data_counter <= w_data_counter + 1'b1;
                end
               
                else w_data_counter <= w_data_counter;
        //
            end
            
            always @ (*)
            begin
                m_axi_awvalid <= ((axi_cs==ADDRESS) && (~user_w_r_ff)) ? 1 : 0;
                m_axi_awlen   <= ((axi_cs==ADDRESS) && (~user_w_r_ff)) ? user_burst_len_ff : 0;
                m_axi_awaddr  <= ((axi_cs==ADDRESS) && (~user_w_r_ff)) ? user_addr_in_ff : 0;
                m_axi_wvalid  <= (axi_cs==WRITE) ? 1 : 0;
                m_axi_wdata   <= (axi_cs==WRITE) ? user_data_in_ff : 0;
                m_axi_wstrb   <= (axi_cs==WRITE) ? user_data_strb_ff : 0;
                m_axi_wlast   <= ((axi_cs==WRITE)&&(w_data_counter == user_burst_len_ff)) ? 1'b1 : 1'b0;
                m_axi_bready  <= ((axi_cs == WRITE_RESPONSE)&& m_axi_bvalid) ? 1'b1 : 'h0;
                
                user_stall_w_data <= (m_axi_wready) ? 1'b0 : 1'b1;
            end
        end
    endgenerate    

// AXI READ ---------------------------------------------------
    generate
        if(READ_EN)
        begin
            always @ (*)
            begin
                m_axi_araddr      <= ((axi_cs==ADDRESS) && (user_w_r_ff)) ? user_addr_in_ff : 0;
                m_axi_arlen       <= ((axi_cs==ADDRESS) && (user_w_r_ff)) ? user_burst_len_ff : 0;
                m_axi_arvalid     <= ((axi_cs==ADDRESS) && (user_w_r_ff)) ? 1 : 0;
                m_axi_rready      <= (axi_cs==READ_RESPONSE /*&& ~user_stall_r_data*/) ? 1 : 0;
            end
        end
    endgenerate
    
endmodule
