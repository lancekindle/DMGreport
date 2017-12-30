include "gbhw.inc"

include "dma.inc"		; allows us to use dma_Copy2HRAM macro
include "sprite.inc"		; gives us spr_* macros to modify all sprites

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

	SpriteAttr	copyright	; declare "copyright" as a sprite

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


	; see where we declare "copyright" as a sprite-variable above
	; set X=20, Y=10, Tile=$19, Flags=0
	PutSpriteXAddr	copyright, 20
	PutSpriteYAddr	copyright, 10
	sprite_PutTile	copyright, $19
	sprite_PutFlags	copyright, $00


.loop
	halt	; halts cpu until interrupt triggers (vblank)
 	; by halting, we ensure that .loop only runs only each screen-refresh,
	; so only 60fps. That makes the sprite movement here manageable
	nop

	call	jpad_GetKeys

	; move character if corresponding button has been pushed
	push	af	; save register A (joypad info)
	and	PADF_UP	; compare joypad info. Set NZ flag if UP bit present
	jr	z, .skip_up
	GetSpriteYAddr	copyright
	dec	A
	PutSpriteYAddr	copyright, a
.skip_up
	pop	af	; restore register A (joypad info)
	push	af	; save (again) reg. A
	and	PADF_DOWN
	jr	z, .skip_down
	GetSpriteYAddr	copyright
	inc	A
	PutSpriteYAddr	copyright, a
.skip_down
	pop	af
	push	af
	and	PADF_LEFT
	jr	z, .skip_left
	GetSpriteXAddr	copyright
	dec	A
	PutSpriteXAddr	copyright, a
.skip_left
	pop	af
	push	af
	and	PADF_RIGHT
	jr	z, .skip_right

	GetSpriteXAddr	copyright
	inc	A
	PutSpriteXAddr	copyright, a
.skip_right
	pop	af

	jp	.loop		; start up at top of .loop label. Repeats each vblank


jpad_GetKeys:
; Uses AF, B
; get currently pressed keys. Register A will hold keys in the following
; order: MSB --> LSB (Most Significant Bit --> Least Significant Bit)
; Down, Up, Left, Right, Start, Select, B, A
; This works by writing

	; get action buttons: A, B, Start / Select
	ld	a, JOYPAD_BUTTONS; choose bit that'll give us action button info
	ld	[rJOYPAD], a; write to joypad, telling it we'd like button info
	ld	a, [rJOYPAD]; gameboy will write (back in address) joypad info
	ld	a, [rJOYPAD]
	cpl		; take compliment
	and	$0f	; look at first 4 bits only  (lower nibble)
	swap	a	; place lower nibble into upper nibble
	ld	b, a	; store keys in b
	; get directional keys
	ld	a, JOYPAD_ARROWS
	ld	[rJOYPAD], a ; write to joypad, selecting direction keys
	ld	a, [rJOYPAD]
	ld	a, [rJOYPAD]
	ld	a, [rJOYPAD]	; delay to reliablly read keys
	ld	a, [rJOYPAD]	; since we've just swapped from reading
	ld	a, [rJOYPAD]	; buttons to arrow keys
	ld	a, [rJOYPAD]
	cpl			; take compliment
	and	$0f		; keep lower nibble
	or	b		; combine action & direction keys (result in a)
	ld	b, a

	ld	a, JOYPAD_BUTTONS | JOYPAD_ARROWS
	ld	[rJOYPAD], a		; reset joypad

	ld	a, b	; register A holds result. Each bit represents a key
	ret

; ================ QUESTIONS FOR STUDENT ===========================
; Use the Arrow keys. The character moves!
