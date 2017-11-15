include "gbhw.inc"

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
	ROM_HEADER	"  HELLO WORLD  "

; by convention, *.asm files add code to the ROM when included. *.inc files
; do not add code. They only define constants or macros. The macros add code
; to the ROM when called

include	"ibmpc1.inc"	; used to generate ascii characters in our ROM
include "memory.asm"	; used to copy Monochrome ascii characters to VRAM

code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM

	call	lcd_Stop

	; load ascii tiles (inserted below with chr_IBMPC1 macro) into VRAM
	ld	hl, ascii_tiles	; ROM address where we insert ascii tiles
	ld	de, _VRAM	; destination. Going to copy ascii to video ram
	; bc = byte-count. Aka how many bytes to copy
	ld	bc, ascii_tiles_end - ascii_tiles
	call	mem_CopyMono	; copies monochrome tiles, specifically
				; (our ascii set is monochrome)


	ld	a, [rLCDC]
	or	LCDCF_ON
	ld	[rLCDC], a	; turn LCD back on


	; now lets copy some text onto the screen
	ld	hl, blank_line_text
	ld	de, _SCRN0
	ld	bc, 32	; copy 32 bytes starting at "blank_lines"
	call	mem_CopyVRAM

	ld	hl, hello_world_text
	ld	de, _SCRN0 + SCRN_VX_B	; screen + one full screen's width (in bytes)
	; means that DE points to 2nd row on-screen
	ld	bc, 32	; again, make a guess that we want to copy 32 bytes
	call	mem_CopyVRAM

; So -- why does this work? We really just type out characters and they appear
; on-screen? Yes... but let's go into details. Each character that we type is
; stored in-rom as a number corresponding to it's ascii value. And we've loaded
; tiles in VRAM whose tile# corresponds perfectly to ascii #'s. So there's a
; one-to-one match between text stored in-ROM and the character-tiles we've
; loaded into VRAM

.loop
	halt
	nop

	jp	.loop


; define a string as a sequence of bytes in ROM
; these sequences of bytes will correspond to background tiles representing
; the characters typed into this string. Which means that we can display
; ascii on-screen by simply copying the below bytes to address $9800 (_SCRN0)
blank_line_text:
	DB	"                             "
hello_world_text:
	DB	"        hello world!         "


; You can turn off LCD at any time, but it's bad for LCD if NOT done at vblank
lcd_Stop:
	ld	a, [rLCDC]	; LCD-Config
	and	LCDCF_ON	; compare config to lcd-on flag
	ret	z		; return if LCD is already off
.wait4vblank
	ldh	a, [rLY]   ; ldh is a faster version of ld if in [$FFxx] range
	cp	145  ; are we at line 145 yet?  (finished drawing screen then)
	jr	nz, .wait4vblank
.stopLCD
	ld	a, [rLCDC]
	xor	LCDCF_ON	; XOR lcd-on bit with lcd control bits. (toggles LCD off)
	ld	[rLCDC], a	; `a` holds result of XOR operation
	ret


ascii_tiles:
	chr_IBMPC1	1, 8	; spit out 256 ascii characters here in rom
				; (params 1, 8 specify we want all 256 chars)
ascii_tiles_end:


; ================ QUESTIONS FOR STUDENT ===========================
; Why does "hello world!" Appear so far to the left of the screen?
;	Can you correct that?
; What happens if you shorten the "      hello world!          " to just
;	"hello world!"?    (Once done -- Where did the visual junk come from?)
; Can you blank the entire screen?
