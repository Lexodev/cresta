;*******************************************************************************
; macro.s
;
; Usefull macros
;*******************************************************************************

; Copperlist macros

; Move a data to a register (CMOVE value,register)
CMOVE     MACRO
  dc.w    (\2)&$0ffe,\1
  ENDM

; Wait for a beam position (CWAIT x,y,[mask])
CWAIT     MACRO
  IFC     '','\3'
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,$fffe
  ELSEIF
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,(\3)&$fffe
  ENDC
  ENDM

; Skip the following instruction (CSKIP x,y,[mask])
CSKIP     MACRO
  IFC     '','\3'
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,$ffff
  ELSEIF
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,((\3)&$ffff)!1
  ENDC
  ENDM

; NO-OP instruction
CNOOP     MACRO
  dc.l    $01fe0000
  ENDM

; End of copperlist (CEND)
CEND      MACRO
  dc.l    $fffffffe
  ENDM

;*******************************************************************************

; Wait for a raster line (RWAIT x,y)
RWAIT MACRO
.RasterWait\@:
  cmpi.w  #((\2)&$ff)<<8!((\1)&$ff),CUSTOM+VHPOSR
  blo.s   .RasterWait\@
  ENDM

;*******************************************************************************

; Allocate a memory buffer (ALLOCMEM size,memtype,adrsave,onerror)
ALLOCMEM  MACRO
  move.l  $4.w,a6
  move.l  #\1,d0
  move.l  #\2,d1
  jsr     _AllocMem(a6)
  move.l  d0,\3
  beq     \4
  ENDM

; Free a memory buffer (FREEMEM size,adrsave)
FREEMEM   MACRO
  tst.l   \2
  beq.s   .NoMemory\@
  move.l  $4.w,a6
  move.l  #\1,d0
  move.l  \2,a1
  jsr     _FreeMem(a6)
  move.l  #0,\2
.NoMemory\@:
  ENDM

;*******************************************************************************

; Wait VBL flag
WAITVBL   MACRO
  move.w  #$0,FlagVBL
.WaitVBL\@:
  tst.w   FlagVBL
  beq.s   .WaitVBL\@
  ENDM

;*******************************************************************************

; Wait for end of blitter activity
; a6 = custom base
WAITBLT   MACRO
  tst.b   2(a6)
.WaitBlit\@:
  btst    #6,DMACONR(a6)
  bne.s   .WaitBlit\@
  ENDM

;*******************************************************************************

; Process a 14 bits fixed float number
FIXEDVAL  MACRO
  addx.l  \1,\1
  add.l   \1,\1
  swap    \1
  ENDM

;*******************************************************************************

; Wait a left mouse click (WAITLMB [color])
WAITLMB   MACRO
.WaitLMB\@:
  IFC     '','\1'
  nop
  ELSEIF
  move.w  #\1,CUSTOM+COLOR00
  ENDC
  btst    #MOUSE_BUTTON1,CIAA+CIAPRA    ; Test left mouse button
  bne.s   .WaitLMB\@
  ENDM
