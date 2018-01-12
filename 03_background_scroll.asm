include "gbhw.inc"

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

; Vertical-blank triggers each time the screen finishes drawing. Video-RAM
; (VRAM) is only available during VBLANK. So this is when updating OAM /
; sprites is executed.
SECTION "Vblank", ROM0[$0040]
	reti

; there are 5 more interrupts not shown, since they won't be used in this
; example. But it's good practice to include them with a reti
;----------- END INTERRUPT VECTORS -------------------

SECTION "ROM_entry_point", ROM0[$0100]	; ROM is given control from boot here
	nop
	jp	code_begins

;------------- BEGIN ROM HEADER ----------------
; The gameboy reads this info (before handing control over to ROM)
SECTION "rom header", ROM0[$0104]
	NINTENDO_LOGO
	; we moved the large sequence of DB into a macro called ROM_HEADER
	ROM_HEADER	"Cart Name Here "

code_begins:
	; background image is just the nintendo logo. Tile 0x19 is the (R).

	ld	a, IEF_VBLANK	; --
	ld	[rIE], a	; Set only Vblank interrupt flag
	ei	; enable interrupts, so that vblank triggers

.loop
	halt	; halts cpu until interrupt triggers (vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the background movement here manageable
	nop

	ld	a, [rSCX]
	inc	a
	ld	[rSCX], a

	jp	.loop		; start up at top of .loop label. Repeats each vblank

; ================ QUESTIONS FOR STUDENT ===========================
; what happens if you remove the "halt" command in the .loop? Why?
