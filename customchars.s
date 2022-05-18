.segment "CODE"

.scope CustomChars

NOTE_A = $8A
NOTE_B = $8B
NOTE_C = $8C
NOTE_D = $8D
NOTE_E = $8E
NOTE_F = $8F
NOTE_G = $90

GRID_TOP          = $A4
GRID_TOP_LEFT     = $A5
GRID_TOP_RIGHT    = $A6
GRID_LEFT         = $A7
GRID_RIGHT        = GRID_LEFT
NOTE_DOT          = $A8
NOTE_CUT_LEFT     = $A9
NOTE_CUT_MIDDLE   = $AA
NOTE_CUT_RIGHT    = $AB
NOTE_REL_LEFT     = $AC
NOTE_REL_MIDDLE   = $AD
NOTE_REL_RIGHT    = $AE
GRID_BOTTOM       = $AF
GRID_BOTTOM_LEFT  = GRID_BOTTOM
GRID_BOTTOM_RIGHT = $B0

INSERT_INDICATOR  = $BB


install:
    ; for the grid letters/numbers, we're going to pull the chars out of the charset
    ; and shift them all over by one pixel, filling in the left pixel
    VERA_SET_ADDR $1F400, 1 ; top half of tileset (Data0)
    inc Vera::Reg::Ctrl
    VERA_SET_ADDR $1F180, 1 ; start at the number 0 (Data1)

    ldx #0
    :
    lda Vera::Reg::Data1
    sec
    ror
    sta Vera::Reg::Data0
    inx
    cpx #(8*10)
    bne :-

    VERA_SET_ADDR $1F208, 1 ; start at the letter A (Data1)
    dec Vera::Reg::Ctrl ; make sure the next Addrx is for Data0

    ldx #0
    :
    lda Vera::Reg::Data1
    sec
    ror
    sta Vera::Reg::Data0
    inx
    cpx #(8*26)
    bne :-


    ldx #0
    :
    lda graphic_chars,x
    sta Vera::Reg::Data0
    inx
    cpx #(8*13)
    bne :-

    rts


graphic_chars:
    ; _
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111111
    .byte %00000000

    ; ,_
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111111
    .byte %10000000

    ; ,
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %10000000
    .byte %10000000

    ; |
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000

    ; |.
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10011000
    .byte %10011000
    .byte %10000000

    ; |- (left)
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10111111
    .byte %10111111
    .byte %10000000
    .byte %10000000
    .byte %10000000

    ; - (middle)
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111111
    .byte %11111111
    .byte %00000000
    .byte %00000000
    .byte %00000000

    ; - (right)
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111110
    .byte %11111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

    ; |=
    .byte %10000000
    .byte %10000000
    .byte %10111111
    .byte %10000000
    .byte %10111111
    .byte %10000000
    .byte %10000000
    .byte %10000000

    ; = (middle)
    .byte %00000000
    .byte %00000000
    .byte %11111111
    .byte %00000000
    .byte %11111111
    .byte %00000000
    .byte %00000000
    .byte %00000000

    ; = (right)
    .byte %00000000
    .byte %00000000
    .byte %11111110
    .byte %00000000
    .byte %11111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

    ; ¯
    .byte %11111111
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000

    ; `
    .byte %10000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00000000




.endscope
