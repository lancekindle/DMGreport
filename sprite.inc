; hello-sprite.inc
; definitions used in hello-sprite.asm
; updates:
;  2008-03-23: added conditional so it is not interpreted by the assembler 2x


        IF      !DEF(SPRITE_INC)
SPRITE_INC  SET  1

OAMDATALOC	EQU	_RAM				; must be multiple of $100
OAMDATALOCBANK	EQU	OAMDATALOC/$100 
OAMDATALENGTH	EQU	$A0

		printt  "From Sprite.inc\n"
		printv	OAMDATALOCBANK
		printt	"\n"
		
		RSSET	OAMDATALOC
sprite_RS	SET OAMDATALOC

; RSSET and RB are macros / compiler stuff that increments a value called _RS
; so let's talk about _RS. It's a compiler-tracked byte. (max value of 255)
; RSSET 100        ; sets the _RS value to 100
; X		RB  25     ; sets X to 100 (current value of _RS) then adds 25 to _RS
; Y		RB  14     ; sets Y to 125 (current value of _RS) then adds 14 to _RS

; since SpriteAttr is called right after __RS is set to OAMDATALOC,
; then RB 1 is assigning an OAMDATA location to each value and then
; incrementing __RS, Thus giving Y, X Addr, Tilenum, & Flags a unique OAM data
; location.
SpriteAttr:	MACRO
	RSSET	sprite_RS
\1_YAddr		RB	1
\1_XAddr		RB	1
\1_TileNum	RB	1
\1_Flags		RB	1
sprite_RS	SET	_RS  ; keep backup of _RS, because _RS will change
		ENDM

; change tile. This will swap the graphic with which the sprite is drawn
sprite_PutTile: MACRO
	ld	a, \2
	ld	[\1_TileNum], a
	ENDM

; get current tile of sprite
sprite_GetTile: MACRO
	ld	a, [\1_TileNum]
	ENDM

; change flags. This will set the full flags-byte. Flags include properties:
; palette#, Xflip, Yflip, priority, etc...
sprite_PutFlags: MACRO
	ld	a, \2
	ld	[\1_Flags], a
	ENDM

sprite_GetFlags: MACRO
	ld	a, [\1_Flags]
	ENDM

;set XAddr of sprite.
;format:
;	PutSpriteXAddr	SpriteName,r8
;	PutSpriteXAddr	SpriteName,n8
PutSpriteXAddr:	MACRO
		push	af
		ld	a,\2
		add	8	
		ld	[\1_XAddr], a
		pop	af
		ENDM

;set YAddr of sprite.
;format:
;	PutSpriteYAddr	SpriteName,r8
;	PutSpriteYAddr	SpriteName,n8
PutSpriteYAddr:	MACRO
		push	af
		ld	a,\2
		add	16	
		ld	[\1_YAddr], a
		pop	af
		ENDM

GetSpriteXAddr:	MACRO
		ld	a,[\1_XAddr]
		sub	8
		ENDM

GetSpriteYAddr:	MACRO
		ld	a,[\1_YAddr]
		sub	16
		ENDM

MoveLeft: MACRO
	; move sprite (\1) to the left by x (\2)
	GetSpriteXAddr \1  ; ld x into a
	sub \2
	PutSpriteXAddr \1, a
	ENDM

MoveRight: MACRO
	; move sprite (\1) to the right by x (\2)
	GetSpriteXAddr \1  ; ld x into a
	add \2
	PutSpriteXAddr \1, a
	ENDM

MoveUp: MACRO
	; move sprite (\1) upwards by y (\2)
	GetSpriteYAddr \1  ; ld y into a
	sub \2
	PutSpriteYAddr \1, a
	ENDM

MoveDown: MACRO
	; move sprite (\1) downwards by y (\2)
	GetSpriteYAddr \1  ; ld y into a
	add \2
	PutSpriteYAddr \1, a
	ENDM

MoveIfLeft: MACRO
	; ld keys in a, and pass spriteName as argument
	; IF Left key was pressed, will move left by second argument
	push af
	and PADF_LEFT
	jr z, .skipLeft\@  ; return (do nothing) if left was not pressed
	MoveLeft \1, \2
.skipLeft\@
	pop af
	ENDM

MoveOnceIfLeft: MACRO
	; only moves once per depressed key. Waits for key to be released
	; and then re-pressed to move again
	if_not	jpad_EdgeLeft,		jr .skipOnceLeft\@
	MoveLeft \1, \2
.skipOnceLeft\@
	ENDM

MoveOnceIfRight: MACRO
	; only moves once per depressed key. Waits for key to be released
	; and then re-pressed to move again
	if_not	jpad_EdgeRight,		jr .skipOnceRight\@
	MoveRight \1, \2
.skipOnceRight\@
	ENDM

MoveOnceIfUp: MACRO
	; only moves once per depressed key. Waits for key to be released
	; and then re-pressed to move again
	if_not	jpad_EdgeUp,		jr .skipOnceUp\@
	MoveUp \1, \2
.skipOnceUp\@
	ENDM

MoveOnceIfDown: MACRO
	; only moves once per depressed key. Waits for key to be released
	; and then re-pressed to move again
	if_not	jpad_EdgeDown,		jr .skipOnceDown\@
	MoveDown \1, \2
.skipOnceDown\@
	ENDM

MoveRepeatIfLeft: MACRO
	; moves every ~1/3rd of a second while left is pressed
	push af
	and PADF_LEFT
	jr nz, .leftHeld\@
.resetOnceLeft\@
	ld a, 0
	ld [var_LEFT], a
	jr .skipOnceLeft\@
.leftHeld\@
	ld a, [var_LEFT]
	add $10
	ld [var_LEFT], a		; store var_LEFT
	cp $10
	jr nz, .skipOnceLeft\@   ; if [var_LEFT] != $10, then we already pressed LEFT
	MoveLeft \1, \2
.skipOnceLeft\@
	pop af
	ENDM

MoveIfRight: MACRO
	; ld keys in a, and pass spriteName as argument
	; IF Right key was pressed, will move right by second argument
	push af
	and PADF_RIGHT
	jr z, .skipRight\@  ; return (do nothing) if key was not pressed
	GetSpriteXAddr \1
	add \2
	PutSpriteXAddr \1, a
.skipRight\@
	pop af
	ENDM

MoveIfUp: MACRO
	; ld keys in a, and pass spriteName as argument
	; IF Up key was pressed, will move right by second argument
	push af
	and PADF_UP
	jr z, .skipUp\@  ;do nothing if key was not pressed
	GetSpriteYAddr \1
	sub \2
	PutSpriteYAddr \1, a
.skipUp\@
	pop af
	ENDM

MoveIfDown: MACRO
	; ld keys in a, and pass spriteName as argument
	; IF Down key was pressed, will move right by second argument
	push af
	and PADF_DOWN
	jr z, .skipDown\@ ; return (do nothing) if key was not pressed
	GetSpriteYAddr \1
	add \2
	PutSpriteYAddr \1, a
.skipDown\@
	pop af
	ENDM


IfLeft: MACRO
	push af
	AND PADF_LEFT
	jr z, .skipIfLeft\@
	run_2nd_arg_cmd
@.skipIfLeft\@
	pop af
	ENDM

		ENDC			; HELLO_SPRITE_INC
