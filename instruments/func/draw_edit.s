EDITBOX_X = 22
EDITBOX_Y = 18

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

.proc draw_edit_psg_instrument

    ldx #<dialog
    ldy #>dialog
    jsr Util::dialog

    rts


dialog: .byte EDITBOX_Y,EDITBOX_X,8,24
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

        .byte 2,1,1
        .word text1
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),4

        .byte 3,1,6
        .byte InstState::lookup_addr,1
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),15

        .byte 2,1,22
        .word text2
        .byte $D0,3

        .byte 2,2,1
        .word text3
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),6

        .byte 7,2,7
        .byte InstState::lookup_addr,$10
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),$80

        .byte 2,2,8
        .word text4
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),10

        .byte 7,2,18
        .byte InstState::lookup_addr,$10
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),$40

        .byte 2,2,19
        .word text5
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),1

        .byte 2,3,1
        .word text6
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),8

        .byte 2,4,1
        .word text7
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),12

        .byte 5,4,16
        .byte InstState::lookup_addr,$11
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,5,1
        .word text8
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),11

        .byte 5,5,16
        .byte InstState::lookup_addr,$12
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,6,1
        .word text9
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),10

        .byte 5,6,16
        .byte InstState::lookup_addr,$13
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,7,1
        .word text10
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),10

        .byte 5,7,16
        .byte InstState::lookup_addr,$14
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,8,1
        .word text11
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),14

        .byte 5,8,16
        .byte InstState::lookup_addr,$15
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 0

text1: .asciiz "Name"
text2: .asciiz "PSG"
text3: .asciiz "Left ["
text4: .asciiz "]  Right ["
text5: .asciiz "]"
text6: .asciiz "Waveform"
text7: .asciiz "Volume Macro"
text8: .asciiz "Pitch Macro"
text9: .asciiz "Fine Macro"
text10:.asciiz "Duty Macro"
text11:.asciiz "Waveform Macro"

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
