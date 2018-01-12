; semicolon precedes comments (this is a comment, for example)
include "gbhw.inc"	; holds references (variables) to many gameboy-specific
			; memory addresses and game-logic

;----------- ROM ENTRY POINT ----------------

SECTION "ROM_entry_point", ROM0[$0100]	; ROM is given control from boot here
	nop
	jp	code_begins

;------------- BEGIN ROM HEADER ----------------
; The gameboy reads this info (before handing control over to ROM)
SECTION "rom header", ROM0[$0104]
	NINTENDO_LOGO	; nintendo logo is required here or gameboy will lock

; ROM HEADER BELOW HERE (info checked by gameboy before handing control of
; gameboy over to ROM)
; DB stands or "Define Byte" -- we tell RGBDS (the compiler) to store the
; following sequence of characters / numbers on a byte-by-byte basis
 DB "Cart Name Here " ; Cart name - 15 characters / 15 bytes
 DB 0                         ; $143 - GBC support. $80 = both. $C0 = only gbc
 DB 0,0                       ; $144 - Licensee code (not important)
 DB 0                         ; $146 - SGB Support indicator
 DB 0                         ; $147 - Cart type / MBC type (0 => no mbc)
 DB 0                         ; $148 - ROM Size (0 => 32KB)
 DB 0                         ; $149 - RAM Size (0 => 0KB RAM on cartridge)
 DB 1                         ; $14a - Destination code
 DB $33                       ; $14b - Old licensee code
 DB 0                         ; $14c - Mask ROM version
 DB 0                         ; $14d - Complement check (important) rgbds-fixed
 DW 0                         ; $14e - Checksum (not important)


code_begins:
	di	; disable interrupts
	; background image is just the nintendo logo. Tile 0x19 is the (R).

.loop_until_line_144
	ld	a, [rLY]	; get lcd line number (which line# is drawn)
	; Search rLY within gbhw.inc to learn more about rLY
	cp	144
	jp	nz, .loop_until_line_144
.loop_until_line_145
	ld	a, [rLY]
	cp	145
	jp	nz, .loop_until_line_145


	ld	a, [rSCX]	; "Scroll-X" search gbhw.inc to learn more
	inc	a
	ld	[rSCX], a

	jp	.loop_until_line_144	; jump to '.loop...' label above

; ================ QUESTIONS FOR STUDENT ===========================
; can you make the background scroll the other way? What about up / down?
;	(hint) search rSCY within gbhw.inc
