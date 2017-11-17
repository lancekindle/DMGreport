include "gbhw.inc"
include "cgbhw.inc"

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

SECTION "Vblank", ROM0[$0040]
	reti

SECTION "LCDC", ROM0[$0048]
	reti

SECTION "Timer", ROM0[$0050]
	reti

SECTION "Serial", ROM0[$0058]
	reti

SECTION "Joypad", ROM0[$0060]
	reti
;----------- END INTERRUPT VECTORS -------------------

SECTION "ROM_entry_point", ROM0[$0100]	; ROM is given control from boot here
	nop
	jp	code_begins

;------------- BEGIN ROM HEADER ----------------
; The gameboy reads this info (before handing control over to ROM)
SECTION "rom header", ROM0[$0104]
	NINTENDO_LOGO

 ; ROM HEADER (included in full this time)
 DB " color palette " ; Cart name - 15bytes

 DB $80			  ; $143 - GBC support. $80 = both. $C0 = only gbc
; BGB (the emulator) will boot to color hardware if cartridge supports it.
; if this byte is 0 (or something aside form $80 and $C0), hardware will boot
; with original DMG gameboy stuff (palette, starting register vals, & logo)
; =============================================================

 DB 0,0			  ; $144 - Licensee code (not important)
 DB 0			  ; $146 - SGB Support indicator
 DB 0			  ; default NOMBC
 DB 0			  ; $148 - ROM Size -- default 32KB ROM size
 DB 0			  ; $149 - RAM Size (default 0KB)
 DB 1			  ; $14a - Destination code
 DB $33			  ; $14b - Old licensee code
 DB 0			  ; $14c - Mask ROM version
 DB 0			  ; $14d - Complement check (important)
 DW 0			  ; $14e - Checksum (not important)


; by convention, *.asm files add code to the ROM when included. *.inc files
; do not add code. They only define constants or macros. The macros add code
; to the ROM when called

code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM
; assume that we're inside a gameboy color. Set color palettes
	ld	hl, background_palettes
	call	rgb_SetAllBGP

.loop
	halt
	nop
	jp	.loop


; *** Set all background palettes ***
; Entry: HL = pntr to data for 8 palettes
rgb_SetAllBGP:
	ld	a,%10000000	; bit 7 = auto-increment.
				; Bits 0-6 = index of palette to update
; when auto-increment is set, writing to rBCPD auto-increments
; to the next byte, and then the next palette (every 8 bytes)
	ldh	[rBCPS],a
	ld	bc, $4000 | (rBCPD & $00FF)
	; b = 64, c = rBCPD	(when using ld [$FF00+c], a)
	; There are a total of 8 background palettes * 8 bytes per palette = 64
.loop1:
	di
.loop2:
	ldh	a,[rSTAT]
	and	STATF_BUSY
	jr	nz, .loop2
	ld	a,[hl+]
	ld	[$FF00+c],a	; write to successive palette bytes
	ei
	dec	b
	jr	nz, .loop1
	ret


; This RGBSet Macro uses RGB values from 0 to 255. It then reduces the range
; to 0-32. With a range 0-32, each color component is represented by 5 bits,
; and a full 3-tuple color is represented by 15 bits. (aka 2 bytes)
; Blue:  bits 14-10		(note that bit 15 is not used)
; Green: bits 9-5
; Red:   bits 4-0
; Example: rgb_Set 255, 0, 0  ; RED
rgb_Set: MACRO
	; DW (define-word) stores LSB then MSB in-memory
	; meaning that passing rgb_Set a tuple of the form RRR, GGG, BBB
	; will be stored in-rom as two successive bytes: %GGGRRRRR, %xBBBBBGG
	; yet the 16-bit value (before writing to rom) is %xBBBBBGG %GGGRRRRR
	; This is the exact order (LSB first) that the GBC expects in rBCPD
	DW	((\3 >> 3) << 10) + ((\2 >> 3) << 5) + (\1 >> 3)
	ENDM


; generate 8 palettes of colors here. Each palette contains 4 shades of color
background_palettes:
	; set all 4 shades to same color (only for demo)
	; each color takes up 2 bytes (5 bits per RGB tuple, so 15 bits)
	rgb_Set	0, 255, 255	; Cyan
	rgb_Set	0, 255, 255	; Cyan
	rgb_Set	0, 255, 255	; Cyan
	rgb_Set	0, 255, 255	; Cyan

	rgb_Set	255, 0, 0	; Red
	rgb_Set	255, 0, 0	; Red
	rgb_Set	255, 0, 0	; Red
	rgb_Set	255, 0, 0	; Red

	rgb_Set	0, 255, 0	; Green
	rgb_Set	0, 255, 0	; Green
	rgb_Set	0, 255, 0	; Green
	rgb_Set	0, 255, 0	; Green

	rgb_Set	0, 0, 255	; Blue
	rgb_Set	0, 0, 255	; Blue
	rgb_Set	0, 0, 255	; Blue
	rgb_Set	0, 0, 255	; Blue

	rgb_Set	255, 255, 0	; Yellow
	rgb_Set	255, 255, 0	; Yellow
	rgb_Set	255, 255, 0	; Yellow
	rgb_Set	255, 255, 0	; Yellow

	rgb_Set	255, 0, 255	; Pink/Purple
	rgb_Set	255, 0, 255	; Pink/Purple
	rgb_Set	255, 0, 255	; Pink/Purple
	rgb_Set	255, 0, 255	; Pink/Purple

	rgb_Set	0, 0, 0		; Black
	rgb_Set	0, 0, 0		; Black
	rgb_Set	0, 0, 0		; Black
	rgb_Set	0, 0, 0		; Black

	rgb_Set	255, 255, 255	; White
	rgb_Set	255, 255, 255	; White
	rgb_Set	255, 255, 255	; White
	rgb_Set	255, 255, 255	; White



;	Some background info from cgbhw.inc
; -- BCPS ($FF68)
; -- Background Color Palette Specification (R/W)
; -- AKA Background Colors Index. Allows you to change colors.
; -- Write to this to set which color / palette you'd like to R/W from.
;	(using rBCPD)
; -- Bit 7 - specifies autoincrement (1) or not (0). If set, will
;	increment to next index on write.
; -- Bits 5-3 - specify the palette #
; -- Bits 2-1 - Specifies the palette data/color #
; -- Bit 0 - Specifies H/L (H:1, L:0) of Red, Green, or Blue data
; -- Low-byte contains	%GGGRRRRR
; -- High-byte contains %xBBBBBGG
; --
; -- So... There are a total of 8 palettes. Specify which one you'd like
;	to R/W by setting bits 5-3 appropriately.
; -- There are a total of 4 colors per palette. Specify which color you'd
;	like to R/W by settings bits 2-1.
; -- It takes two bytes to set each color. Each color is RGB, range of 0-31
;	Red: bits 0-4, Green: bits 5-9, Blue: bits 10-14 (bit 15 ignored)
; --

; -- BCPD ($FF69)
; -- Background Color Palette Data (R/W)
; -- R/W the color(s) of a palette (index) specified by rBCPS.
; -- To write a full palette, write 1 color at a time, 2 bytes per color
; -- in this format: %xBBBBBGG GGGRRRRR, where you write the low byte first.
; -- (low-byte, in this case, refers to %xBBBBBGG)
; -- after you've written 4 colors (8 bytes), a full palette has been
; -- specified. To use these colors, you'll have to set the color-pointer in
; -- VRAM bank 1 at the same location as the corresponding tile in VRAM Bank 0
; -- See rVRAM_BANK for details


; ================ QUESTIONS FOR STUDENT ===========================
; Can you make it so that Red displays on-screen?
; Create your own color and have it display on the background
