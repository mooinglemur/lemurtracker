
xf_byte_to_hex: ; converts a number to two ASCII/PETSCII hex digits: input A = number to convert, output A = most sig nybble, X = least sig nybble, affects A,X
    pha

    and #$0f
    tax
    pla
    lsr
    lsr
    lsr
    lsr
    pha
    txa
    jsr @hexify
    tax
    pla
@hexify:
    cmp #10
    bcc @nothex
    adc #$66
@nothex:
    eor #%00110000
    rts


xf_set_charset:
    lda #3
    jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_reset_charset:
    lda #2
    jmp SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_clear_screen:
    VERA_SET_ADDR $1B000,1
    ldy #64 ; rows
@row:
    ldx #128 ; columns
@column:
    lda #32 ; empty tile
    sta VERA_data0
    lda #%00000001 ; (BBBB|FFFF) background and foreground colors
    sta VERA_data0
    dex
    bne @column
    dey
    bne @row

    rts
