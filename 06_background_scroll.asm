include "gbhw.inc"

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

; Vertical-blank triggers each time the screen finishes drawing. Video-RAM
; (VRAM) is only available during VBLANK. So this is when updating OAM /
; sprites is executed.
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

; safe to include other files begining here. INCLUDE'd files often immediately
; add more code to the compiled ROM. It's critical that your code does not
; step over the first $0000 - $014E bytes


code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM
; background image is just the nintendo logo. Tile 0x19 is the (R).

	ld	a, IEF_VBLANK	; --
	ld	[rIE], a	; Set only Vblank interrupt flag
	ei			; enable interrupts. Only vblank will trigger


	ld	a, [rLCDC]	; fetch LCD Config. (Each bit is a flag)
	or	LCDCF_OBJON	; enable sprites through "OBJects ON" flag
	or	LCDCF_OBJ8	; enable 8bit wide sprites (vs. 16-bit wide)
	ld	[rLCDC], a	; save LCD Config. Sprites are now visible. 

.loop
	halt	; halts cpu until interrupt triggers (vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop


	ld	a,b
	ld	[rSCX],a
	inc	a
	ld	b,a

	jp	.loop		; start up at top of .loop label. Repeats each vblank

; ================ QUESTIONS FOR STUDENT ===========================
; why is there visual junk on the screen?
; why does the visual junk on-screen NOT move, while the background does?
; what happens if you remove the "halt" command in the .loop? Why?
