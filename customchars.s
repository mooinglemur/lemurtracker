.segment "CODE"

.scope CustomChars

NOTE_A = $80
NOTE_B = $81
NOTE_C = $82
NOTE_D = $83
NOTE_E = $84
NOTE_F = $85
NOTE_G = $86

GRID_TOP          = $87
GRID_TOP_LEFT     = $88
GRID_TOP_RIGHT    = $89
GRID_LEFT         = $8A
GRID_RIGHT        = GRID_LEFT
NOTE_DOT          = $8B
NOTE_CUT_LEFT     = $8C
NOTE_CUT_MIDDLE   = $8D
NOTE_CUT_RIGHT    = $8E
NOTE_REL_LEFT     = $8F
NOTE_REL_MIDDLE   = $90
NOTE_REL_RIGHT    = $91
GRID_BOTTOM       = $92
GRID_BOTTOM_LEFT  = GRID_BOTTOM
GRID_BOTTOM_RIGHT = $93



install:
    VERA_SET_ADDR $1F400, 1 ; second half of tileset
    ldx #0
    :
    lda note_chars,x
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



; Custom characters for notes



note_chars:
    ; A
    .byte %10001100
    .byte %10110011
    .byte %10110011
    .byte %10111111
    .byte %10110011
    .byte %10110011
    .byte %10110011
    .byte %10000000

    ; B
    .byte %10111100
    .byte %10110010
    .byte %10110011
    .byte %10111110
    .byte %10110011
    .byte %10110010
    .byte %10111100
    .byte %10000000

    ; C
    .byte %10011110
    .byte %10110011
    .byte %10110000
    .byte %10110000
    .byte %10110000
    .byte %10110011
    .byte %10011110
    .byte %10000000

    ; D
    .byte %10111100
    .byte %10110110
    .byte %10110011
    .byte %10110011
    .byte %10110011
    .byte %10110110
    .byte %10111100
    .byte %10000000

    ; E
    .byte %10111111
    .byte %10110000
    .byte %10110000
    .byte %10111100
    .byte %10110000
    .byte %10110000
    .byte %10111111
    .byte %10000000

    ; F
    .byte %10111111
    .byte %10110000
    .byte %10110000
    .byte %10111100
    .byte %10110000
    .byte %10110000
    .byte %10110000
    .byte %10000000

    ; G
    .byte %10011110
    .byte %10110011
    .byte %10110000
    .byte %10110111
    .byte %10110011
    .byte %10110011
    .byte %10011110
    .byte %10000000

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
