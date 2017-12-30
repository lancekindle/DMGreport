include "gbhw.inc"

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

; Vertical-blank triggers each time the screen finishes drawing. Video-RAM
; (VRAM) is only available during VBLANK. So this is when updating OAM /
; sprites is executed.
SECTION "Vblank", ROM0[$0040]
	jp	vblank_handler

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

	ld	a, IEF_VBLANK | IEF_LCDC
	ld	[rIE], a	; enable VBLANK and LCDC (for horizontal blank)

	ld	a, STATF_MODE00	; horizontal blank interrupt flag
	ld	[rSTAT], a	; throw interrupt during HBLANK on LCDC


	; preload rSCY into HL, 0 into A, set carry flag
	ld	hl, rSCY
	xor	a
	SCF	; sets carry flag. Since we do nothing else with it, we can
		; use it to toggle between repeating a horizontal line by
		; decrementing rSCY

	ei			; enable interrupts.

.loop
	halt	; halts cpu until interrupt triggers (Hblank & Vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop

	CCF	; Complement Carry-Flag (toggle it)
	; this has the effect of causing the LCD to draw the same rSCY line
	; twice, thus causing a stretch effect
	jr	nc, .do_normal_line
	dec	[hl]
.do_normal_line

	jp	.loop		; start up at top of .loop label. Repeats each vblank

vblank_handler:
	ld	a, 45
	ld	[hl], a	; reset rSCY to 45
	reti

; ================ QUESTIONS FOR STUDENT ===========================
; Why do we reset the rSCY line number to 45 every Vblank?
;	(hint) at which line--SCY--does the nintendo logo appear?
; Why is the logo vibrating up and down like that?
;	(hint) some internal state is not resetting each screen redraw
;	Modify the code so that the logo is stationary. (possible w/ 1 opcode)
; Can you make it so that the stretched logo also scrolls down?
; Can you make it such that the logo scrolls left?
