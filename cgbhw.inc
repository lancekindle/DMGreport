; the following are Color Game Boy specific hardware registers


    IF !DEF (CGBHW_INC)
CGBHW_INC   SET 1


; --
; -- KEY 1 ($FF4D)
; -- Select CPU Speed (R/W)
; --
rKEY1	EQU $FF4D


; --
; -- VBK ($FF4F)
; -- Select Video RAM Bank (R/W)
; --
; -- Write 0 or 1 to select VRAM bank 0 or 1, respectively
; -- VRAM Bank 0 holds tile and sprite data (the actual graphics)
; -- VRAM Bank 1 holds tile properties (sets priority, Yflip, Xflip, and
; -- color for corresponding tile data in bank 0)
; --
; -- Set properties in the following format:	pYX-bPPP
; -- (PPP) color palette: bits 0-2
; -- (b) character bank: bit 3 (gbc has another bank called chr bank??)
; -- (X) x flip: bit 5	(when 1, tile is flipped horizontally)
; -- (Y) y flip: bit 6	(when 1, tile is flipped vertically)
; -- (p) priority flag: bit 7	(when 1, ...display above sprites?)
; -- (REMEMBER, THE ABOVE BITS ARE FOR WRITING TO VRAM BANK 1 ($9800-...)
rVBK	EQU $FF4F
rVRAM_BANK	EQU $FF4F


; --
; -- HDMA1 ($FF51)
; -- Horizontal Blanking, General Purpose DMA (W)
; --
rHDMA1	EQU $FF51


; --
; -- HDMA2 ($FF52)
; -- Horizontal Blanking, General Purpose DMA (W)
; --
rHDMA2	EQU $FF52


; --
; -- HDMA3 ($FF53)
; -- Horizontal Blanking, General Purpose DMA (W)
; --
rHDMA3	EQU $FF53


; --
; -- HDMA4 ($FF54)
; -- Horizontal Blanking, General Purpose DMA (W)
; --
rHDMA4	EQU $FF54


; --
; -- HDMA5 ($FF55)
; -- Horizontal Blanking, General Purpose DMA (R/W)
; --
rHDMA5	EQU $FF55


; --
; -- RP ($FF56)
; -- Infrared Communications Port (R/W)
; --
rRP	EQU $FF56


; --
; -- BCPS ($FF68)
; -- Background Color Palette Specification (R/W)
; -- AKA Background Colors Index. Allows you to change colors.
; -- Write to this to set which color / palette you'd like to R/W from.
;	(using rBCPD)
; -- Bit 7 - specifies autoincrement (1) or not (0). If set, will
;	increment to next index on write.
; -- Bits 5-3 - specify the palette #
; -- Bits 2-1 - Specifies the palette data/color #
; -- Bit 0 - Specifies H/L (H:1, L:0) of Red, Green, or Blue data
; -- Low-byte contains	%GGGRRRRR
; -- High-byte contains %xBBBBBGG
; --
; -- So... There are a total of 8 palettes. Specify which one you'd like
;	to R/W by setting bits 5-3 appropriately.
; -- There are a total of 4 colors per palette. Specify which color you'd
;	like to R/W by settings bits 2-1.
; -- It takes two bytes to set each color. Each color is RGB, range of 0-31
;	Red: bits 0-4, Green: bits 5-9, Blue: bits 10-14 (bit 15 ignored)
; --
rBCPS	EQU $FF68


; --
; -- BCPD ($FF69)
; -- Background Color Palette Data (R/W)
; -- R/W the color(s) of a palette (index) specified by rBCPS.
; -- To write a full palette, write 1 color at a time, 2 bytes per color
; -- in this format: %xBBBBBGG GGGRRRRR, where you write the low byte first
; -- (low-byte, in this case, refers to %xBBBBBGG).
; -- after you've written 4 colors (8 bytes), a full palette has been
; -- specified. To use these colors, you'll have to set the color-pointer in
; -- VRAM bank 1 at the same location as the corresponding tile in VRAM Bank 0
; -- See rVRAM_BANK for details
; --
rBCPD	EQU $FF69


; --
; -- BCPS ($FF6A)
; -- Object Color Palette Specification (R/W)
; --
rOCPS	EQU $FF6A


; --
; -- BCPD ($FF6B)
; -- Object Color Palette Data (R/W)
; --
rOCPD	EQU $FF6B


; --
; -- SVBK ($FF70)
; -- Select Main RAM Bank (R/W)
; --
rSVBK	EQU $FF70


    ENDC    ; end CGBHW defines
