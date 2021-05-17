// Copyright 2011-2018 Frederic Requin
//
// This file is part of the MCC216 project
//
// The J68 core:
// -------------
// Simple re-implementation of the MC68000 CPU
// The core has the following characteristics:
//  - Tested on a Cyclone III (90 MHz) and a Stratix II (180 MHz)
//  - from 1500 (~70 MHz) to 1900 LEs (~90 MHz) on Cyclone III
//  - 2048 x 20-bit microcode ROM
//  - 256 x 28-bit decode ROM
//  - 2 x block RAM for the data and instruction stacks
//  - stack based CPU with forth-like microcode
//  - not cycle-exact : needs a frequency ~3 x higher
//  - all 68000 instructions are implemented
//  - almost all 68000 exceptions are implemented (only bus error missing)
//  - only auto-vector interrupts supported

`default_nettype none
module soc_j68
(
    input           clk50M, // rst_in, clk_ena,
	// SDCARD
	output 		SD_CS,		// CS
	output 		SD_SCK,		// SCLK
	output 		SD_CMD,		// MOSI
	input  		SD_DAT0,		// MISO
	 // SDRAM
	inout wire [15:0]     SDRAM_DATA, // SDRAM Data bus 16 Bits
	output wire [12:0]    SDRAM_ADDR, // SDRAM Address bus 13 Bits
	output wire           SDRAM_DQML, // SDRAM Low-byte Data Mask
	output wire           SDRAM_DQMH, // SDRAM High-byte Data Mask
	output wire           SDRAM_nWE,  // SDRAM Write Enable
	output wire           SDRAM_nCAS, // SDRAM Column Address Strobe
	output wire           SDRAM_nRAS, // SDRAM Row Address Strobe
	output wire           SDRAM_nCS,  // SDRAM Chip Select
	output wire [1:0]     SDRAM_BA,   // SDRAM Bank Address
	output wire           SDRAM_CLK,  // SDRAM Clock
	output wire           SDRAM_CKE,  // SDRAM Clock Enable
    // UART #0 (Load port)
    input           uart0_rxd, // uart0_cts_n, uart0_dcd_n,
    output          uart0_txd, uart0_rts_n,
    // UART #1 (Terminal)
    input           uart1_rxd, // uart1_cts_n, uart1_dcd_n,
    output          uart1_txd, uart1_rts_n,
	 //
	 input  [2:0] BTN,
    output [7:0]	LED,
    output [3:0] DIG
);

    wire rst         = !locked | resflg;
    wire clk_ena     = 1;
    wire uart0_cts_n = 0;
	 wire uart0_dcd_n = 0;
    wire uart1_cts_n = 0;
	 wire uart1_dcd_n = 0;
    
    parameter VECT_0 = 32'h0000413C; // Initial SSP (for debug)
    parameter VECT_1 = 32'h0000011C; // Initial PC (for debug)

    // Peripherals
    reg   [9:0] r_eclk;
    reg         r_ser_clk;
    reg   [5:0] r_ser_ctr;
    wire        w_uart0_txd;
    reg   [2:0] r_uart0_txd;
    reg   [2:0] r_uart0_rxd;
    wire        w_uart1_txd;
    reg   [2:0] r_uart1_txd;
    reg   [2:0] r_uart1_rxd;
    
    // Read/write controls
    reg         r_rden_dly;
    wire        w_cpu_rden;
    wire        w_cpu_wren;
    wire        w_cpu_rw_n;
    wire        w_cpu_dtack;
    
    // Address bus
    wire  [1:0] w_cpu_bena;
    wire [31:0] w_cpu_addr;
    wire        w_cpu_vpa;
    
    // Data bus
    wire [15:0] w_cpu_wdata;
    wire [15:0] w_cpu_rdata;
    wire [15:0] w_q_rom;
    wire [15:0] w_q_ram;
    wire [15:0] w_q_bram;
    wire [15:0] w_q_scram;
    wire [15:0] w_q_dram;
    reg   [7:0] r_q_acia;
    wire  [7:0] w_aciaa_data_out;
    wire        w_aciaa_data_en;
    wire  [7:0] w_aciab_data_out;
    wire        w_aciab_data_en;
    
    // Interrupts
    wire  [2:0] w_cpu_fc;
    reg   [2:0] r_cpu_ipl_n;
    wire        w_irq_1_n;
    wire        w_irq_2_n;
    wire        w_irq_3_n;
    
    // Debug
    reg  [31:0] r_dbg_regs[15:0];
    wire  [3:0] w_dbg_reg_addr;
    wire  [3:0] w_dbg_reg_wren;
    wire [15:0] w_dbg_reg_data;
    wire [15:0] w_dbg_sr_reg;
    wire [31:0] w_dbg_pc_reg;
    wire [31:0] w_dbg_usp_reg;
    wire [31:0] w_dbg_ssp_reg;
    wire [31:0] w_dbg_cycles;
    wire        w_dbg_ifetch;
    wire  [2:0] w_dbg_irq_lvl;
	 
	 // CPM68K
	 reg  [15:0]  w_sysmd;	// b7=move_rom_ff8 000xxx --> ff8xxxx(32KB)
    
	 assign LED = {w_sysmd[7:2],stsout[4],sdcbusy};
	 assign DIG = 4'b1111;
	 
    // ========================================================================
    // 68000 core
    // ========================================================================
    
    cpu_j68 U_j68
    (
        .rst          (rst || sdwait),
        .clk          (clk),
        .clk_ena      (clk_ena),
        .rd_ena       (w_cpu_rden),
        .wr_ena       (w_cpu_wren),
        .data_ack     (w_cpu_dtack),
        .byte_ena     (w_cpu_bena),
        .address      (w_cpu_addr),
        .rd_data      (w_cpu_rdata),
        .wr_data      (w_cpu_wdata),
        .fc           (w_cpu_fc),
        .ipl_n        (ipl_n),
        .dbg_reg_addr (w_dbg_reg_addr), .dbg_reg_wren (w_dbg_reg_wren), .dbg_reg_data (w_dbg_reg_data),
        .dbg_sr_reg   (w_dbg_sr_reg), .dbg_pc_reg   (w_dbg_pc_reg),
        .dbg_usp_reg  (w_dbg_usp_reg), .dbg_ssp_reg  (w_dbg_ssp_reg),
        .dbg_vbr_reg  (), .dbg_cycles   (w_dbg_cycles),
        .dbg_ifetch   (w_dbg_ifetch), .dbg_irq_lvl  (w_dbg_irq_lvl)
    );
    
	wire req_adr = w_cpu_addr[23:0]==brk_adr && w_sysmd[6];
	reg  req_adrd,req_nmi;
	wire [2:0] ipl_n = req_nmi ? 3'b000 : r_cpu_ipl_n;
	
    always@(posedge rst or posedge clk) begin
	  if (rst) begin req_adrd <= 0; req_nmi <= 0; end
	  else begin
	    req_adrd <= req_adr;
		//if(req_adr && ~req_adrd) req_nmi <= 1; 
	    //if(req_nmi==1 && w_cpu_fc[0]==1) req_nmi <= 0;
	  end
	 end
    // Valid peripheral address
    assign w_cpu_vpa  = w_acia_a_cs || w_acia_b_cs || w_sysmd_cs;
    // Write control
    assign w_cpu_rw_n = w_cpu_rden & ~w_cpu_wren;
	 
	wire w_cpu_rwen  = w_cpu_rden || w_cpu_wren;
	wire w_rom_cs    = ((w_cpu_addr[23:16]==8'h00 && w_cpu_addr[15:14] == 2'b00 && ~w_sysmd[7]) ||	// 000xxx 
	                    (w_cpu_addr[23:16]==8'hff && w_cpu_addr[15:14] == 2'b01 && ~w_sysmd[6]) ) 	// FF4xxx MON68K
                       && w_cpu_rwen;
	wire w_bram_cs   = 0;//w_cpu_addr[23:16]==8'hfe && w_cpu_addr[15:12] == 4'b0101 && w_cpu_rwen && w_sysmd[7]; // FE5xxx BIOS
	wire w_dram_cs   = ~(w_ram_cs || w_scram_cs || w_scctl_cs || w_cpu_vpa) && w_cpu_rwen; // SDRAM
 	wire w_ram_cs    = 0; //w_cpu_addr[23:16]==8'h00 && w_cpu_addr[15:14] == 3'b01 && w_cpu_rwen && ~w_sysmd[7];
	wire w_acia_a_cs = w_cpu_addr[23:8] == 16'hff11 ? w_cpu_bena[1] : 1'b0; // ACIA0    FF11xx No.Use
	wire w_acia_b_cs = w_cpu_addr[23:8] == 16'hff10 ? w_cpu_bena[1] : 1'b0;	// ACIA1    FF10xx
	wire w_scram_cs  = w_cpu_addr[23:9] == {12'hff0,3'b001} && w_cpu_rwen;	// SDCD.BUF FF0200 - 3FF
	wire w_scctl_cs  = w_cpu_addr[23:8] == 16'hff01 && w_cpu_rwen;			// SDCD.CTL FF01xx
	wire w_ddmy_cs   = w_cpu_addr[23:8] == 16'hff00 && w_cpu_rwen;			// Disk.Dmy FF00xx
	wire w_sysmd_cs  = w_cpu_addr[23:8] == 16'hff0f && w_cpu_rwen;			// SYS.CTL  FF0Fxx
    
`ifdef verilator3
    import "DPI-C" function void m68k_trace_init(  input int vect_0, input int vect_1 );
    import "DPI-C" function void m68k_trace_fetch( input int sr, input int pc, input int usp, input int ssp, input int lvl );
    import "DPI-C" function void m68k_trace_regs(  input int addr, input int wren, input int data );
    import "DPI-C" function void m68k_trace_read(  input int fc, input int bena, input int addr, input int data );
    import "DPI-C" function void m68k_trace_write( input int fc, input int bena, input int addr, input int data );
    initial begin m68k_trace_init(VECT_0, VECT_1); end

    always@(posedge clk) begin : M68K_TRACE_CPP
        if (clk_ena) begin
            // Instruction fetch
            if (w_dbg_ifetch)
                m68k_trace_fetch({16'd0, w_dbg_sr_reg}, w_dbg_pc_reg, w_dbg_usp_reg, w_dbg_ssp_reg, {29'd0, w_dbg_irq_lvl});
            // Registers update
            m68k_trace_regs({28'd0, w_dbg_reg_addr}, {28'd0, w_dbg_reg_wren}, {16'd0, w_dbg_reg_data});
            // Read/write access
            if (w_cpu_dtack) begin
                if (w_cpu_rden)
                    m68k_trace_read({29'd0, w_cpu_fc}, {30'd0, w_cpu_bena}, w_cpu_addr, {16'd0, w_cpu_rdata});
                if (w_cpu_wren)
                    m68k_trace_write({29'd0, w_cpu_fc}, {30'd0, w_cpu_bena}, w_cpu_addr, {16'd0, w_cpu_wdata});
            end
        end
    end
`endif
    
    // ========================================================================
    // ACIA-A at $A000 / $A002 (Load port)
    // ========================================================================
    acia_6850 U_acia_6850_a (
        .reset(rst), .clk(clk), .e_clk(r_eclk[3]),
        .cs(w_acia_a_cs), .rw_n(w_cpu_rw_n), .rs(w_cpu_addr[1]),
        .data_in(w_cpu_wdata[15:8]), .data_out(w_aciaa_data_out),
        .data_en(w_aciaa_data_en), .irq_n(w_irq_1_n),
        .txclk(r_ser_clk), .rxclk(r_ser_clk),
        .rxdata(r_uart0_rxd[2]), .txdata(w_uart0_txd),
        .cts_n(uart0_cts_n), .dcd_n(uart0_dcd_n), .rts_n(uart0_rts_n)
    );
    always@(posedge clk) r_uart0_rxd <= { r_uart0_rxd[1:0], uart0_rxd };
    always@(posedge clk) r_uart0_txd <= { r_uart0_txd[1:0], w_uart0_txd };
    assign uart0_txd = r_uart0_txd[2];
    
    // ========================================================================
    // ACIA-B at $C000 / $C002 (Terminal)
    // ========================================================================
    acia_6850 U_acia_6850_b(
        .reset(rst), .clk(clk), .e_clk(r_eclk[3]),
        .cs(w_acia_b_cs), .rw_n(w_cpu_rw_n), .rs(w_cpu_addr[1]),
        .data_in(w_cpu_wdata[15:8]), .data_out(w_aciab_data_out),
        .data_en(w_aciab_data_en), .irq_n    (w_irq_2_n),
        .txclk(r_ser_clk), .rxclk(r_ser_clk),
        .rxdata(r_uart1_rxd[2]), .txdata(w_uart1_txd),
        .cts_n(uart1_cts_n), .dcd_n(uart1_dcd_n), .rts_n(uart1_rts_n)
    );
    always@(posedge clk) r_uart1_rxd <= { r_uart1_rxd[1:0], uart1_rxd };
    always@(posedge clk) r_uart1_txd <= { r_uart1_txd[1:0], w_uart1_txd };
    assign uart1_txd = r_uart1_txd[2];
    
    // ========================================================================
    // Clock generater
    // ========================================================================
    clkgen	clkgen(
       .areset(resflg), .inclk0 (clk50M), .c0 (clk), .c1 (clksdr), .c2 (clkspi),.locked (locked) );
    wire clk;
    reg [15:0] rescnt;
    reg       resflg;
    always@(posedge clk50M) begin // Cancel chattering 
       if(BTN[0]==0) begin resflg <= 1; rescnt <= 0; end
       else if(rescnt!=16'hffff) rescnt <= rescnt + 1;
		      else                 resflg <= 0;
	 end
    // ========================================================================
    // Serial clock
    // ========================================================================
    reg [15:0]	serialClkCount;
    always@(posedge rst or posedge clk50M) begin : SERIAL_CLOCK
        if (rst) begin serialClkCount <= 0; r_ser_clk <= 0; end
		  else        serialClkCount	<= serialClkCount + 16'd2416; // 115200bps/50M
		  r_ser_clk	<= serialClkCount[15]; 
	 end
    
    // ========================================================================
    // E clock (CPU clock divided by 10)
    // ========================================================================
    always@(posedge rst or posedge clk) begin : E_CLOCK
        if (rst) begin
            r_eclk <= 10'b0000000001;
        end else if (clk_ena) begin
            r_eclk <= { r_eclk[8:0], r_eclk[9] };
        end
    end
    
    // ========================================================================
    // Interrupts levels with priority encoding
    // ========================================================================
    always@(posedge rst or posedge clk) begin : IRQ_LEVEL
        reg [3:1] v_irq;
        if (rst) begin
            r_cpu_ipl_n <= 3'b111;
        end
        else if (clk_ena) begin
            v_irq[3] = ~w_irq_3_n;
            v_irq[2] = ~w_irq_2_n;
            v_irq[1] = ~w_irq_1_n;
            casez (v_irq)
                3'b??1 : r_cpu_ipl_n <= 3'b110; // Level #1 from ACIA-A
                3'b?10 : r_cpu_ipl_n <= 3'b101; // Level #2 from ACIA-B
                3'b100 : r_cpu_ipl_n <= 3'b100; // Level #3 (not used)
                3'b000 : r_cpu_ipl_n <= 3'b111; // No interrupts
            endcase
        end
    end
    assign w_irq_3_n = 1'b1;
    
    // ========================================================================
    // Data acknowledge
    // ========================================================================
    always@(posedge rst or posedge clk) begin : DTACK_GEN
        if (rst) begin
            r_rden_dly <= 1'b0; r_q_acia   <= 8'h00;
        end else begin
            // Read latencies
            r_rden_dly <= w_cpu_rden & ~w_cpu_vpa              // ROM/RAM read
                        | w_cpu_rden &  w_cpu_vpa & r_eclk[3]; // ACIAs read
            // Peripheral data bus
            if (r_eclk[3]) begin
                // MSB (even addresses)
                r_q_acia <= w_aciaa_data_out & {8{w_acia_a_cs}}  // ACIA-A
                          | w_aciab_data_out & {8{w_acia_b_cs}}; // ACIA-B
            end
        end
    end
    assign w_cpu_dtack = w_dram_cs ? sddtac : 
	                      w_cpu_wren & ~w_cpu_vpa             // RAM write
                       | w_cpu_wren &  w_cpu_vpa & r_eclk[3] // ACIAs write
                       | r_rden_dly;                         // ROM/RAM, ACIAs read
    
    // ========================================================================
    // Read data multiplexing
    // ========================================================================
	 assign w_cpu_rdata = w_rom_cs    ? w_q_rom :
	                      //w_bram_cs   ? w_q_bram :
	                      //w_ram_cs    ? w_q_ram :
	                      w_acia_a_cs ? { r_q_acia, 8'h00 } :
	                      w_acia_b_cs ? { r_q_acia, 8'h00 } :
						       d_scctl_cs  ? {8'h00,7'b1000000, sdcbusy} :
						       w_sysmd_cs  ? w_sysmd  :
	                      w_scram_cs  ? w_q_scram:
						       w_ddmy_cs   ? 16'h0000 : // Disk Dumy.Read(All0)
	                      w_dram_cs   ? w_q_dram :
						  16'hffff;

    // ========================================================================
    // Monitor Option
    // ========================================================================
    reg [15:0] w_scctl[0:3]; // 4word(8byte) RAM
	reg [23:0] brk_adr;
	reg [15:0] r_scctl;
	reg  [1:0] s_scctl; // Select scctl.addr
	reg [15:0] scctl_cmd,scctl_sts;
	wire [1:0] scctl_adr = w_cpu_addr[2:1];
	reg        sdcd_req,d_scctl_cs;
    always@(posedge rst or posedge clk) begin
        if (rst) begin
            w_sysmd <= 15'h00; brk_adr <= 24'h0;
			scctl_cmd <= 16'h0000; sdcd_req <= 0;
		end else begin
			d_scctl_cs <= w_scctl_cs;
			if(w_sysmd_cs && ~w_cpu_rw_n) begin 
				case(w_cpu_addr[2:1])
					2'h0: w_sysmd[15:0]  <= w_cpu_wdata[15:0];
					2'h1: brk_adr[23:16] <= w_cpu_wdata[7:0];
					2'h2: brk_adr[15:0]  <= w_cpu_wdata[15:0];
				endcase;
			end
			if(w_scctl_cs && ~w_cpu_rw_n) begin 
				w_scctl[scctl_adr] <= w_cpu_wdata; // Cmd
				case(w_cpu_addr[2:1])
					2'h0: begin scctl_cmd <= w_cpu_wdata; sdcd_req <= 1; end
					2'h1: sdadr[23:16] <= w_cpu_wdata[7:0];
					2'h2: sdadr[15:0]  <= w_cpu_wdata[15:0];
					default: ;
				endcase;
			end
			r_scctl <= w_scctl[scctl_adr];
			if(sdcd_req && sdacc) sdcd_req <= 0;
		end
    end
	 
    // ========================================================================
    // 16 KB ROM at $0000 - $3FFF
    // ========================================================================
    onchip_rom U_onchip_rom(
        .clock(clk), .address(w_cpu_addr[13:1]), .q(w_q_rom) );

    // ========================================================================
    // 8 KB ROM at $6000 - $7FFFF
    // ========================================================================
	//biosram	biosram(
	//	.clock (clk), .wren (w_cpu_wren && w_bram_cs), .byteena (w_cpu_bena),
	//	.address (w_cpu_addr[12:1]), .data (w_cpu_wdata), .q (w_q_bram) );

    // ========================================================================
    // 4 KB RAM at $4000 - $4FFF
    // ========================================================================
    //onchip_ram U_onchip_ram(
    //    .clock(clk), .wren(w_cpu_wren && w_ram_cs), .byteena(w_cpu_bena),
    //    .address(w_cpu_addr[13:1]), .data(w_cpu_wdata), .q(w_q_ram) );

    // ========================================================================
    // 256W(16bit) SD_card R/W RAM
    // ========================================================================
	sdcd_ram sdcd_ram(
		.clock (clk), .wren (srwen), .byteena (srben), .address (srmad[7:0]),
		.data (srwpt),.q (w_q_scram) );

    // ========================================================================
    // 16 MB DRAM at $0000 - $ffff
    // ========================================================================
	wire clksdr,locked;
	assign SDRAM_CLK = ~clksdr; 
	assign SDRAM_CKE = 1'b1;
	sdram sdram (
	  .clk_hi(clksdr), .sdt( syncsd[2:0]), .init(rst),
	  .addr(w_cpu_addr[24:1]), .din(w_cpu_wdata), .dout(sddout), .ds(w_cpu_bena),
	  .we(w_dram_cs & & w_cpu_wren & sdaccm), .oe(w_dram_cs & w_cpu_rden & sdaccm),
	  .sd_addr( SDRAM_ADDR), .sd_data( SDRAM_DATA), .sd_dqm( {SDRAM_DQMH, SDRAM_DQML} ),
	  .sd_ba( SDRAM_BA), .sd_cs( SDRAM_nCS), .sd_we( SDRAM_nWE),
	  .sd_ras( SDRAM_nRAS), .sd_cas( SDRAM_nCAS) );

	reg [3:0]   syncsd;
	wire [15:0] sddout;
	reg  [15:0] sddoutl;
	reg         sdaccm,sddtac,sdwait;
	reg  [7:0]  sdwaitc;
	assign w_q_dram = sddoutl;
	always @(posedge rst or posedge clksdr)	begin
	   if (rst) begin
		   sdaccm = 0; sddtac <= 0; sdwait <= 1; sdwaitc <= 0;
		end else begin
		   //
			if(sdwait) begin
			  sdwaitc <= sdwaitc +1;
			  if(sdwaitc==8'hff) sdwait <= 0;
			end
			//
		   syncsd[3:0] <= syncsd[3:0] + 4'd1;
			if(w_dram_cs) begin
			   if(syncsd==3'h7) 
				   if(sdaccm==0) sdaccm = 1;
					else          sdaccm = 0;
		      if(sdaccm==1 && syncsd==3'h6) begin
			      sddtac <= 1; 
					if(w_cpu_rden) sddoutl <= sddout;
				end
			end else begin
			   sdaccm <= 0; sddtac <= 0;
			end
		end
	end

    // ========================================================================
    // SD Controller
    // ========================================================================

// regAddr dataOut   n_rd(Rise)   n_wr(Rise)
//  000    <= sdout  Data.Read    Data.Write              
//  001    <= status              Start.Read(0)/Write(1)  0/1=DataIn/Out
//  010 - 100 Block.Adr SDHC(7:0-15:8-23:16) SDSC(16:9-24:17-31:25)  
//	status(7) <= '1' tx empty  status(6) <= '0' rx ready
//	status(5) <= block_busy;   status(4) <= init_busy;
	sd_controller	sd1 (
		.clk(clkspi), .n_reset(!rst), .regAddr(sdra),
		.n_wr(!sdwr), .n_rd(!sdrd),
		.dataIn(sdin), .dataOut(sdout), .stsout(stsout),
		.sdCS(SD_CS), .sdMOSI(SD_CMD), .sdMISO(SD_DAT0), .sdSCLK(SD_SCK),
		.driveLED()
	);
	
	wire clkspi;
	//reg clkspi,clkspix; // 50/2 = 25MHz
	//always@(posedge clk) begin
	//	clkspix <= ~clkspix;
	//	if(clkspix) 
	//	  clkspi <= ~clkspi;
	//end

	wire [7:0]   stsout;
	wire rdb   = 0; //BTN[0];
	wire wrb   = 0; //BTN[1];
	reg  sdrd,sdwr,sdcbusy,mrwe;
	reg  [23:0] sdadr;
	reg  [2:0]  sdra;
	reg  [7:0]  sdin,mrdi;
	wire [7:0]  mrdo;
	reg  [13:0] mradr;      // Buffer.Point 
	(* keep *)wire [7:0]  sdrdt,sdout,sdled;
	reg  [7:0] sdsts;
	reg [9:0] sdbbcnt;

	reg         rdd,wrd;
	reg  [2:0]  rseq,wseq,aseq,aseqc,rmseq,wmseq,sdmode;
	reg  [23:0] secct;

	 wire        srwen;
	 reg         sdwen;
	 wire [1:0]  srben,sdben;
	 wire [12:0] srmad,sdmad;
	 wire [15:0] srwpt,sdwpt;
	 wire sdacc = rseq!=0 || wseq!=0; // SD.Access = 1
	 assign srwen = sdacc ? sdwen : w_cpu_wren && w_scram_cs;
	 assign srben = sdacc ? sdben : w_cpu_bena;
	 assign srmad = sdacc ? sdmad : w_cpu_addr[13:1];
	 assign srwpt = sdacc ? sdwpt : w_cpu_wdata;
	 
	 assign sdben = 2'b11;
	 assign sdmad = mradr[13:1];
	 assign sdwpt = {whdat,sdout};
	 
	reg  [7:0]  whdat;
	reg         mrwed;

	always @(posedge rst or posedge clkspi) begin
		if(rst) begin
			rseq <= 3'h0; wseq <= 3'h0; aseq <= 3'h0;
			rmseq <= 3'h0; wmseq <= 3'h0; sdcbusy <= 0;
			sdra <= 3'b001; 
			//sdadr <= 24'h000000; 
			mrwe <= 1'b0;
		end else begin
			if(rdb && !rdd) rmseq <= 3'h1;
			if(sdcd_req && ~sdacc && scctl_cmd[1:0]!=2'b11) begin 
				if(scctl_cmd[0]) begin sdmode <= 0; aseq <= 3'h1; rseq <= 3'h1; end
				if(scctl_cmd[1]) begin sdmode <= 1; aseq <= 3'h1; wseq <= 3'h1; end
			end
			//if(wrb && !wrd) wmseq <= 3'h1;
			rdd <= rdb; wrd <= wrb;
			if(sdra==3'b001) sdsts <= sdout;

			case(rseq)
				3'h1: begin 
					if(aseq==3'h0) begin
						sdbbcnt <= 0; rseq <= 3'h2;
					end
					end
				3'h2: begin 
					if(sdout[5] && !sdout[4]) rseq <= 3'h3; // INIT & BLOCK Not.Busy
					end
				3'h3: begin sdra <= 3'b001; rseq <= 3'h4; end
				3'h4: begin
					if(!sdout[5]) begin rseq <= 3'h7; end // Read(512B).End
					else
						if(sdout[6]) begin sdra <= 3'b000; sdrd <= 1'b1; rseq <= 3'h5; end 
					end
				3'h5: begin
					sdrd <= 1'b0; mrdi <= sdout; 
					if(sdbbcnt<512) begin
						if(mradr[0]==0) whdat <= sdout;
						else            sdwen <= 1'b1; 
					end
					rseq <= 3'h6;
					end
				3'h6: begin 
						sdwen <= 1'b0;	sdbbcnt <= sdbbcnt + 1;  
						if(sdbbcnt<512) mradr <= mradr + 14'h1; 
						rseq <= 3'h3;  
					end
				3'h7: begin sdcbusy <= 0; rseq <= 0; end
				default: ;
			endcase;
			//
			case(wseq)
				3'h1: if(aseq==3'h0) begin sdwen <= 0; wseq <= 3'h2; end
				3'h2: begin 
					if(sdout[5] && !sdout[4]) wseq <= 3'h3; 
				end
				3'h3: begin sdra <= 3'b001; wseq <= 3'h4; end
				3'h4: begin 
					if(!sdout[5]) begin 
						wseq <= 3'h7; end // Write(512B).End
					else
						if(sdout[7]) begin 
							if(mradr[0]==0) sdin <= w_q_scram[15:8];
							else            sdin <= w_q_scram[7:0];
							//mradr <= mradr + 14'h1;
							sdra <= 3'b000; sdwr <= 1'b1; wseq <= 3'h5;
						end 
				end
				3'h5: begin sdwr <= 1'b0; mradr <= mradr + 14'h1; wseq <= 3'h3; end
				3'h7: begin sdcbusy <= 0; wseq <= 0; end
				default: ;
			endcase;
		//
		case(aseq)
			3'h1: begin sdra <= 3'b010; aseqc <= 3'h0; aseq <= 3'h2; end
			3'h2: begin sdwr <= 1'b1; aseq <= 3'h3; end
			3'h3: begin  
					case(aseqc)
						3'h0: begin sdcbusy <= 1; sdra <= 3'b010; sdin <= sdadr[ 7: 0]; end
						3'h1: begin sdra <= 3'b011; sdin <= sdadr[15: 8]; end
						3'h2: begin sdra <= 3'b100; sdin <= sdadr[23:16]; end
						3'h3: begin if(sdmode) sdin <= 8'h01;
										else   sdin <= 8'h00;
										sdra <= 3'b001; 
								end
						default: ;
					endcase
					aseq <= 3'h4;
				end
			3'h4: begin sdwr <= 1'b0; aseq <= 3'h5; end 
			3'h5: begin 
					aseqc <= aseqc + 3'h1;
					if(aseqc<3'h3) aseq <= 3'h2;
					else           aseq <= 3'h7; // Address Set.End
				end
			3'h7: begin mradr <= 14'h0; aseq <= 3'h0; end
			default: ;
		endcase

		end
    end

endmodule
`default_nettype wire

