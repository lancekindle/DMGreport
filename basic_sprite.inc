
	IF !DEF(EASY_SPRITE_INC)
	; don't re-include if sprite.inc already INCLUDE'd
EASY_SPRITE_INC = 1



OAMDATALOC	= _RAM	; set first 160 bytes of RAM to hold OAM variables
OAMDATALOCBANK	= OAMDATALOC / $100 ; used by DMA_ROUTINE to point to _RAM


; set first sprite's properties (at $C000)
; these macros are for demo-ing only. The normal method is to declare a sprite
; with spr_Declare <sprite name> and then use spr_SetX, spr_GetY, etc...
spr_Setup1stSprite: MACRO
	push	af
	push	hl
	ld	hl, OAMDATALOC
	ld	[hl], \1	; set X coordinate
	inc	hl
	ld	[hl], \2	; set Y coordinate
	inc	hl
	ld	[hl], \3	; set Tile #
	inc	hl
	ld	[hl], \4	; set flags (default of 0 works)
	pop	hl
	pop	af
	ENDM

; set first sprite's X,y coordinates
spr_Set1stSpriteX: MACRO
	ld	a, \1	; load X into A
	ld	[OAMDATALOC], a
	ENDM

spr_Set1stSpriteY: MACRO
	ld	a, \1
	ld	[OAMDATALOC + 1], a
	ENDM


; get first sprite's X, Y coordinates
spr_Get1stSpriteX: MACRO
	ld	a, [OAMDATALOC]
	ENDM

spr_Get1stSpriteY: MACRO
	ld	a, [OAMDATALOC + 1]
	ENDM



	ENDC	; end sprite.inc inclusion
