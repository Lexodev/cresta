;*******************************************************************************
; toolbox.s
;
; Utility functions
;*******************************************************************************

;*******************************************************************************
  SECTION TOOLBOXCODE,CODE
;*******************************************************************************

;*******************************************************************************
; Save system
;   OUT : d0.l = operation success
;*******************************************************************************
SaveSystem:
  movem.l a0-a6,-(sp)

  movea.l _ExecBase,a6                  ; EXEC library

  jsr     _Forbid(a6)                   ; Stop multitask

.OpenDOSLib:
  lea     DOSLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open DOS library
  tst.l   d0
  beq     .EndInit                      ; Quit if not present
  move.l  d0,DOSBase                    ; Keep the pointer

.OpenGraphicsLib:
  lea     GraphicsLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open GRAPHICS library
  tst.l   d0
  beq     .EndInit                      ; Quit if not present
  move.l  d0,GfxBase                    ; Keep the pointer

.SaveInterrupts:
  lea     CUSTOM,a6
  move.w  DMACONR(a6),SaveDmacon
  ori.w   #$8100,SaveDmacon             ; Save DMA status
  move.w  INTENAR(a6),SaveIntena
  ori.w   #$C000,SaveIntena             ; Save IT status

  movea.l GfxBase,a6                    ; GRAPHICS base
.ReserveBlitter:
  jsr     _WaitBlit(a6)                 ; Wait end of Blitter activity

.SaveCopper:
  move.l  GFX_COPPERLIST(a6),SaveCopper ; Save current copper list

.ResetView:
  move.l  GFX_ACTIVEVIEW(a6),SaveView   ; Save the current view
  suba.l  a1,a1
  jsr     _LoadView(a6)                 ; Load an empty view
  jsr     _WaitTOF(a6)
  jsr     _WaitTOF(a6)                  ; Two wait for interlaced screens

.CheckCPU:
  movea.l _ExecBase,a6                  ; EXEC library
  move.w  EXEC_ATTNFLAGS(a6),d0         ; Flags ATTN EXEC (CPU & FPU)
  bne.s   .GetVectorBase                ; Not 68000, get the VBR
  moveq.l #0,d0
  bra.s   .SaveVbr
.GetVectorBase:
  lea     GetVBR,a5
  jsr     _Supervisor(a6)
.SaveVbr:
  move.l  d0,VbrBase                    ;  Get VBR

.SaveVectors:
  movea.l VbrBase,a0                    ; Save current interrupts vectors
  move.l  VEC_KBD(a0),SaveKeyboard      ; Keyboard
  move.l  VEC_VBL(a0),SaveVbl           ; VBL

.NoError:
  move.l  #-1,d0                        ; Init OK

.EndInit:
  movem.l (sp)+,a0-a6
  rts

;*******************************************************************************
; Restore system
;*******************************************************************************
RestoreSystem:
  movem.l a0-a6,-(sp)

  tst.l   DOSBase
  beq     .CloseGraphicsLib             ; DOS library not open

  tst.l   GfxBase
  beq     .NoRestore                    ; GRAPHICS library not open

  lea     CUSTOM,a6
.StopInterrupts:
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
  move.w  #INT_STOP,INTENA(a6)          ; Stop interruptions
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests

.RestoreVectors:
  move.l  VbrBase,a0                    ; Restore vectors
  move.l  SaveKeyboard,VEC_KBD(a0)      ; Keyboard
  move.l  SaveVbl,VEC_VBL(a0)           ; VBL

  movea.l GfxBase,a6

.RestoreView:
  movea.l SaveView,a1
  jsr     _LoadView(a6)                 ; Restore view
  jsr     _WaitTOF(a6)
  jsr     _WaitTOF(a6)                  ; Two times for interlaced screens
  
.FreeBlitter:
  jsr     _WaitBlit(a6)                 ; Wait end of Blitter activity

  lea     CUSTOM,a6
.RestoreCopper:
  move.l  SaveCopper,COP1LC(a6)         ; Restore Copper list

.RestoreInterrupts:
  move.w  SaveIntena,INTENA(a6)         ; Restore IT
  move.w  SaveDmacon,DMACON(a6)         ; Restore DMA

.CloseGraphicsLib:
  movea.l $4.w,a6
  movea.l GfxBase,a1
  jsr     _CloseLibrary(a6)             ; Close GRAPHICS library

.CloseDOSLib:
  movea.l $4.w,a6
  movea.l DOSBase,a1
  jsr     _CloseLibrary(a6)             ; Close DOS library

.NoRestore
  movea.l $4.w,a6
  jsr     _Permit(a6)                   ; Start multitask

  movem.l (sp)+,a0-a6
  rts

;*******************************************************************************
; Get VBR
;*******************************************************************************
GetVBR:
  dc.l    $4E7A0801                     ; Opcode for "movec VBR,d0"
  rte

;*******************************************************************************
; Calcul sprite control data
;   IN  : d0.w = X coordinate
;         d1.w = Y coordinate
;         d2.w = sprite height
;         d3.l = screen position (W: starty, W: startx)
;   OUT : d0.l = sprite control data
;
; V = VSTART, H = HSTART, S = VSTOP, A = ATTACH, x = UNUSED
;
; SPRxPOS : 15 .  .  .  .  .  .  8  7  .  .  .  .  .  .  0
;           V7 V6 V5 V4 V3 V2 V1 V0 H8 H7 H6 H5 H4 H3 H2 H1
;
; SPRxCTL : 15 .  .  .  .  .  .  8  7  .  .  .  .  .  .  0
;           S7 S6 S5 S4 S3 S2 S1 S0 A  x  x  x  x  V8 S8 H0
;*******************************************************************************
CalculSpriteControl:
  movem.l d1-d3,-(sp)
  andi.l  #$FFFF,d0
  add.w   d3,d0                         ; Add screen offset X
  andi.l  #$FFFF,d1
  swap    d3
  add.w   d3,d1                         ; Add screen offset Y
  andi.l  #$FFFF,d2
  add.w   d1,d2                         ; Sprite VSTOP
  lsl.l   #8,d1                         ; Set VSTART low bits
  ror.l   #1,d0                         ; Set HSTART high bits
  or.w    d1,d0                         ; First control data (SPRxPOS)
  swap    d0                            ; Get HSTART low bit
  rol.w   #1,d0                         ; In first position
  lsl.l   #8,d2                         ; Set VSTOP low bits
  or.w    d2,d0                         ; Second control data (SPRxCTL)
  swap    d1                            ; Get VSTART high bit
  lsl.w   #2,d1                         ; In third position
  or.w    d1,d0                         ; Add to control data
  swap    d2                            ; Get VSTOP high bit
  add.w   d2,d2                         ; In second position
  or.w    d2,d0                         ; Add to control data
  movem.l (sp)+,d1-d3
  rts

;*******************************************************************************
; Get a random number between 0 and X
;   IN  : d0.w = upper limit
;   OUT : d0.w = random value
;*******************************************************************************
RandXorShift:
  movem.l d1-d7,-(sp)

  move.l  RandomSeed,d1                 ; randomseed

  move.l  RandomX,d2                    ; x
  move.l  RandomY,d3                    ; y
  move.l  RandomZ,d4                    ; z

  move.l  d2,d7                         ; t = x
  moveq.l #11,d5
  lsl.l   d5,d7                         ; t = x << 11
  eor.l   d2,d7                         ; t = x ^ (x << 11)
  andi.l  #$7fffffff,d7                 ; t = (x ^ (x << 11)) & 0x7fffffff
  
  exg     d2,d3                         ; x = y
  exg     d3,d4                         ; y = z
  move.l  d1,d4                         ; z = randomseed
  
  move.l  d7,d6
  moveq.l #8,d5
  lsr.l   d5,d6                         ; t >> 8
  eor.l   d6,d7                         ; t ^ (t >> 8)
  
  move.l  d1,d6                         ; randomseed
  moveq.l #19,d5
  lsr.l   d5,d6                         ; randomseed = randomseed >> 19
  eor.l   d6,d1                         ; randomseed = randomseed ^ (randomseed >> 19)
  
  eor.l   d7,d1                         ; randomseed = randomseed ^ (randomseed >> 19) ^ (t ^ (t >> 8))

  move.l  d1,RandomSeed                 ; Save for next call
  move.l  d2,RandomX
  move.l  d3,RandomY
  move.l  d4,RandomZ

  swap    d1
  rol.l   #1,d1                         ; randomseed >> 15
  mulu.w  d1,d0
  swap    d0                            ; Result

  movem.l (sp)+,d1-d7  
  rts

;*******************************************************************************
  SECTION TOOLBOXDATA,DATA
;*******************************************************************************

GraphicsLib:
  dc.b    "graphics.library",0

DOSLib:
  dc.b    "dos.library",0

  EVEN

VbrBase:
  dc.l    0
GfxBase:
  dc.l    0
DOSBase:
  dc.l    0

SaveIntena:
  dc.w    0
SaveDmacon:
  dc.w    0
SaveKeyboard:
  dc.l    0
SaveVbl:
  dc.l    0
SaveView:
  dc.l    0
SaveCopper:
  dc.l    0

RandomSeed:
  dc.l    314159265
RandomX:
  dc.l    987654321
RandomY:
  dc.l    362436069
RandomZ:
  dc.l    521288629

; Sine/cosine table (512 level)
SinCosTable:                            ; W: Sine, W: Cosine
  dc.w    $0000,$4000,$00c9,$3ffe,$0192,$3ffb,$025b,$3ff4,$0323,$3fec
  dc.w    $03ec,$3fe1,$04b5,$3fd3,$057d,$3fc3,$0645,$3fb1,$070d,$3f9c
  dc.w    $07d5,$3f84,$089c,$3f6a,$0964,$3f4e,$0a2a,$3f2f,$0af1,$3f0e
  dc.w    $0bb6,$3eeb,$0c7c,$3ec5,$0d41,$3e9c,$0e05,$3e71,$0ec9,$3e44
  dc.w    $0f8c,$3e14,$104f,$3de2,$1111,$3dae,$11d3,$3d77,$1294,$3d3e
  dc.w    $1354,$3d02,$1413,$3cc5,$14d1,$3c84,$158f,$3c42,$164c,$3bfd
  dc.w    $1708,$3bb6,$17c3,$3b6c,$187d,$3b20,$1937,$3ad2,$19ef,$3a82
  dc.w    $1aa6,$3a2f,$1b5d,$39da,$1c12,$3983,$1cc6,$392a,$1d79,$38cf
  dc.w    $1e2b,$3871,$1edc,$3811,$1f8b,$37af,$2039,$374b,$20e7,$36e5
  dc.w    $2192,$367c,$223d,$3612,$22e6,$35a5,$238e,$3536,$2434,$34c6
  dc.w    $24da,$3453,$257d,$33de,$261f,$3367,$26c0,$32ee,$275f,$3274
  dc.w    $27fd,$31f7,$2899,$3179,$2934,$30f8,$29cd,$3076,$2a65,$2ff1
  dc.w    $2afa,$2f6b,$2b8e,$2ee3,$2c21,$2e5a,$2cb2,$2dce,$2d41,$2d41
  dc.w    $2dce,$2cb2,$2e5a,$2c21,$2ee3,$2b8e,$2f6b,$2afa,$2ff1,$2a65
  dc.w    $3076,$29cd,$30f8,$2934,$3179,$2899,$31f7,$27fd,$3274,$275f
  dc.w    $32ee,$26c0,$3367,$261f,$33de,$257d,$3453,$24da,$34c6,$2434
  dc.w    $3536,$238e,$35a5,$22e6,$3612,$223d,$367c,$2192,$36e5,$20e7
  dc.w    $374b,$2039,$37af,$1f8b,$3811,$1edc,$3871,$1e2b,$38cf,$1d79
  dc.w    $392a,$1cc6,$3983,$1c12,$39da,$1b5d,$3a2f,$1aa6,$3a82,$19ef
  dc.w    $3ad2,$1937,$3b20,$187d,$3b6c,$17c3,$3bb6,$1708,$3bfd,$164c
  dc.w    $3c42,$158f,$3c84,$14d1,$3cc5,$1413,$3d02,$1354,$3d3e,$1294
  dc.w    $3d77,$11d3,$3dae,$1111,$3de2,$104f,$3e14,$0f8c,$3e44,$0ec9
  dc.w    $3e71,$0e05,$3e9c,$0d41,$3ec5,$0c7c,$3eeb,$0bb6,$3f0e,$0af1
  dc.w    $3f2f,$0a2a,$3f4e,$0964,$3f6a,$089c,$3f84,$07d5,$3f9c,$070d
  dc.w    $3fb1,$0645,$3fc3,$057d,$3fd3,$04b5,$3fe1,$03ec,$3fec,$0323
  dc.w    $3ff4,$025b,$3ffb,$0192,$3ffe,$00c9,$4000,$0000,$3ffe,$ff36
  dc.w    $3ffb,$fe6d,$3ff4,$fda4,$3fec,$fcdc,$3fe1,$fc13,$3fd3,$fb4a
  dc.w    $3fc3,$fa82,$3fb1,$f9ba,$3f9c,$f8f2,$3f84,$f82a,$3f6a,$f763
  dc.w    $3f4e,$f69b,$3f2f,$f5d5,$3f0e,$f50e,$3eeb,$f449,$3ec5,$f383
  dc.w    $3e9c,$f2be,$3e71,$f1fa,$3e44,$f136,$3e14,$f073,$3de2,$efb0
  dc.w    $3dae,$eeee,$3d77,$ee2c,$3d3e,$ed6b,$3d02,$ecab,$3cc5,$ebec
  dc.w    $3c84,$eb2e,$3c42,$ea70,$3bfd,$e9b3,$3bb6,$e8f7,$3b6c,$e83c
  dc.w    $3b20,$e782,$3ad2,$e6c8,$3a82,$e610,$3a2f,$e559,$39da,$e4a2
  dc.w    $3983,$e3ed,$392a,$e339,$38cf,$e286,$3871,$e1d4,$3811,$e123
  dc.w    $37af,$e074,$374b,$dfc6,$36e5,$df18,$367c,$de6d,$3612,$ddc2
  dc.w    $35a5,$dd19,$3536,$dc71,$34c6,$dbcb,$3453,$db25,$33de,$da82
  dc.w    $3367,$d9e0,$32ee,$d93f,$3274,$d8a0,$31f7,$d802,$3179,$d766
  dc.w    $30f8,$d6cb,$3076,$d632,$2ff1,$d59a,$2f6b,$d505,$2ee3,$d471
  dc.w    $2e5a,$d3de,$2dce,$d34d,$2d41,$d2be,$2cb2,$d231,$2c21,$d1a5
  dc.w    $2b8e,$d11c,$2afa,$d094,$2a65,$d00e,$29cd,$cf89,$2934,$cf07
  dc.w    $2899,$ce86,$27fd,$ce08,$275f,$cd8b,$26c0,$cd11,$261f,$cc98
  dc.w    $257d,$cc21,$24da,$cbac,$2434,$cb39,$238e,$cac9,$22e6,$ca5a
  dc.w    $223d,$c9ed,$2192,$c983,$20e7,$c91a,$2039,$c8b4,$1f8b,$c850
  dc.w    $1edc,$c7ee,$1e2b,$c78e,$1d79,$c730,$1cc6,$c6d5,$1c12,$c67c
  dc.w    $1b5d,$c625,$1aa6,$c5d0,$19ef,$c57d,$1937,$c52d,$187d,$c4df
  dc.w    $17c3,$c493,$1708,$c449,$164c,$c402,$158f,$c3bd,$14d1,$c37b
  dc.w    $1413,$c33a,$1354,$c2fd,$1294,$c2c1,$11d3,$c288,$1111,$c251
  dc.w    $104f,$c21d,$0f8c,$c1eb,$0ec9,$c1bb,$0e05,$c18e,$0d41,$c163
  dc.w    $0c7c,$c13a,$0bb6,$c114,$0af1,$c0f1,$0a2a,$c0d0,$0964,$c0b1
  dc.w    $089c,$c095,$07d5,$c07b,$070d,$c063,$0645,$c04e,$057d,$c03c
  dc.w    $04b5,$c02c,$03ec,$c01e,$0323,$c013,$025b,$c00b,$0192,$c004
  dc.w    $00c9,$c001,$0000,$c000,$ff36,$c001,$fe6d,$c004,$fda4,$c00b
  dc.w    $fcdc,$c013,$fc13,$c01e,$fb4a,$c02c,$fa82,$c03c,$f9ba,$c04e
  dc.w    $f8f2,$c063,$f82a,$c07b,$f763,$c095,$f69b,$c0b1,$f5d5,$c0d0
  dc.w    $f50e,$c0f1,$f449,$c114,$f383,$c13a,$f2be,$c163,$f1fa,$c18e
  dc.w    $f136,$c1bb,$f073,$c1eb,$efb0,$c21d,$eeee,$c251,$ee2c,$c288
  dc.w    $ed6b,$c2c1,$ecab,$c2fd,$ebec,$c33a,$eb2e,$c37b,$ea70,$c3bd
  dc.w    $e9b3,$c402,$e8f7,$c449,$e83c,$c493,$e782,$c4df,$e6c8,$c52d
  dc.w    $e610,$c57d,$e559,$c5d0,$e4a2,$c625,$e3ed,$c67c,$e339,$c6d5
  dc.w    $e286,$c730,$e1d4,$c78e,$e123,$c7ee,$e074,$c850,$dfc6,$c8b4
  dc.w    $df18,$c91a,$de6d,$c983,$ddc2,$c9ed,$dd19,$ca5a,$dc71,$cac9
  dc.w    $dbcb,$cb39,$db25,$cbac,$da82,$cc21,$d9e0,$cc98,$d93f,$cd11
  dc.w    $d8a0,$cd8b,$d802,$ce08,$d766,$ce86,$d6cb,$cf07,$d632,$cf89
  dc.w    $d59a,$d00e,$d505,$d094,$d471,$d11c,$d3de,$d1a5,$d34d,$d231
  dc.w    $d2be,$d2be,$d231,$d34d,$d1a5,$d3de,$d11c,$d471,$d094,$d505
  dc.w    $d00e,$d59a,$cf89,$d632,$cf07,$d6cb,$ce86,$d766,$ce08,$d802
  dc.w    $cd8b,$d8a0,$cd11,$d93f,$cc98,$d9e0,$cc21,$da82,$cbac,$db25
  dc.w    $cb39,$dbcb,$cac9,$dc71,$ca5a,$dd19,$c9ed,$ddc2,$c983,$de6d
  dc.w    $c91a,$df18,$c8b4,$dfc6,$c850,$e074,$c7ee,$e123,$c78e,$e1d4
  dc.w    $c730,$e286,$c6d5,$e339,$c67c,$e3ed,$c625,$e4a2,$c5d0,$e559
  dc.w    $c57d,$e610,$c52d,$e6c8,$c4df,$e782,$c493,$e83c,$c449,$e8f7
  dc.w    $c402,$e9b3,$c3bd,$ea70,$c37b,$eb2e,$c33a,$ebec,$c2fd,$ecab
  dc.w    $c2c1,$ed6b,$c288,$ee2c,$c251,$eeee,$c21d,$efb0,$c1eb,$f073
  dc.w    $c1bb,$f136,$c18e,$f1fa,$c163,$f2be,$c13a,$f383,$c114,$f449
  dc.w    $c0f1,$f50e,$c0d0,$f5d5,$c0b1,$f69b,$c095,$f763,$c07b,$f82a
  dc.w    $c063,$f8f2,$c04e,$f9ba,$c03c,$fa82,$c02c,$fb4a,$c01e,$fc13
  dc.w    $c013,$fcdc,$c00b,$fda4,$c004,$fe6d,$c001,$ff36,$c000,$ffff
  dc.w    $c001,$00c9,$c004,$0192,$c00b,$025b,$c013,$0323,$c01e,$03ec
  dc.w    $c02c,$04b5,$c03c,$057d,$c04e,$0645,$c063,$070d,$c07b,$07d5
  dc.w    $c095,$089c,$c0b1,$0964,$c0d0,$0a2a,$c0f1,$0af1,$c114,$0bb6
  dc.w    $c13a,$0c7c,$c163,$0d41,$c18e,$0e05,$c1bb,$0ec9,$c1eb,$0f8c
  dc.w    $c21d,$104f,$c251,$1111,$c288,$11d3,$c2c1,$1294,$c2fd,$1354
  dc.w    $c33a,$1413,$c37b,$14d1,$c3bd,$158f,$c402,$164c,$c449,$1708
  dc.w    $c493,$17c3,$c4df,$187d,$c52d,$1937,$c57d,$19ef,$c5d0,$1aa6
  dc.w    $c625,$1b5d,$c67c,$1c12,$c6d5,$1cc6,$c730,$1d79,$c78e,$1e2b
  dc.w    $c7ee,$1edc,$c850,$1f8b,$c8b4,$2039,$c91a,$20e7,$c983,$2192
  dc.w    $c9ed,$223d,$ca5a,$22e6,$cac9,$238e,$cb39,$2434,$cbac,$24da
  dc.w    $cc21,$257d,$cc98,$261f,$cd11,$26c0,$cd8b,$275f,$ce08,$27fd
  dc.w    $ce86,$2899,$cf07,$2934,$cf89,$29cd,$d00e,$2a65,$d094,$2afa
  dc.w    $d11c,$2b8e,$d1a5,$2c21,$d231,$2cb2,$d2be,$2d41,$d34d,$2dce
  dc.w    $d3de,$2e5a,$d471,$2ee3,$d505,$2f6b,$d59a,$2ff1,$d632,$3076
  dc.w    $d6cb,$30f8,$d766,$3179,$d802,$31f7,$d8a0,$3274,$d93f,$32ee
  dc.w    $d9e0,$3367,$da82,$33de,$db25,$3453,$dbcb,$34c6,$dc71,$3536
  dc.w    $dd19,$35a5,$ddc2,$3612,$de6d,$367c,$df18,$36e5,$dfc6,$374b
  dc.w    $e074,$37af,$e123,$3811,$e1d4,$3871,$e286,$38cf,$e339,$392a
  dc.w    $e3ed,$3983,$e4a2,$39da,$e559,$3a2f,$e610,$3a82,$e6c8,$3ad2
  dc.w    $e782,$3b20,$e83c,$3b6c,$e8f7,$3bb6,$e9b3,$3bfd,$ea70,$3c42
  dc.w    $eb2e,$3c84,$ebec,$3cc5,$ecab,$3d02,$ed6b,$3d3e,$ee2c,$3d77
  dc.w    $eeee,$3dae,$efb0,$3de2,$f073,$3e14,$f136,$3e44,$f1fa,$3e71
  dc.w    $f2be,$3e9c,$f383,$3ec5,$f449,$3eeb,$f50e,$3f0e,$f5d5,$3f2f
  dc.w    $f69b,$3f4e,$f763,$3f6a,$f82a,$3f84,$f8f2,$3f9c,$f9ba,$3fb1
  dc.w    $fa82,$3fc3,$fb4a,$3fd3,$fc13,$3fe1,$fcdc,$3fec,$fda4,$3ff4
  dc.w    $fe6d,$3ffb,$ff36,$3ffe
