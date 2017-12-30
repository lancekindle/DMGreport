include "gbhw.inc"	; wealth of gameboy hardware & addresses info

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

; Vertical-blank triggers each time the screen finishes drawing. Draw-To-Screen
; routines happen here because Video-RAM is only available during vblank*
SECTION "Vblank", ROM0[$0040]
	reti

; LCDC interrupts are LCD-specific interrupts (not including vblank) such as
; interrupting when the gameboy draws a specific horizontal line on-screen
SECTION "LCDC", ROM0[$0048]
	reti

; Timer interrupt is triggered when the timer, rTIMA, ($FF05) overflows.
; rDIV, rTIMA, rTMA, rTAC all control the timer.
SECTION "Timer", ROM0[$0050]
	reti

; Serial interrupt occurs after the gameboy transfers a byte through the
; gameboy link cable.
SECTION "Serial", ROM0[$0058]
	reti

; Joypad interrupt occurs after a button has been pressed. Usually we don't
; enable this, and instead poll the joypad state each vblank
SECTION "Joypad", ROM0[$0060]
	reti
;----------- END INTERRUPT VECTORS -------------------
; QUESTION TO STUDENT -- How many bytes separate each interrupt vector?


SECTION "ROM_entry_point", ROM0[$0100]	; ROM is given control from boot here
	nop
	jp	code_begins


;------------- BEGIN ROM HEADER ----------------
; The gameboy reads this info (before handing control over to ROM)
;* macro calls (such as NINTENDO_LOGO) MUST be indented to run
SECTION "rom header", ROM0[$0104]
	NINTENDO_LOGO	; add nintendo logo. Required to run on real hardware
	ROM_HEADER	"0123456789ABCDE"

; safe to include other files here. INCLUDE'd files often immediately add more
; code to the compiled ROM. It's critical that your code does not step over
; the first $0000 - $014E bytes

code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM
.loop
	halt	; halts cpu until interrupt triggers
	nop
	jp	.loop
; QUESTION TO STUDENT: when run, this example displays Nintendo's logo. How?
;	(hint) when run on a CGB it shows nothing; on a DMG, the logo appears.
