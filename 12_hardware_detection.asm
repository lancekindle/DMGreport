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

 ; ROM HEADER (included in full this time)
 DB "hardware detect" ; Cart name - 15bytes


; =============== TRY CHANGING GBC BYTE HERE ==================
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

include "debug.inc"	; supplies the bug_message macro to display message
			; within BGB's debug window AND output msg string to
			; debugmsg.txt if enabled within BGB's .ini config

code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM
	cp	$11	; register A holds $11 if its CGB or GBA
	jp	nz, .dmg_loop
	ld	a, b
	bit	0, b	; Bit 0 of register B is 0 if CGB, 1 if GBA
	jp	z, .cgb_loop
	jp	.gba_loop

.dmg_loop
	bug_message	"it's an original gameboy"
	halt
	nop

	jp	.dmg_loop
.cgb_loop
	bug_message	"it's a color gameboy!"
	halt
	nop

	jp	.cgb_loop
.gba_loop
	bug_message	"it's a gameboy advanceh"
	halt
	nop

	jp	.gba_loop


; ================ QUESTIONS FOR STUDENT ===========================
; Notice that the "Nintendo" logo no longer appears on-screen. Why?
;	What happened to the logo? Did it get erased, was the background
;	changed to only invisible tiles, or did the palette change?
;	Open BGB's VRAM viewer to find out.
; What happens if you change the header's GBC support byte to 0?... or $C0?
; Open up BGB's debug window by pressing [ESC]. Based on which instruction
;	is executing, can you tell which hardware BGB is emulating?
