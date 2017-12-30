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
; You can find it on BGB's VRAM Tiles: (right-click) -> other -> VRAM -> Tiles
; Let's use the (R) as a sprite and move it


	ld	a, IEF_VBLANK	; --
	ld	[rIE], a	; Set only Vblank interrupt flag
	ei			; enable interrupts. Only vblank will trigger


	halt	; wait a frame
	nop
	halt
	nop	; wait two frames before pushing bytes -- critical timing here
	; if we mess up timing, writes to OAM will fail. Thus the sprite will
	; NOT be updated. Try removing these two halts to see what happens.


; ----
; OAM aka Sprite memory on the gameboy begins at memory address $FE00.
; There are a total of 40 sprites available to manipulate.
; Each sprite has 4 attributes that are set in sequential bytes in memory:
;	X coordinate
;	Y coordinate
;	Tile #  (relative to start of tiles in VRAM: $8000)
;	Sprite Flags  (such as, visible, priority, X & Y flip)

	ld	hl, _OAMRAM	; point to 1st sprite's 1st property: X
	ld	[hl], 20	; set X to 20
	ld	hl, _OAMRAM + 1 ; HL points to sprite's Y
	ld	[hl], 10	; set Y to 10
	ld	hl, _OAMRAM + 2 ; HL points to sprite's tile (from BG map)
	ld	[hl], $19	; set Tile to the (R) graphic
	ld	hl, _OAMRAM + 3	; HL points to sprite's flags
	ld	[hl], 0		; set all flags to 0. X,Y-flip, palette, etc.

	ld	a, [rLCDC]	; fetch LCD Config. (Each bit is a flag)
	or	LCDCF_OBJON	; enable sprites through "OBJects ON" flag
	or	LCDCF_OBJ8	; enable 8bit wide sprites (vs. 16-bit wide)
	ld	[rLCDC], a	; save LCD Config. Sprites are now visible. 

.loop
	halt	; halts cpu until interrupt triggers (vblank)
	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop

	ld	hl, _OAMRAM
	ld	a, [hl]
	inc	a		; X += 1
	ld	[hl], a		; save new X coordinates
	ld	hl, _OAMRAM + 1
	inc	[hl]		; set Y += 1

	jp	.loop		; start up at top of .loop label. Repeats each vblank

; ================ QUESTIONS FOR STUDENT ===========================
; why is there visual junk on the screen?
;	(hint) are these displaying on the background tiles? (use bgb to view)
; can you change this so that Y moves twice as fast as X?
; can you change this so that sprite moves half as fast?
; what happens if you remove the "halt" command in the .loop? Why?
