.segment "CODE"

.scope CustomChars

NOTE_A = $0A
NOTE_B = $0B
NOTE_C = $0C
NOTE_D = $0D
NOTE_E = $0E
NOTE_F = $0F
NOTE_G = $10

GRID_TOP          = $11
GRID_TOP_LEFT     = $12
GRID_TOP_RIGHT    = $13
GRID_LEFT         = $14
GRID_RIGHT        = GRID_LEFT
NOTE_DOT          = $15
NOTE_CUT_LEFT     = $16
NOTE_CUT_MIDDLE   = $17
NOTE_CUT_RIGHT    = $18
NOTE_REL_LEFT     = $19
NOTE_REL_MIDDLE   = $1A
NOTE_REL_RIGHT    = $1B
GRID_BOTTOM       = $1C
GRID_BOTTOM_LEFT  = GRID_BOTTOM
GRID_BOTTOM_RIGHT = $1D



install:
    ; for the grid letters/numbers, we're going to pull the chars out of the charset
    ; and shift them all over by one pixel, filling in the left pixel
    VERA_SET_ADDR $1F000, 1 ; beginning of tileset (Data0)
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
    cpx #(8*7)
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
