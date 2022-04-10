.segment "CODE"

xf_install_custom_chars:
    VERA_SET_ADDR $1F400, 1 ; second half of tileset
    ldx #0
    :
    lda xf_note_chars,x
    sta Vera::Reg::Data0
    inx
    cpx #(8*7)
    bne :-

    ldx #0
    :
    lda xf_graphic_chars,x
    sta Vera::Reg::Data0
    inx
    cpx #(8*5)
    bne :-

    rts




; Custom characters for notes

xf_graphic_chars:
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

    ; |-
    .byte %10000000
    .byte %10000000
    .byte %10000000
    .byte %10111111
    .byte %10111111
    .byte %10000000
    .byte %10000000
    .byte %10000000

    ; -
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

    ; =
    .byte %00000000
    .byte %00000000
    .byte %11111110
    .byte %00000000
    .byte %11111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

xf_note_chars:
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
