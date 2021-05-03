//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


// TODO
//  - Complete Keyboard Mapping
//  - Make Memory size select from OSD
//  - Select PAL/NTSC
//  - OSD Load Keyboard Map 
//  - Tape Load Graphical wave
//  - Tape Counter (bytes)

// Done
//  - Rewind on CAS load or Reset
//  - LED_Disk on Tape Load

//Core : 
//Z80 - 3,5555Mhz
//AY - z80/2 = 1,777 Mhz
//Mess :
//Z80 - 3,579545
//AY - 1,789772



module SVI328
(       
        output        LED,                                              
        output        VGA_HS,
        output        VGA_VS,
        output        AUDIO_L,
        output        AUDIO_R,  
        input         TAPE_IN,
        input         UART_RXD,
        output        UART_TXD,
        input         SPI_SCK,
        output        SPI_DO,
        input         SPI_DI,
        input         SPI_SS2,
        input         SPI_SS3,
        input         CONF_DATA0,
        input         CLOCK_27,
        output  [5:0] VGA_R,
        output  [5:0] VGA_G,
        output  [5:0] VGA_B,

		  output [12:0] SDRAM_A,
		  inout  [15:0] SDRAM_DQ,
		  output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nWE,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nCS,
        output  [1:0] SDRAM_BA,
        output        SDRAM_CLK,
        output        SDRAM_CKE
);


 
assign LED  =  svi_audio_in;




`include "build_id.v" 
parameter CONF_STR = {
	"SVI328;;",
	"F,BINROM,Load Cartridge;",
	"F,CAS,Cas File;",
	"OF,Tape Input,File,Line;",
	"TD,Tape Rewind;",
	"O79,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O6,Border,No,Yes;",
	"O3,Joysticks swap,No,Yes;",
	"T0,Reset;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_sys;
wire pll_locked;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),
	.locked(pll_locked)
);

reg ce_10m7 = 0;
reg ce_5m3 = 0;
reg ce_21m3 = 0;
always @(posedge clk_sys) begin
	reg [2:0] div;
	
	div <= div+1'd1;
	ce_10m7 <= !div[1:0];
	ce_5m3  <= !div[2:0];
	ce_21m3 <= div[0];
end

/////////////////  HPS  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [31:0] joy0, joy1;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire [10:0] PS2Keys;
 
mist_io #(.STRLEN($size(CONF_STR)>>3)) mist_io
(
	.SPI_SCK   (SPI_SCK),
   .CONF_DATA0(CONF_DATA0),
   .SPI_SS2   (SPI_SS2),
   .SPI_DO    (SPI_DO),
   .SPI_DI    (SPI_DI),

	.clk_sys(clk_sys),
	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(forced_scandoubler),
   .ypbpr     (ypbpr),
	
	.ioctl_ce(1),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
		
	.ps2_key(PS2Keys),
	
	.joystick_0(joy0), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy1)

);

/////////////////  RESET  /////////////////////////

wire reset = status[0] | buttons[1] | (ioctl_download && ioctl_isROM);

////////////////  KeyBoard  ///////////////////////


wire [3:0] svi_row;
wire [7:0] svi_col;
sviKeyboard KeyboardSVI
(
	.clk		(clk_sys),
	.reset	(reset),
	
	.keys		(PS2Keys),
	.svi_row (svi_row),
	.svi_col (svi_col)
	
);


wire [15:0] cpu_ram_a;
wire        ram_we_n, ram_rd_n, ram_ce_n;
wire  [7:0] ram_di;
wire  [7:0] ram_do;


wire [13:0] vram_a;
wire        vram_we;
wire  [7:0] vram_di;
wire  [7:0] vram_do;

spram #(14) vram
(
	.clock(clk_sys),
	.address(vram_a),
	.wren(vram_we),
	.data(vram_do),
	.q(vram_di)
);


wire sdram_rdy;


wire sdram_we,sdram_rd;
wire [17:0] sdram_addr;
wire  [7:0] sdram_din;
wire ioctl_isROM = (ioctl_index[5:0]<6'd2); //Index osd File is 0 (ROM) or 1(Rom Cartridge)


assign sdram_we = (ioctl_wr && ioctl_isROM) | ( isRam & ~(ram_we_n | ram_ce_n));
assign sdram_addr = (ioctl_download && ioctl_isROM) ? {ioctl_index[0],ioctl_addr[15:0]} : ram_a;
assign sdram_din = (ioctl_wr && ioctl_isROM) ? ioctl_dout : ram_do;

assign sdram_rd = ~(ram_rd_n | ram_ce_n);
assign SDRAM_CLK = ~clk_sys;
sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

   .wtbt(0),
   .addr(sdram_addr), 
   .rd(sdram_rd),
   .dout(ram_di),
   .din(sdram_din),
   .we(sdram_we), 
   .ready(sdram_rdy)
);


wire [17:0] ram_a;
wire isRam;

wire motor;

svi_mapper RamMapper
(
    .addr_i		(cpu_ram_a),
    .RegMap_i	(ay_port_b),
    .addr_o		(ram_a),
	 .ram			(isRam)
);


////////////////  Console  ////////////////////////

wire [10:0] audio;

dac #(10) dac_l (
   .clk_i        (clk_sys),
   .res_n_i      (1      ),
   .dac_i        (audio),
   .dac_o        (AUDIO_L)
);

assign AUDIO_R=AUDIO_L;

assign CLK_VIDEO = clk_sys;

wire [7:0] R,G,B,ay_port_b;
wire hblank, vblank;
wire hsync, vsync;

wire [31:0] joya = status[3] ? joy1 : joy0;
wire [31:0] joyb = status[3] ? joy0 : joy1;


wire svi_audio_in = status[15] ? tape_in : (CAS_status != 0 ? CAS_dout : 1'b0);

cv_console console
(
	.clk_i(clk_sys),
	.clk_en_10m7_i(ce_10m7),
	.clk_en_5m3_i(ce_5m3),
	.reset_n_i(~reset),

   .svi_row_o(svi_row),
   .svi_col_i(svi_col),	
	
	.svi_tap_i(svi_audio_in),//status[15] ? tape_in : (CAS_status != 0 ? CAS_dout : 1'b0)),

   .motor_o(motor),

	.joy0_i(~{joya[4],joya[0],joya[1],joya[2],joya[3]}), //SVI {Fire,Right, Left, Down, Up} // HPS {Fire,Up, Down, Left, Right}
	.joy1_i(~{joyb[4],joyb[0],joyb[1],joyb[2],joyb[3]}),

	.cpu_ram_a_o(cpu_ram_a),
	.cpu_ram_we_n_o(ram_we_n),
	.cpu_ram_ce_n_o(ram_ce_n),
	.cpu_ram_rd_n_o(ram_rd_n),
	.cpu_ram_d_i(ram_di),
	.cpu_ram_d_o(ram_do),

	.ay_port_b(ay_port_b),
	
	.vram_a_o(vram_a),
	.vram_we_o(vram_we),
	.vram_d_o(vram_do),
	.vram_d_i(vram_di),

	.border_i(status[6]),
	.rgb_r_o(R),
	.rgb_g_o(G),
	.rgb_b_o(B),
	.hsync_n_o(hsync),
	.vsync_n_o(vsync),
	.hblank_o(hblank),
	.vblank_o(vblank),

	.audio_o(audio)
);


/////////////////  VIDEO  /////////////////////////


wire [2:0] scale = status[9:7];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg hs_o, vs_o;
always @(posedge CLK_VIDEO) begin
	hs_o <= ~hsync;
	if(~hs_o & ~hsync) vs_o <= ~vsync;
end

video_mixer #(.LINE_LENGTH(290)) video_mixer
(
	.*,

	.ce_pix(ce_5m3),
   .ce_pix_actual(ce_5m3),
   
	.scandoubler_disable(forced_scandoubler),
	.hq2x(scale==1),
	.mono(0),
	.scanlines(forced_scandoubler ? 2'b00 : {scale==3, scale==2}),
   .ypbpr_full(0),
   .line_start(0),


	.R(R[7:2]),
	.G(G[7:2]),
	.B(B[7:2]),

	// Positive pulses.
	.HSync(hs_o),
	.VSync(vs_o),
	.HBlank(hblank),
	.VBlank(vblank)
);




/////////////////  Tape In   /////////////////////////

wire tape_in;
assign tape_in = UART_RXD;


///////////// OSD CAS load //////////

wire CAS_dout;
wire [2:0] CAS_status;
wire play, rewind;
wire CAS_rd;
wire [25:0] CAS_addr;
wire [7:0] CAS_di;

wire [25:0] CAS_ram_addr;
wire CAS_ram_wren, CAS_ram_cs;
wire ioctl_isCAS = (ioctl_index[5:0] == 6'd2);

assign CAS_ram_cs = 1'b1;
assign CAS_ram_addr = (ioctl_download && ioctl_isCAS) ? ioctl_addr[17:0] : CAS_addr;
assign CAS_ram_wren = ioctl_wr && ioctl_isCAS; 

//17 128
//18 256
spram #(13) CAS_ram
(
	.clock(clk_sys),
	.cs(CAS_ram_cs),
	.address(CAS_ram_addr),	
	.wren(CAS_ram_wren), 
	.data(ioctl_dout),
	.q(CAS_di)
);


assign play = ~motor;
assign rewind = status[13] | (ioctl_download && ioctl_isCAS) | reset; //status[13];

cassette CASReader(

  .clk(ce_21m3), //  42.666/2
  .play(play), 
  .rewind(rewind),

  .sdram_addr(CAS_addr),
  .sdram_data(CAS_di),
  .sdram_rd(CAS_rd),

  .data(CAS_dout),
  .status(CAS_status)

);

endmodule