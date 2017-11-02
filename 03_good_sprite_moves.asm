include "gbhw.inc"

DMA_ROUTINE	= $FF80
OAMDATALOC	= _RAM	; set first 160 bytes of RAM to hold OAM variables
OAMDATALOCBANK	= OAMDATALOC / $100 ; used by DMA_ROUTINE to point to _RAM

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
	ROM_HEADER	"first dma usage"


dma_Copy2HRAM: MACRO
; copies the dmacode to HIRAM. dmacode will get run each Vblank,
; and it is resposible for copying sprite data from ram to vram.
; dma_Copy2HRAM trashes all registers
; actual dma code preserves all registers
	jr	.copy_dma_into_memory\@
.dmacode\@
	push	af
	ld	a, OAMDATALOCBANK
	ldh	[rDMA], a
	ld	a, $28 ; countdown until DMA is finishes, then exit
.dma_wait\@			;<-|
	dec	a		;  |	keep looping until DMA finishes
	jr	nz, .dma_wait\@ ; _|
	pop	af
	reti	; if this were jumped to by the v-blank interrupt, we'd
		; want to reti (re-enable interrupts).
.dmaend\@
.copy_dma_into_memory\@
	ld	de, DMA_ROUTINE
	ld	hl, .dmacode\@
	ld	bc, .dmaend\@ - .dmacode\@
; mem_Copy copied from memory.asm for this example
; copies BC # of bytes from source (HL) to destination (DE)
.mem_Copy\@
	inc	b
	inc	c
	jr	.skip\@
.loop\@	ld	a,[hl+]
	ld	[de],a
	inc	de
.skip\@	dec	c
	jr	nz,.loop\@
	dec	b
	jr	nz,.loop\@
	ENDM


code_begins:
	di	; disable interrupts
	ld	SP, $FFFF	; set stack to top of HRAM

	dma_Copy2HRAM	; routine that updates sprites for us

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
; DMA_ROUTINE called each vblank now handles moving data data starting at
; _RAM ($C000) into $FE00. So now we write sprite data at $C000
; There are a total of 40 sprites available to manipulate.
; Each sprite has 4 attributes that are set in sequential bytes in memory:
;	X coordinate
;	Y coordinate
;	Tile #  (relative to start of tiles in VRAM: $8000)
;	Sprite Flags  (such as, visible, priority, X & Y flip)

	ld	hl, _RAM	; point to 1st sprite's 1st property: X
	ld	[hl], 20	; set X to 20
	inc	hl		; HL points to sprite's Y
	ld	[hl], 10	; set Y to 10
	inc	hl		; HL points to sprite's tile (from BG map)
	ld	[hl], $19	; set Tile to the (R) graphic
	inc	hl		; HL points to sprite's flags
	ld	[hl], 0		; set all flags to 0. X,Y-flip, palette, etc.


.loop
	halt	; halts cpu until interrupt triggers (vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop

	ld	hl, _RAM	; HL points to X coordinate
	ld	a, [hl]
	inc	a		; X += 1
	ld	[hl], a		; save new X coordinates
	inc	hl		; HL points to Y coordinate
	inc	[hl]		; set Y += 1

	jp	.loop		; start up at top of .loop label. Repeats each vblank

; =============================================================
; ----------- (In Depth) So what does DMA do? -----------------
; =============================================================
; DMA (on the original gameboy) is a specific memory-copying routine
; that is 2x+ faster at copying memory from a specified source to a
; hard-coded destination of $FE00-$FE9F (where OAM resides).
; because sprites / objects depend on OAM manipulation, we write to
; OAM all throughout game logic. Except there's a catch: OAM is
; inaccessible a lot due to the LCD drawing routine. So almost every
; game sets aside 160 bytes in normal RAM that they write to. Then,
; every Vertical-Blank (when OAM is accessible), we initiate DMA to
; copy the 160 bytes from RAM into OAM. The value we write to [rDMA]
; is the MSB version of the source address. If we write $C0,
; then DMA copies 160 bytes from $C000 into OAM.
; while DMA performs it's copying routine, the cpu is still active,
; but unable to access the ROM, or any other memory aside from HRAM.
; That's why this routine gets copied into HRAM and performs a
; for-loop before exiting. It's timed so that DMA is complete when
; it exits. In this case, DMA takes 162 Machine Cycles.
