;*******************************************************************************
; constant.s
;
; Constants definition
;*******************************************************************************

; Status constants
NULL                = 0
TRUE                = -1
FALSE               = 0
EOL                 = $0A

; EXEC functions
_ExecBase           = $4
_Supervisor         = -$1E
_Forbid             = -$84
_Permit             = -$8A
_AddIntServer       = -$A8
_RemIntServer       = -$AE
_AllocMem           = -$C6
_FreeMem            = -$D2
_AvailMem           = -$D8
_FindTask           = -$126
_SetTaskPri         = -$12C
_CloseLibrary       = -$19E
_OpenLibrary        = -$228

; GRAPHICS functions
_LoadView           = -$DE
_WaitBlit           = -$E4
_WaitTOF            = -$10E
_OwnBlitter         = -$1C8
_DisownBlitter      = -$1CE

; DOS functions
_Open               = -$1E
_Close              = -$24
_Read               = -$2A
_Write              = -$30
_Seek               = -$42
_PutStr             = -$3B4

; INTUITION functions
_RethinkDisplay     = -$186

; Interrupts vectors
VEC_KBD             = $68
VEC_VBL             = $6C
VEC_AUDIO           = $70
VEC_TRAP0           = $80

; Library constants
LIB_VERSION         = $14
LIB_REVISION        = $16

; Exec constants
EXEC_ATTNFLAGS      = $128
EXEC_VBFREQ         = $212
EXEC_AF68010        = $0
EXEC_AF68020        = $1
EXEC_AF68030        = $2
EXEC_AF68040        = $3
EXEC_AF68060        = $9
EXEC_AFMFPU         = $F

; Graphics constants
GFXB_ECS_AGNUS      = $0
GFXB_ECS_DENISE     = $1
GFXB_AA_ALICE       = $2
GFXB_PAL            = $2
GFX_ACTIVEVIEW      = $22
GFX_COPPERLIST      = $26
GFX_DISPLAYFLAGS    = $CE
GFX_CHIPREV         = $EC

; DMA channels
DMA_ON              = $8200
DMA_OFF             = $0200
DMA_NASTYBLIT       = $0400
DMA_BITPLANE        = $0100
DMA_COPPER          = $0080
DMA_BLITTER         = $0040
DMA_SPRITE          = $0020
DMA_DISK            = $0010
DMA_AUDIO3          = $0008
DMA_AUDIO2          = $0004
DMA_AUDIO1          = $0002
DMA_AUDIO0          = $0001
DMA_AUDIOFULL       = DMA_AUDIO0|DMA_AUDIO1|DMA_AUDIO2|DMA_AUDIO3
DMA_STOP            = $7FFF

; Interruptions
INT_ON              = $C000
INT_OFF             = $4000
INT_EXTER           = $2000
INT_DSKSYN          = $1000
INT_RBF             = $0800
INT_AUD3            = $0400
INT_AUD2            = $0200
INT_AUD1            = $0100
INT_AUD0            = $0080
INT_BLIT            = $0040
INT_VERTB           = $0020
INT_COPER           = $0010
INT_PORTS           = $0008
INT_SOFT            = $0004
INT_DSKBLK          = $0002
INT_STOP            = $7FFF

; IT and DMA for DOS functions
DOS_INTENA          = INT_PORTS
DOS_DMA             = DMA_BLITTER|DMA_DISK

; Interrupts servers
INTB_VERTB          = 5
INTB_COPER          = 4

; Burst mode
BURST_NONE          = $0000
BURST_SPR0          = $0000
BURST_SPR2          = $0004
BURST_SPR4          = $000C
BURST_BPL0          = $0000
BURST_BPL2          = $0001
BURST_BPL4          = $0003

; Sprites
SPR_MAXSPRITE       = 8

; Colors
PAL_MAXCOLORS       = 32

; Audio
AUDIO_PALCLOCK      = 3546895
AUDIO_NTSCCLOCK     = 3579545
AUDIO_MAXVOLUME     = 64
AUDIO_CHAN0         = 0
AUDIO_CHAN1         = 1
AUDIO_CHAN2         = 2
AUDIO_CHAN3         = 3
AUDIO_CHANX         = -1

; Blitter
BLT_SRCA            = $00F0
BLT_SRCB            = $00CC
BLT_SRCC            = $00AA
BLT_USEA            = $0800
BLT_USEB            = $0400
BLT_USEC            = $0200
BLT_USED            = $0100

; Minterm for clear mode
BLT_CLEAR           = BLT_USED

; Minterm for standard copy (A -> D)
BLT_COPY            = (BLT_USEA+BLT_USED)+BLT_SRCA

; Minterm for ored copy (A|C -> D)
BLT_ORCOPY          = (BLT_USEA+BLT_USEC+BLT_USED)+(BLT_SRCA|BLT_SRCC)

; Minterm for cookie cut copy (A = masque, B = BLOB, A&B|!A&C -> D)
BLT_CCUT            = (BLT_USEA+BLT_USEB+BLT_USEC+BLT_USED)+((BLT_SRCA&BLT_SRCB)+(~BLT_SRCA&BLT_SRCC))

; Minterm for fill mode (A -> D)
BLT_FILL            = (BLT_USEA+BLT_USED)+BLT_SRCA

; Fill mode
BLT_FILLEXCLU       = $0012
BLT_FILLINCLU       = $000A

; Descending mode
BLT_DESCENDING      = $0002

; Memory option
MEMF_PUBLIC         = 1<<0
MEMF_CHIP           = 1<<1
MEMF_FAST           = 1<<2
MEMF_CLEAR          = 1<<16
MEMF_LARGEST        = 1<<17
MEMF_TOTAL          = 1<<19

; File option
MODE_OLDFILE        = 1005
MODE_NEWFILE        = 1006
MODE_READWRITE      = 1004
OFFSET_BEGINNING    = -1
OFFSET_CURRENT      = 0
OFFSET_END          = 1

; Joystick / mouse
MOUSE_BUTTON1       = 6
MOUSE_BUTTON2       = 2
JOY_BUTTON1         = 7
