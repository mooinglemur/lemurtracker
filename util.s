.scope Util

tmp1: .res 1
tmp2: .res 1
tmp3: .res 1
tmp4: .res 1
tmp5: .res 1
tmp6: .res 1
tmp7: .res 1

byte_to_hex: ; converts a number to two ASCII/PETSCII hex digits: input A = number to convert, output A = most sig nybble, X = least sig nybble, affects A,X
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

byte_to_hex_in_grid: ; converts a number to two ASCII/PETSCII hex digits: input A = number to convert, output A = most sig nybble, X = least sig nybble, affects A,X
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

hex_char_to_nybble:
    sec
    sbc #$30
    cmp #$0A
    bcc @end
    sbc #$07
    cmp #$10
    bcc @end
    sbc #$20
@end:
    rts

set_charset:
    lda #1
    jmp X16::Kernal::SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

reset_charset:
    lda #2
    jmp X16::Kernal::SCREEN_SET_CHARSET ; jmp replaces jsr followed by rts

clear_screen:
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

set_vera_data_txtcoords: ; .x = col (eor #$FF x coord for color attribute)
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

.proc zero_hiram
    lda #0
    ldy #0
outerloop:
    ldx #1
middleloop:
    stx X16::Reg::RAMBank
innerloop:
    sta $A000,y
    INDEX1 = (*-1)
    sta $A100,y
    INDEX2 = (*-1)
    dey
    bne innerloop
    inx
    cpx #64
    bcc middleloop

    ldx INDEX2
    inx
    cpx #$C0
    bcs end
    stx INDEX1
    inx
    stx INDEX2
    bra outerloop
end:
    ; just in case we run this routine more than once, self-mod back to original
    ldx #$A0
    stx INDEX1
    inx
    stx INDEX2

    rts
.endproc

.include "util/dialog.s"
.include "util/cursor.s"

.endscope
