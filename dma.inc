
	IF !DEF(DMA_INC)
	; don't re-include this file if it's already been INCLUDE'd
DMA_INC = 1


DMA_ROUTINE	= $FF80


dma_Copy2HRAM: MACRO
	IF !DEF(MEMORY_ASM)
	FAIL "include memory.asm before you use the dma_Copy2HRAM macro"
	ENDC
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
	; copies BC # of bytes from source (HL) to destination (DE)
	call	mem_Copy
	ENDM






	ENDC	; end definition of DMA.inc file
