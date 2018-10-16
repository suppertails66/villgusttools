
;.include "sys/pce_arch.s"
;.include "base/macros.s"

.memorymap
   defaultslot     1
   
   ;===============================================
   ; RAM area
   ;===============================================
   
   slotsize        $800
   slot            0       $0000
   slotsize        $2000
   slot            1       $6000
   
   ;===============================================
   ; ROM area
   ;===============================================
   
   slotsize        $2000
   slot            2       $8000
   slot            3       $A000
   slotsize        $2000
   slot            4       $C000
   slot            5       $E000
.endme

.rombankmap
  bankstotal 32
  banksize $2000
  banks 32
.endro

.emptyfill $FF

.background "villgust.nes"

; unbackground expanded ROM space
.unbackground $20000 $3BFFF

; unbackground free space at end of banks
.unbackground $BEAC $BFFF
.unbackground $3FD68 $3FF4D

.define PPUCTRL $2000
.define PPUMASK $2001
.define PPUSTATUS $2002
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014

;===============================================
; Constants
;===============================================

.define upperChrBankLo $0038
.define upperChrBankHi $0039
.define prgBankLo $0040
.define prgBankHi $0041

.define expTextBuf $6F00


  ;======
  ; NEW
  ;======

  ; top bit = set if two-line
  .define twoLineFlag $00E8
  .define twoTermFlag $00E9

;===============================================
; Existing routines
;===============================================

.define useRtsJumpTable $C19E
.define switchPrg $C1D5
.define switchChr $C366
.define saveAndSwitchPrg $C295

;===============================================
; New script
;===============================================

; CHR bank $B8
.bank $10 slot 3
.org $0000
.section "new script 1" overwrite
  newScript4E000:
    .include "out/script/maps/script4E000.inc"
.ends

; CHR bank $BC
.bank $11 slot 3
.org $0000
.section "new script 2" overwrite
  newScript4F000:
    .include "out/script/maps/script4F000.inc"
.ends

; CHR bank $DC
.bank $12 slot 3
.org $0000
.section "new script credits" overwrite
  newScript57000:
    .include "out/script/maps/script57000.inc"
.ends

; CHR bank $F0
.bank $13 slot 3
.org $0000
.section "new script 3" overwrite
  newScript5C000:
    .include "out/script/maps/script5C000.inc"
.ends

; CHR bank $F4
.bank $14 slot 3
.org $0000
.section "new script 4" overwrite
  newScript5D000:
    .include "out/script/maps/script5D000.inc"
.ends

; CHR bank $F8
.bank $15 slot 3
.org $0000
.section "new script 5" overwrite
  newScript5E000:
    .include "out/script/maps/script5E000.inc"
.ends

; textTable1
.bank $16 slot 2
.section "new script 6" free
  textTable1:
    .include "out/script/maps/script1AFEE.inc"
.ends

; textTable0
.bank $16 slot 3
.section "new script 7" free
  textTable0Data:
;    .include "out/script/maps/script0B586.inc"
    .include "out/script/maps/script0B586_data.inc"
.ends

; textTable0 index
.bank $05 slot 3
.section "new script 8" free
  textTable0Index:
    .include "out/script/maps/script0B586_index.inc"
.ends

.define stdScriptTableBase $A000

;===============================================
; Use new textTable0
;===============================================

.define tt0StatusOffset $1F
.define tt0MagicOffset $26
.define tt0NameOffset $0C
.define tt0MagicOffsetTwoLine $35
.define tt0BaseOffsetTwoLine $44

.bank $04 slot 2
.org $1625
.section "use new textTable0 1" overwrite
;  ; use new index (base)
;  lda #<textTable0Index
;  sta $0000
;  lda #>textTable0Index
;  sta $0001
  
  ; use new index (base)
  lda #<(textTable0Index+(tt0BaseOffsetTwoLine*2))
  sta $0000
  lda #>(textTable0Index+(tt0BaseOffsetTwoLine*2))
  sta $0001
.ends

.bank $04 slot 2
.org $163A
.section "use new textTable0 2" overwrite
;  jsr useNewTt0Data1

  jsr useTwoLineTt0Base
.ends

.bank $1F slot 5
.section "use new textTable0 3" free
  useNewTt0Data1:
    
    lda prgBankHi
    pha
    
      lda #:textTable0Data
      sta prgBankHi
      jsr switchPrg
      
      ; print
      jsr $9402
    
    pla
    sta prgBankHi
    jmp switchPrg
    
    
.ends

.bank $04 slot 2
.org $1874
.section "use new textTable0 name strings" overwrite
  ; use new index (name)
  lda #<(textTable0Index+(tt0NameOffset*2))
  sta $0000
  lda #>(textTable0Index+(tt0NameOffset*2))
  sta $0001
  
  pla
  jsr $C1C7
  ; retrieve upper-border diacritic flag?
  plp
  
  jsr useNewTt0Data1
.ends

.bank $04 slot 2
.org $1651
.section "use new textTable0 status effects 1" overwrite
  ; use new index (base)
  lda #<(textTable0Index+(tt0StatusOffset*2))
  sta $0000
  lda #>(textTable0Index+(tt0StatusOffset*2))
  sta $0001
.ends

.bank $04 slot 2
.org $1675
.section "use new textTable0 status effects 2" overwrite
  jsr useNewTt0Data1
.ends

.bank $04 slot 2
.org $15C8
.section "use new textTable0 magic" overwrite
;  ; use new index (base)
;  lda #<(textTable0Index+(tt0MagicOffset*2))
;  sta $0000
;  lda #>(textTable0Index+(tt0MagicOffset*2))
;  sta $0001
;  
;  pla
;  jsr $C1C7
;  clc
;  
;  jsr useNewTt0Data1
  
  ; use new index (base)
  lda #<(textTable0Index+(tt0MagicOffsetTwoLine*2))
  sta $0000
  lda #>(textTable0Index+(tt0MagicOffsetTwoLine*2))
  sta $0001
  pla
  jsr $C1C7
  jmp useTwoLineMagicNames
  
.ends

;===============================================
; Use new textTable1
;===============================================

.define tt1ItemOffset 79
.define tt1MonsterOffset 207
.define tt1MonsterOffsetTwoLine 272
.define tt1ItemOffsetTwoLine 337

.bank $1F slot 5
.section "use new textTable two-line entries" free
  useTwoLineMonsterNames:
    jsr useTwoLineNames
    jmp $95AE
  
  useTwoLineItemNames:
    jsr useTwoLineNames
    jmp $9587
  
  useTwoLineMagicNames:
    jsr useTwoLineTt0Names
    jmp $95D8
  
  useTwoLineTt0Base:
;    ; if carry is set, top-line diacritics in use -- use one-line format
;    bcs @oneLine
;    
;    @twoLine:
;      jsr useTwoLineTt0Names
;      jmp $963D
;    
;    @oneLine:
;    jsr useNewTt0Data1
;    jmp $963D
    
    jsr useTwoLineTt0Names
    jmp $963D
  
  useTwoLineTt0Names:
    
    lda prgBankHi
    pha
    
      lda #:textTable0Data
      sta prgBankHi
      jsr switchPrg
      
      ; print
      jsr useTwoLineNamesNoLookup
    
    pla
    sta prgBankHi
    jmp switchPrg

  useTwoLineNames:
    inc twoTermFlag
    
    ; make up work
    jsr $C7B3

    useTwoLineNamesNoLookup:
  
    ; print top line to buffer
;    clc
    jsr $9401
    
    ; now, X = terminator dstindex and Y = terminator srcindex
    ; move to next positions
    inx
    iny
    
    ; make up work
    lda #$00
    sta $0008
    lda #$80
    sta $000A
    ; print second part
    jsr $9432
    
    ; set two-line flag
    inc twoLineFlag
    rts
  
  twoTermCopyDone:
    ; finish
    lda #$80
    sta $0000
    lda #$06
    sta $0001
    jmp $C2A8
  
  twoTermCopyNext:
    iny
    lda #$00
    sta twoTermFlag
    jmp $C7BF
    
.ends

.bank $1E slot 4
.org $07C9
.section "two-terminator copy" overwrite
  lda twoTermFlag
  bne +
    jmp twoTermCopyDone
  +:
  jmp twoTermCopyNext
.ends

.bank $04 slot 2
.org $153C
.section "use new textTable1 1" overwrite
  ; main entries
  lda #<textTable1
  sta $0000
  lda #>textTable1
  sta $0001
  lda #:textTable1
  sta $0002
.ends

.bank $04 slot 2
.org $1573
.section "use new textTable1 2" overwrite
  ; items (non-dialogue)
  lda #<(textTable1+(tt1ItemOffsetTwoLine * 2))
  sta $0000
  lda #>(textTable1+(tt1ItemOffsetTwoLine * 2))
  sta $0001
  lda #:textTable1
  sta $0002
  pla
  jmp useTwoLineItemNames
.ends

.bank $04 slot 2
.org $159A
.section "use new textTable1 3" overwrite
  ; monsters (non-dialogue)
  lda #<(textTable1+(tt1MonsterOffsetTwoLine * 2))
  sta $0000
  lda #>(textTable1+(tt1MonsterOffsetTwoLine * 2))
  sta $0001
  lda #:textTable1
  sta $0002
  pla
  jmp useTwoLineMonsterNames
.ends

.bank $1E slot 4
.org $083E
.section "use new textTable1 4" overwrite
  ; monster names in dialogue
  lda #:textTable1
  jsr saveAndSwitchPrg
  lda #<(textTable1+(tt1MonsterOffset * 2))
  sta $0000
  lda #>(textTable1+(tt1MonsterOffset * 2))
  sta $0001
.ends

.bank $1E slot 4
.org $082C
.section "use new textTable1 5" overwrite
  ; item names in dialogue
  lda #:textTable1
  jsr saveAndSwitchPrg
  lda #<(textTable1+(tt1ItemOffset * 2))
  sta $0000
  lda #>(textTable1+(tt1ItemOffset * 2))
  sta $0001
.ends

;===============================================
; pos table for textTable1 strings
;
; format for each entry: tileX, tileY, output size
;===============================================

.bank $04 slot 2
.org $1B41
.section "newTt1PosTable" overwrite
  tt1PosTable_0:
    .db $6,$8,$18
  tt1PosTable_1:
    .db $16,$9,$3
  tt1PosTable_2:
    .db $12,$3,$4
  tt1PosTable_3:
    .db $12,$4,$5
  tt1PosTable_4:
    .db $a,$9,$c
  tt1PosTable_5:
    .db $a,$b,$c
  tt1PosTable_6:
    .db $a,$d,$e
  tt1PosTable_7:
    .db $a,$f,$10
  tt1PosTable_8:
    .db $2,$12,$10
  tt1PosTable_9:
    .db $2,$14,$10
  tt1PosTable_a:
    .db $2,$16,$10
  tt1PosTable_b:
    .db $2,$19,$5
  tt1PosTable_c:
    .db $7,$80,$4
  tt1PosTable_d:
    .db $12,$80,$9
  tt1PosTable_e:
    .db $12,$80,$9
  tt1PosTable_f:
    .db $12,$80,$9
  tt1PosTable_10:
    .db $12,$80,$9
  tt1PosTable_11:
    .db $12,$80,$9
  tt1PosTable_12:
    .db $11,$3,$3
  tt1PosTable_13:
    .db $11,$5,$3
  tt1PosTable_14:
    .db $1,$8,$2
  tt1PosTable_15:
    .db $1,$a,$2
  tt1PosTable_16:
    .db $1,$c,$2
  tt1PosTable_17:
    .db $1,$e,$2
  tt1PosTable_18:
    .db $1,$10,$2
  tt1PosTable_19:
    .db $1,$12,$2
  tt1PosTable_1a:
    .db $0,$0,$0
  tt1PosTable_1b:
    .db $0,$0,$0
  tt1PosTable_1c:
    .db $12,$3,$8
  tt1PosTable_1d:
    .db $12,$5,$8
  tt1PosTable_1e:
    .db $f,$6,$7
  tt1PosTable_1f:
    .db $f,$8,$3
  tt1PosTable_20:
    .db $f,$a,$7
  tt1PosTable_21:
    .db $f,$c,$8
  tt1PosTable_22:
    .db $f,$e,$6
  tt1PosTable_23:
    .db $f,$10,$0
  tt1PosTable_24:
    .db $f,$12,$6
  tt1PosTable_25:
    .db $f,$14,$2
  tt1PosTable_26:
    .db $f,$16,$7
  tt1PosTable_27:
    .db $f,$18,$7
  tt1PosTable_28:
    .db $f,$1a,$3
  tt1PosTable_29:
    .db $f,$1c,$2
  tt1PosTable_2a:
    .db $b,$20,$3
  tt1PosTable_2b:
    .db $b,$22,$3
  tt1PosTable_2c:
    .db $b,$24,$3
  tt1PosTable_2d:
    .db $b,$26,$3
  tt1PosTable_2e:
    .db $b,$20,$3
  tt1PosTable_2f:
    .db $b,$22,$3
  tt1PosTable_30:
    .db $b,$24,$3
  tt1PosTable_31:
    .db $b,$26,$3
  tt1PosTable_32:
    .db $0,$0,$0
  tt1PosTable_33:
    .db $0,$0,$0
  tt1PosTable_34:
    .db $4,$2,$7
  tt1PosTable_35:
    .db $4,$4,$3
  tt1PosTable_36:
    .db $4,$6,$2
  tt1PosTable_37:
    .db $4,$8,$3
  tt1PosTable_38:
    .db $4,$a,$3
  tt1PosTable_39:
    .db $4,$c,$6
  tt1PosTable_3a:
    .db $4,$e,$7
  tt1PosTable_3b:
    .db $4,$10,$5
  tt1PosTable_3c:
    .db $4,$12,$5
  tt1PosTable_3d:
    .db $4,$14,$4
  ; heal poison
  tt1PosTable_3e:
    .db $6,$16,$b
  tt1PosTable_3f:
    .db $6,$17,$a
  tt1PosTable_40:
    .db $6,$18,$5
  tt1PosTable_41:
    .db $6,$17,$3
  tt1PosTable_42:
    .db $6,$18,$2
  tt1PosTable_43:
    .db $1,$4,$6
  tt1PosTable_44:
    .db $1,$4,$6
  tt1PosTable_45:
    .db $1,$4,$6
  tt1PosTable_46:
    .db $1,$4,$6
  tt1PosTable_47:
    .db $6,$16,$9
  tt1PosTable_48:
    .db $6,$17,$5
  tt1PosTable_49:
    .db $6,$18,$4
  tt1PosTable_4a:
    .db $11,$16,$5
  tt1PosTable_4b:
    .db $6,$16,$f
  tt1PosTable_4c:
    .db $6,$17,$4
  tt1PosTable_4d:
    .db $3,$3,$9
  tt1PosTable_4e:
    .db $13,$3,$9
.ends

;===============================================
; table of cursor positions for menus
;===============================================

.bank $04 slot 2
.org $1385
.section "menu cursor pos table" overwrite
  ; x
;  .db $07,$07,$07,$11,$11
  ; y
;  .db $16,$18,$1A,$16,$18
  ; x
  .db $05,$05,$05,$10,$10
  ; y
  .db $17,$18,$19,$17,$18
.ends

.bank $05 slot 2
.org $00B3
.section "move cursor inventory 1" overwrite
;  ; x
;  .db $01,$0F
;  ; y
;  .db $0A,$0C,$0E,$10,$12,$14,$16,$18
  ; x
  .db $01,$0F
  ; y
  .db $09,$0B,$0D,$0F,$11,$13,$15,$17
.ends

.bank $05 slot 2
.org $1076
.section "move cursor shop 1" overwrite
;  adc #$0A
  adc #$09
.ends

.bank $05 slot 2
.org $085A
.section "move cursor equipment menu battle" overwrite
;  ; y
;  .db $22,$24,$26,$28
  ; y
  .db $21,$23,$25,$27
.ends

.bank $05 slot 2
.org $09AB
.section "move cursor magic menu battle" overwrite
;  ; x
;  .db $02,$10
;  ; y
;  .db $2C,$2E,$30
  ; x
  .db $02,$10
  ; y
  .db $2B,$2D,$2F
.ends

;===============================================
; update game over cursor positions
;===============================================

.define gameOverCursorPpuAddr1 $232C
.define gameOverCursorPpuAddr2 $2331

.bank $0A slot 2
.org $0DD8
.section "move cursor game over 1" overwrite
  ; PPU addr
  .db >gameOverCursorPpuAddr1,<gameOverCursorPpuAddr1
.ends

.bank $0A slot 2
.org $0DE1
.section "move cursor game over 2" overwrite
  ; PPU addr
  .db >gameOverCursorPpuAddr1,<gameOverCursorPpuAddr1
.ends

.bank $0A slot 2
.org $0DDC
.section "move cursor game over 3" overwrite
  ; PPU addr
  .db >gameOverCursorPpuAddr2,<gameOverCursorPpuAddr2
.ends

.bank $0A slot 2
.org $0DE5
.section "move cursor game over 4" overwrite
  ; PPU addr
  .db >gameOverCursorPpuAddr2,<gameOverCursorPpuAddr2
.ends

;===============================================
; Don't copy from CHR ROM
;===============================================

; unbackground free space from removed CHR copy
.unbackground $3EF2E $3EFD7

.define newChrCopyDst $6F00
.define charCopiesPerCall $30

.define scratch1   $0018
.define scratch1Lo $0018
.define scratch1Hi $0019
.define scratch2   $00FE
.define scratch2Lo $00FE
.define scratch2Hi $00FF

.bank $1F slot 5
.org $0F2B
.section "no chr rom copy 1" overwrite
  jmp newChrRomCopy
.ends

.bank $1F slot 5
.section "no chr rom copy 2" free
  newChrRomCopy:
    ; set PPUCTRL
;    lda $00AC
;    and #$FB
;    sta $2000
    
    ; save current PRG banks
;    lda prgBankLo
;    pha
    lda prgBankHi
    pha

;    lda scratch2Lo
;    pha
;    lda scratch2Hi
;    pha
    
      ;======================================
      ; remap CHR bank to new PRG bank
      ; containing strings
      ;======================================
      
      ; get target CHR bank
      lda $0603
      
      ; remap to new PRG bank
      ldx #$00
      -:
        cmp chrToPrgTable.w,X
        beq +
        inx
        bne -
      +:
      
      ; add #$10 to index to get target bank (hi slot)
      txa
      clc
      adc #$10
      sta prgBankHi
      
      ; switch banks
      jsr switchPrg
    
      ;======================================
      ; look up pointer to target string
      ; (if not already done)
      ;======================================
      
      ; branch if high byte of string pointer nonzero (i.e. lookup already
      ; done)
      lda $0602
      bne @pointerLookupDone
      
        ; get string num
        lda $0604
        ; multiply by 2
        asl
        
        ; add base address of table and write to $0604
        clc
        adc #<stdScriptTableBase
        sta $0604
        sta scratch1Lo
        lda #$00
        adc #>stdScriptTableBase
        sta $0605
        sta scratch1Hi
        
        ; fetch pointer to $0601
        ldy #$00
        lda (scratch1),Y
        sta $0601
        iny
        lda (scratch1),Y
        sta $0602
        
        ; write dstptr to 0605
        lda #>newChrCopyDst
        sta $0605
        lda #<newChrCopyDst
        sta $0604
        
      @pointerLookupDone:
      
      ; copy srcptr to scratch2
      lda $0602
      sta scratch2Hi
      lda $0601
      sta scratch2Lo
      
      ; copy dstptr to $0018
      lda $0605
      sta scratch1Hi
      lda $0604
      sta scratch1Lo
      ; add #$30 to dstptr at 0604
      clc
      adc #charCopiesPerCall
      sta $0604
      lda #$00
      adc $0605
      sta $0605
    
      ;======================================
      ; copy target string to RAM
      ;======================================
      
      ; enable PRG RAM
      lda #$81
      sta $A001
      
      ldy #$00
      -:
        ; fetch next string byte
        lda (scratch2),Y
        
        ; branch if terminator
        beq @teminatorFound
        
        sta (scratch1),Y
        
        iny
        cpy #charCopiesPerCall
        bcc -
        bcs @terminatorHandled
      
      @teminatorFound:
      
      ; write terminator
      sta (scratch1),Y
      ; flag copy as finished?
      lda #$00
      sta $0600
      
      @terminatorHandled:

      ; write-protect expansion RAM
      lda #$00
      sta $A001
      
      ;======================================
      ; add 0x30 to srcaddr
      ;======================================
      
      lda $0601
      clc
      adc #charCopiesPerCall
      sta $0601
      lda #$00
      adc $0602
      sta $0602
      
;    pla
;    sta scratch2Hi
;    pla
;    sta scratch2Lo
      
    ; restore old PRG banks
    pla
    sta prgBankHi
;    pla
;    sta prgBankLo
    jmp switchPrg
;    rts

  chrToPrgTable:
    .db $B8,$BC,$DC,$F0,$F4,$F8

.ends

;===============================================
; Disable diacritics. The game allocates 251
; bytes from $0604-$06FF for text printing;
; in the original game, half of that is used
; for the diacritic row. By disabling it, we
; can use all 251 characters per string.
; ...except that due to an obscure bug with
; how the game handles the "more dialogue"
; indicator on certain windows, which just
; happens not to manifest in the original
; game due to the use of diacritics, we have
; to reserve 1 character at the start of the
; buffer, so we can use only 250 characters.
;===============================================

.bank $1F slot 5
.org $0DF2
.section "disable diacritics 1" overwrite
  ; skip transferring diacritic row to PPU
;  ldx $0603
  jmp $EE00
.ends

.bank $04 slot 2
.org $141A
.section "disable diacritics 2" overwrite
  ; skip copying diacritic row to RAM (dialogue)
  
  ; reserve first character in buffer!
  ; if we don't, it will be overwritten by the "wait" indicator
  ; transfer in certain contexts, resulting in corruption.
  ldx #$01
  ; skip copying diacritic row to RAM
  jmp $9428
.ends

/*.bank $1F slot 5
.org $0DE1
.section "disable diacritics 3" overwrite
  ; skip copying diacritic row to RAM (non-dialogue)
  
  ; reserve first character in buffer!
  ldx #$01
  ; skip copying diacritic row to RAM
  jmp $EDE6
.ends*/

;===============================================
; add new 2-row handling
;===============================================

.bank $1F slot 5
.org $0DE1
.section "disable diacritics 3" overwrite
  ; skip copying diacritic row to RAM (non-dialogue)
  
  jmp twoLineCheck
.ends

.bank $1F slot 5
.section "two-line 1" free
  twoLineCheck:
    ; skip copying diacritic row to RAM (non-dialogue)
    ; reserve first character in buffer!
    ldx #$01
    
    ; branch if two-line flag set
    lda twoLineFlag
    bne +
      ; skip copying diacritic row to RAM
      jmp $EDE6
    +:
    
    ; clear two-line flag
    lda #$00
    sta twoLineFlag
    
    ; print first line
    jsr $EE1B
    ; move PPU pos to next row
    jsr $EE80
    ; skip first terminator
    inx
    ; print second line
    jsr $EE1B
    
    jmp $EDEC
    
.ends



;===============================================
; extended menu strings
;===============================================

.bank $04 slot 2
.org $03ED
.section "move menu strings 1" overwrite
  ; x,y coords of main menu strings 1
  lda #$01      ; orig 02
  sta $0044
  lda #$04      ; orig 04
  sta $0045
.ends

.bank $04 slot 2
.org $1631
.section "move menu strings 2" overwrite
  ; length of main menu strings 1
  lda #$06
.ends

; battle
.bank $05 slot 2
.org $05AC
.section "move menu strings 3" overwrite
  ; x,y coords of main menu strings 1
  lda #$01      ; orig 02
  sta $0044
  lda #$04      ; orig 04
  sta $0045
.ends

; battle 2
.bank $04 slot 2
.org $0B5A
.section "move menu strings 4" overwrite
  ; x,y coords of main menu strings 1
  lda #$01      ; orig 02
  sta $0044
  lda #$04      ; orig 04
  sta $0045
.ends

; battle "auto"
.bank $08 slot 2
.org $0A31
.section "move menu strings 5" overwrite
  ; x,y coords of "auto" on autobattle screen
  lda #$01      ; orig 02
  sta $0044
  lda #$04      ; orig 04
  sta $0045
.ends

;===============================================
; print multi-character exp gains with
; additional spacing
;===============================================

.bank $04 slot 2
.org $0E88
.section "multi-char exp gain spacing 1" overwrite
  ; initial x/y tile pos (orig: FF, 13)
  lda #$FB
  sta $0044
  lda #$13
  sta $0045
.ends

.bank $05 slot 2
.org $0AC9
.section "multi-char exp gain spacing 2" overwrite
  jsr newMultiExpAdvance
  jmp $AAD3
.ends

.bank $1F slot 5
.section "multi-char exp gain spacing 3" free
  newMultiExpAdvance:
    ; advance Y if 3rd name written (x == #$13)
    lda $0044
    cmp #$13
    beq @nextLine
    
      ; longest character names length are 7 chars, so
      ; advance by 8 each time
      clc
      adc #$08
      bne @done
      
    @nextLine:
    ; y += 2
    inc $0045
    inc $0045
    ; x = new position
    lda #$07
    
    @done:
    sta $0044
    rts
  
.ends

;===============================================
; fix end-of-string detection algorithm
;
; in the original logic, the game starts from
; the beginning of the string and scans to the
; first space character (01-0D) or terminator
; (00), and assumes the rest is empty.
; this doesn't work with English text, where
; spaces are used between words, so we have to
; modify it to deal with this.
;
; the new check finds the last space character
; that directly follows non-space content, or
; the end of the string if there are no spaces.
;===============================================

.bank $04 slot 2
.org $14CF
.section "fix name end-detection 1" overwrite
  jmp findNameEnd
.ends

.bank $1F slot 5
.section "fix name end-detection 2" free
  findNameEnd:
    ; make up work
;    jsr $C83E
    
    ; Y is now the index of the terminator in the $0420 name buffer
    tya
    pha
      
      ; if last character not space (>= 0E), we're done
;      dey
;      lda $0420,Y
;      cmp #$0E
;      bcs @giveup
    
      ; seek backward until we find a non-space character, or (in case the
      ; string is all spaces) go past the start of the string
      -:
        dey
        ; if index >= 0x80, assume wraparound and give up (buffer is all spaces)
        bmi @giveup
        lda $0420,Y
        cmp #$0E
        bcc -
      
      ; discard old endpos
      pla
      ; Y is now index of last space character following a non-space,
      ; or terminator
      iny
      tya
      bne @done
    
    @giveup:
    ; restore original endpos
    pla
    
    @done:
    
    ; save endpos
    sta scratch2Lo
    
    ; print content from start to endpos
    ldy #$00
    -:
      ; check for terminator
      lda $0420,Y
      beq +
      ; check for endpos
      cpy scratch2Lo
      bcs +
      
      ; print
      jsr $94B0
      jmp -
    +:
    
    jmp $94E0
.ends

;===============================================
; extended window2 strings
;===============================================

; window2
.bank $04 slot 2
.org $0EF3
.section "window2 1" overwrite
  ; x
  lda #$09
  sta $0044
  ; y
  lda #$04
  sta $0045
  
  lda #$06
  ; length
  sta $0603
  
  jsr drawWindow2
  jmp $C32A
.ends

; window2
.bank $1F slot 5
.section "window2 2" free
  drawWindow2:
    
    ; make up work
    lda $0091
    clc
    adc #$10
    
    jmp drawNameCustom
  
  drawNameCustom:
    
    clc 
    php 
    pha 
    
      cmp #$06
      bcs ++
        jsr $E9CF
        bcs +
          lda $04CD
          beq ++
            sec 
            sbc #$01
            jmp ++
        +:
        pla 
        lda #$07
        pha 
      ++:
      jsr $C8E9
      
      ; textTable0 entry $C (names)
      lda #<(textTable0Index+(tt0NameOffset*2))
      sta $0000
      lda #>(textTable0Index+(tt0NameOffset*2))
      sta $0001
    
    pla
    jsr $C1C7
    ; retrieve upper-border diacritic flag?
    plp
    
    jsr useNewTt0Data1

    ; non-hardcoded length
;    lda #$04
;    sta $0603
    lda #$04
    sta $0600
  
    rts
    
.ends

;===============================================
; draw asterisks marking unselectable
; menu items a line higher,
; EXCEPT for character names (which are still
; drawn on the bottom row due to top-row
; diacritic stuff)
;===============================================

.bank $04 slot 2
.org $15EE
.section "trigger asterisk check" overwrite
  jmp asteriskRowCheck
.ends

.bank $1F slot 5
.section "asterisk row check" free
  asteriskRowCheck:
    lda twoTermFlag
    beq +
    
      lda #$00
      sta twoTermFlag
      
      ; draw on second row
      inc $0045
        jsr $C8E9
      dec $0045
      jmp $95F5
    
    +:
    
    jsr $C8E9
    jmp $95F5
  
  nameAsterisk:
    ; flag as lower-row asterisk
    inc twoTermFlag
    ; do usual asterisk draw
    jmp $95DE
    
.ends

.bank $04 slot 2
.org $1302
.section "lower-row asterisks for names" overwrite
  jsr nameAsterisk
.ends

;===============================================
; move item prices up a line
;===============================================

.bank $04 slot 2
.org $0F70
.section "move up item prices" overwrite
  nop
  nop
.ends

;===============================================
; disable "selected" text highlighting so we
; can use the margins of text windows for
; additional space
;===============================================

.bank $04 slot 2
.org $1DE3
.section "disable selection highlighting 1" overwrite
  nop
  nop
  nop
.ends

.bank $04 slot 2
.org $1DEB
.section "disable selection highlighting 2" overwrite
  nop
  nop
  nop
.ends

;===============================================
; speed up text
;===============================================

.bank $1E slot 4
.org $0410
.section "speed up text 1" overwrite
  ; AND global frame counter by $03 instead of $07, doubling base
  ; dialogue speed
  and #$03
.ends

;===============================================
; fix raft assembly display
;===============================================

.bank $05 slot 3
.org $01B2
.section "raft assembly 1" overwrite
  jmp newRaftAssembly
.ends

.bank $1F slot 5
.section "raft assembly 2" free
  newRaftAssembly:
    ; get current item index
    lda $0094
    
    ; write position
    tax
    lda raftXTable.w,X
    sta $0044
    lda raftYTable.w,X
    sta $0045
    
    ; done
    jmp $A1BF
  
  raftXTable:
    .db $11,$18,$15
  raftYTable:
    .db $04,$04,$06
.ends

;===============================================
; use new "new game"/"continue" on title screen
;===============================================

.bank $0A slot 2
.org $0DAB
.section "new title options tilemap components" overwrite
  .incbin "out/script/title_options.bin"
.ends

.define titleNewGamePpuAddr $230B
.define titleContinuePpuAddr $230F

.bank $0A slot 2
.org $0DC5
.section "new title options tilemap cursor positions 1" overwrite
  .db >titleNewGamePpuAddr,<titleNewGamePpuAddr
.ends

.bank $0A slot 2
.org $0DCE
.section "new title options tilemap cursor positions 2" overwrite
  .db >titleNewGamePpuAddr,<titleNewGamePpuAddr
.ends

.bank $0A slot 2
.org $0DC9
.section "new title options tilemap cursor positions 3" overwrite
  .db >titleContinuePpuAddr,<titleContinuePpuAddr
.ends

.bank $0A slot 2
.org $0DD2
.section "new title options tilemap cursor positions 4" overwrite
  .db >titleContinuePpuAddr,<titleContinuePpuAddr
.ends

;===============================================
; Adjust intro text positioning
;===============================================

.bank $0A slot 2
.org $07CA
.section "intro text pos 1" overwrite
  lda #$13
  sta $0045
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $04DD
.section "intro text pos 2" overwrite
  lda #$13
  sta $0045
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $08BF
.section "intro text pos 3" overwrite
  lda #$13
  sta $0045
  lda #$05
  sta $0044
.ends

;===============================================
; Adjust dialogue text positioning
;===============================================

.bank $04 slot 2
.org $0EC1
.section "dialogue text pos 1" overwrite
  lda #$05
  sta $0044
.ends

/*.bank $0A slot 2
.org $0271
.section "dialogue text pos 2" overwrite
  ; "portrait" cutscene 1
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $0295
.section "dialogue text pos 3" overwrite
  ; "portrait" cutscene 2
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $02C9
.section "dialogue text pos 4" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $02FD
.section "dialogue text pos 5" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $0331
.section "dialogue text pos 6" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $04E1
.section "dialogue text pos 7" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $07CE
.section "dialogue text pos 8" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $08C3
.section "dialogue text pos 9" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1B16
.section "dialogue text pos 10" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1B82
.section "dialogue text pos 11" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1C2B
.section "dialogue text pos 12" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1D13
.section "dialogue text pos 13" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1D6C
.section "dialogue text pos 14" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1DDD
.section "dialogue text pos 15" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1E9A
.section "dialogue text pos 16" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $1F3C
.section "dialogue text pos 17" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0B slot 3
.org $0019
.section "dialogue text pos 18" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $015F
.section "dialogue text pos 19" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $0149
.section "dialogue text pos 20" overwrite
  ; ?
  lda #$05
  sta $0044
.ends

.bank $0A slot 2
.org $00D5
.section "dialogue text pos 21" overwrite
  ; ?
  lda #$05
  sta $0044
.ends */

;===============================================
; Adjust Murobo y-position on title
;===============================================

.bank $0A slot 2
.org $074D
.section "adjust murobo title position" overwrite
  lda #$84
.ends

