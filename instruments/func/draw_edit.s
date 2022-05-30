EDITBOX_X = 22
EDITBOX_Y = 18

.include "func/draw_edit/callbacks.s"
.include "func/draw_edit/psg_instrument.s"

.proc draw_edit
    ldy InstState::y_position
    jsr InstState::set_lookup_addr
    lda (InstState::lookup_addr)
    sta InstState::edit_instrument_type
    beq draw_edit_new_instrument
    cmp #1
    bne :+
        jmp draw_edit_psg_instrument
    :
    cmp #2
    bne :+
        jmp draw_edit_ym_instrument
    :
    cmp #3
    bne :+
        jmp draw_edit_ymnoise_instrument
    :
    cmp #4
    bne :+
        jmp draw_edit_multi_instrument
    :


    ; fall back to inst
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw

    rts

.endproc

.proc draw_edit_new_instrument
    ldx #<dialog
    ldy #>dialog
    jsr Util::dialog

cursor:
    lda InstState::edit_field_idx
    clc
    adc #EDITBOX_Y+3
    tay
    lda #EDITBOX_X+1
    eor #$FF
    tax
    lda #2
    jsr Util::set_vera_data_txtcoords
    lda #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
    ldx #16
    :
        sta Vera::Reg::Data0 ; color
        dex
        bne :-


end:
    rts

dialog: .byte EDITBOX_Y,EDITBOX_X,6,16
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

        .byte 2,1,1
        .word text1
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),15

        .byte 1,2 ; separator

        .byte 2,3,1
        .word text2
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),15

        .byte 2,4,1
        .word text3
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),15

        .byte 2,5,1
        .word text4
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),15

        .byte 2,6,1
        .word text5
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),15

        .byte 0

text1: .asciiz "New Instrument"
text2: .asciiz "VERA PSG"
text3: .asciiz "YM2151 (OPM) FM"
text4: .asciiz "YM2151 NOISE"
text5: .asciiz "Multilayered"

.endproc


.proc draw_edit_ym_instrument
    rts
.endproc

.proc draw_edit_ymnoise_instrument
    rts
.endproc

.proc draw_edit_multi_instrument
    rts
.endproc
