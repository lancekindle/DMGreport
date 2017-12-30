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
	ROM_HEADER	"0123456789ABCDE"

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

.loop
	halt
	nop

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


ascii_tiles:
	chr_IBMPC1	1, 8	; spit out 256 ascii characters here in rom
				; (params 1, 8 specify we want all 256 chars)

; ending label (ascii_tiles_end) gives us a memory address that we can use in
; mem_Copy* routine. Since we need both starting and ending memory addresses
; in order to calculate number of bytes to copy (stored in register-pair BC)
ascii_tiles_end:


; ================ QUESTIONS FOR STUDENT ===========================
; Why are there boxes all over the screen, but other characters in the middle?
;	(hint) the nintendo logo used to be there...
; Compare to the previous example -- which Tile# is blank now VS then?
