include "gbhw.inc"

include "dma.inc"		; allows us to use dma_Copy2HRAM macro
include "basic_sprite.inc"	; gives us spr_* macros to modify 1st sprite

;-------------- INTERRUPT VECTORS ------------------------
; specific memory addresses are called when a hardware interrupt triggers

; Vertical-blank triggers each time the screen finishes drawing. Video-RAM
; (VRAM) is only available during VBLANK. So this is when updating OAM /
; sprites is executed.
SECTION "Vblank", ROM0[$0040]
	JP	DMA_ROUTINE

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
	ROM_HEADER	"macro and dma  "

; here's where you can include additional .asm modules
include "memory.asm"


code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM

	dma_Copy2HRAM	; sets up routine from dma.inc that updates sprites

	ld	a, IEF_VBLANK	; --
	ld	[rIE], a	; Set only Vblank interrupt flag
	ei			; enable interrupts. Only vblank will trigger

	ld	a, [rLCDC]	; fetch LCD Config. (Each bit is a flag)
	or	LCDCF_OBJON	; enable sprites through "OBJects ON" flag
	or	LCDCF_OBJ8	; enable 8bit wide sprites (vs. 16-bit wide)
	ld	[rLCDC], a	; save LCD Config. Sprites are now visible. 

	; don't need to wait for vblank since DMA_routine is now called
	; automatically when that happens

; ----
; DMA_ROUTINE is called each vblank now handles moving data data starting at
; _RAM ($C000) into $FE00. So now we write sprite data at $C000
; There are a total of 40 sprites available to manipulate.
; Each sprite has 4 attributes that are set in sequential bytes in memory:
;	X coordinate
;	Y coordinate
;	Tile #  (relative to start of tiles in VRAM: $8000)
;	Sprite Flags  (such as, visible, priority, X & Y flip)

	; set X=20, Y=10, Tile=$19, Flags=0
	spr_Setup1stSprite	20, 10, $19, 0


.loop
	halt	; halts cpu until interrupt triggers (vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop

	spr_Get1stSpriteX
	inc	A
	spr_Set1stSpriteX	A

	spr_Get1stSpriteY
	inc	A
	spr_Set1stSpriteY	A

	jp	.loop		; start up at top of .loop label. Repeats each vblank
