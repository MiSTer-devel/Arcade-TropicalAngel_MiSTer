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
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign FB_FORCE_BLANK = 0;

assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_USER = ioctl_download;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? (status[7] ? 12'd939 : 12'd956) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (status[7] ? 12'd956 : 12'd939) : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.TropicalAngel;;",
	"-;",
	"H0O[2:1],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[5:3],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O[6],Video Timing,Original,Pal 50Hz;",
	"H0O[7],Orientation,Vert,Horz;",
	"O[8],Flip,Off,On;",
	"O[9],Invulnerability,Off,On;",
	"-;",
	"R[0],Reset and close OSD;",
	"J1,Gas,Trick,Start,Coin;",
	"jn,A,B,Start,Select;",
	"V,v",`BUILD_DATE
};

wire [127:0] status;
wire   [1:0] buttons;
wire         palmode = status[6];
wire         flipvid = status[8];
wire         invuln  = status[9];
wire         forced_scandoubler;
wire         direct_video;
wire         video_rotated;

wire  [14:0] rom_addr;
wire  [15:0] rom_do;
wire  [12:0] snd_rom_addr;
wire  [16:1] snd_addr;
wire  [15:0] snd_do;
wire         snd_vma, snd_vma_r, snd_vma_r2;
wire  [14:0] sp_addr;
wire  [31:0] sp_do;

wire         ioctl_download;
wire         ioctl_wr;
wire  [24:0] ioctl_addr;
wire   [7:0] ioctl_dout;
wire   [7:0] ioctl_index;

wire  [15:0] joystick_0,joystick_1;
wire  [15:0] joy = joystick_0 | joystick_1;

wire  [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_36),
	.HPS_BUS(HPS_BUS),

	.EXT_BUS(),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_48, clk_36, clk_72;
wire clk_sys = clk_36;
wire pll_locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_48),
	.outclk_1(clk_36),
	.outclk_2(clk_72),
	.locked(pll_locked)
);

wire reset = (RESET | status[0] | buttons[1] | ioctl_download);

//////////////////////////////////////////////////////////////////

/* ROM structure
00000 - 07FFF main CPU    32k  ta-a-3k ta-a-3m ta-a-3n ta-a-3q
08000 - 09FFF  snd CPU     8k  ta-s-1a
0A000 - 0FFFF gfx1        24k  ta-a-3e ta-a-3d ta-a-3c
10000 - 1BFFF gfx2        48k  ta-b-5j ta-b-5h ta-b-5e ta-b-5d ta-b-5c ta-b-5a
1C000 - 1C0FF chr pal lo 256b  ta-a-5a
1C100 - 1C1FF chr pal hi 256b  ta-a-5b
1C200 - 1C2FF spr pal    256b  ta-b-3d
1C300 - 1C31F spr lut     32b  ta-b-1b
*/

wire [24:0] sp_ioctl_addr = ioctl_addr - 17'h10000; //SP ROM offset: 0x10000

reg port1_req, port2_req;
sdram sdram
(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_72       ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_download ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_download ? 16'hffff : {2'b00, rom_addr[14:1]} ),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( ioctl_download ? 16'hffff : snd_addr ),
	.cpu2_q        ( snd_do ),
	.cpu3_addr 	   (),
	.cpu3_q		   (),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {sp_ioctl_addr[23:16], sp_ioctl_addr[13:0], sp_ioctl_addr[15]} ), // merge sprite roms to 32-bit wide words
	.port2_ds      ( {sp_ioctl_addr[14], ~sp_ioctl_addr[14]} ),
	.port2_we      ( ioctl_download ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( ioctl_download ? 15'h7fff : sp_addr ),
	.sp_q          ( sp_do )
);

// ROM download controller
always @(posedge clk_72) begin
	reg ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_download & !ioctl_index) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end

	// async clock domain crossing here (clk_aud -> clk_36)
	snd_vma_r <= snd_vma;
	snd_vma_r2 <= snd_vma_r;
	if (snd_vma_r2) snd_addr <= 16'h4000 + snd_rom_addr[12:1];
end

// // reset signal generation
// reg reset = 1;
// reg rom_loaded = 0;
// always @(posedge clk_36) begin
// 	reg ioctl_downloadD;
// 	reg [15:0] reset_count;
// 	ioctl_downloadD <= ioctl_download;

// 	if (RESET | status[0] | buttons[1] | ~rom_loaded) reset_count <= 16'hffff;
// 	else if (reset_count != 0) reset_count <= reset_count - 1'd1;

// 	if (ioctl_downloadD & ~ioctl_download) rom_loaded <= 1;
// 	reset <= reset_count != 16'h0000;

// end

wire m_up     = joystick_0[3];
wire m_down   = joystick_0[2];
wire m_left   = joystick_0[1];
wire m_right  = joystick_0[0];
wire m_gas    = joystick_0[4];
wire m_trick  = joystick_0[5];

wire m_up2    = joystick_1[3];
wire m_down2  = joystick_1[2];
wire m_left2  = joystick_1[1];
wire m_right2 = joystick_1[0];
wire m_gas2   = joystick_1[4];
wire m_trick2 = joystick_1[5];

wire m_start1 = joystick_0[6];
wire m_coin1  = joystick_0[7];
wire m_start2 = joystick_1[6];
wire m_coin2  = joystick_1[7];

wire hblank, vblank;
wire blankn;
wire hs, vs;
wire [1:0] r;
wire [2:0] g, b;
wire [1:0] r_swap = {r[0], r[1]};
wire [2:0] red   = blankn ? {r_swap, r_swap[1] } : 0;
wire [2:0] green = blankn ? g : 0;
wire [2:0] blue  = blankn ? b : 0;

reg ce_pix;
always @(posedge clk_48) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
end

wire no_rotate  = status[7] | direct_video;
wire rotate_ccw = 1;
wire flip       = 0;

screen_rotate screen_rotate (.*);

arcade_video #(384,9) arcade_video
(
	.*,

	.clk_video(clk_48),

	.RGB_in({red,green,blue}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);

wire [10:0] audio;
assign AUDIO_L = {audio, 5'd0};
assign AUDIO_R = {audio, 5'd0};
assign AUDIO_S = 0;

reg clk_aud;
always @(posedge clk_36) begin
	reg [15:0] sum;

	clk_aud = 0;
	sum = sum + 16'd895;
	if(sum >= 36000) begin
		sum = sum - 16'd36000;
		clk_aud = 1;
	end
end

wire [7:0] dip1 = ~8'b00000010;
wire [7:0] dip2 = ~{ 1'b0, invuln, 1'b0, 1'b0/*stop*/, 3'b010, flipvid };

TropicalAngel TropicalAngel
(
	.clock_36(clk_36),
	.clock_0p895(clk_aud),
	.reset(reset),

	.palmode(palmode),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hs(hs),
	.video_vs(vs),
	.video_hblank(hblank),
	.video_vblank(vblank),
	.video_blankn(blankn),

	.audio_out(audio),

	.cpu_rom_addr(rom_addr),
	.cpu_rom_do(rom_addr[0] ? rom_do[15:8] : rom_do[7:0]),
	.snd_rom_addr(snd_rom_addr),
	.snd_rom_do(snd_rom_addr[0] ? snd_do[15:8] : snd_do[7:0]),
	.snd_rom_vma(snd_vma),
	.sp_addr(sp_addr),
	.sp_graphx32_do(sp_do),

	.dip_switch_1(dip1),
	.dip_switch_2(dip2),

	.input_0(~{4'd0, m_coin1, 1'b0 /*service*/, m_start2, m_start1}),
	.input_1(~{m_gas, 1'b0, m_trick, 1'b0, m_up, m_down, m_left, m_right}),
	.input_2(~{m_gas2, 1'b0, m_trick2, m_coin2, m_up2, m_down2, m_left2, m_right2}),

	.dl_clk(clk_72),
	.dl_addr(ioctl_addr[16:0]),
	.dl_data(ioctl_dout),
	.dl_wr(ioctl_wr)
);

endmodule
