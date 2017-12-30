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
	call	mem_CopyVRAM

	ld	a, [rLCDC]
	or	LCDCF_ON
	ld	[rLCDC], a	; turn LCD back on

	ld	a, %00000001
	ld	[rBGP], a	; set background pallette

	; enable vblank so that palette changes can work
	ld	a, IEF_VBLANK
	ld	[rIE], a


.loop
	halt
	nop

	add	7
	jr	nc, .loop	; when A overflows, we execute instructions below

	ld	hl, rBGP	; HL points to background palette
	rlc	[hl]
	rlc	[hl]

	jp	.loop



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


; it's necessary to use a macro to generate characters. That way we can use
; custom characters to represent the 4 shades of grey
; (otherwise we'd have to use 0,1,2,3)
chr_custom: MACRO
	PUSHO	; push compiler options so that I can change the meaning of
	; 0,1,2,3 graphics to something better. Like  .-*@
	; change graphics characters. Start the line with ` (for graphics)
	; . = 00
	; - = 01
	; * = 10
	; @ = 11
	OPT	g.~*@

        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@
        DW      `..~~**@@

	POPO	; restore compiler options


	ENDM


ascii_tiles:
	chr_custom
ascii_tiles_end:


; ================ QUESTIONS FOR STUDENT ===========================
; Can you speed up the animation?
; What is causing those lines to move? Are we actually moving the background?
; Why do we "RLC [HL]" twice? What happens if we do it just once? Why?
;	(hint) what does [HL] point to? How is that used?
;	(x2 hint) how many bits represet each color?
; How many pixels do the lines move each iteration? (hint: see custom graphic)
; Move the background in sync such that the lines don't move, but the logo does.
