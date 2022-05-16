
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
    jsr xf_hexify
    tax
    pla
xf_hexify:
    cmp #10
    bcc @nothex
    adc #$66
@nothex:
    eor #%00110000
    rts

xf_byte_to_hex_in_grid: ; converts a number to two ASCII/PETSCII hex digits: input A = number to convert, output A = most sig nybble, X = least sig nybble, affects A,X
    pha
    and #$0f

    tax
    pla
    lsr
    lsr
    lsr
    lsr
    clc
    adc #$80
    pha
    txa
    jsr xf_hexify
    tax
    pla
    rts



xf_set_charset:
    lda #1
    jmp x16::Kernal::SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_reset_charset:
    lda #2
    jmp x16::Kernal::SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

xf_clear_screen:
    VERA_SET_ADDR $1B000,1
    ldy #64 ; rows
@row:
    ldx #128 ; columns
@column:
    lda #32 ; empty tile
    sta Vera::Reg::Data0
    lda #%00000001 ; (BBBB|FFFF) background and foreground colors
    sta Vera::Reg::Data0
    dex
    bne @column
    dey
    bne @row

    rts

xf_set_vera_data_txtcoords: ; .x = col (eor #$FF x coord for color attribute)
                            ; .y = row, .a = stride, clobbers a
    cmp #$00
    bmi @negative_stride
    asl
    asl
    asl
    asl
    ora #$01
    bra @continue
@negative_stride:
    eor #$FF
    inc
    asl
    asl
    asl
    asl
    ora #$09
@continue:
    sta Vera::Reg::AddrH
    tya
    clc
    adc #$B0
    sta Vera::Reg::AddrM

    txa
    bpl @char
    eor #$FF
    asl
    inc
    bra @col
@char:
    asl
@col:
    sta Vera::Reg::AddrL
    rts
