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
    ldx #EDITBOX_X+4
    stx tmp1
    ldy #EDITBOX_Y
    sty tmp2
    stz tmp3

loop:
    lda tmp3
    asl
    tax
    lda texts,x
    sta xf_tmp1
    lda texts+1,x
    beq cursor
    sta xf_tmp2

    ldx tmp1
    ldy tmp2
    lda #1
    jsr xf_set_vera_data_txtcoords

    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    ldy #0

    :
        lda (xf_tmp1),y
        beq :+
        sta Vera::Reg::Data0 ; character
        stx Vera::Reg::Data0 ; color
        iny
        bra :-
    :

    inc tmp2
    inc tmp3
    bra loop
cursor:
    lda InstState::edit_field_idx
    clc
    adc #EDITBOX_Y+3
    tay
    lda #EDITBOX_X+5
    eor #$FF
    tax
    lda #2
    jsr xf_set_vera_data_txtcoords
    lda #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
    ldx #16
    :
        sta Vera::Reg::Data0 ; color
        dex
        bne :-


end:
    rts
texts: .word top,text1,divider,text2,text3,text4,text5,bottom,0
top:   .byte CustomChars::BOX_UL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_UR,0
text1: .byte CustomChars::BOX_VERTICAL,"New Instrument  ",CustomChars::BOX_VERTICAL,0
divider: .byte CustomChars::BOX_TLEFT,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
         .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
         .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
         .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
         .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
         .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_TRIGHT,0
text2: .byte CustomChars::BOX_VERTICAL,"VERA PSG        ",CustomChars::BOX_VERTICAL,0
text3: .byte CustomChars::BOX_VERTICAL,"YM2151 (OPM) FM ",CustomChars::BOX_VERTICAL,0
text4: .byte CustomChars::BOX_VERTICAL,"YM2151 NOISE    ",CustomChars::BOX_VERTICAL,0
text5: .byte CustomChars::BOX_VERTICAL,"Multilayered    ",CustomChars::BOX_VERTICAL,0
bottom:.byte CustomChars::BOX_LL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL
       .byte CustomChars::BOX_HORIZONTAL,CustomChars::BOX_HORIZONTAL,CustomChars::BOX_LR,0


.endproc

.proc draw_edit_psg_instrument
    ldx #EDITBOX_X
    stx tmp1
    ldy #EDITBOX_Y
    sty tmp2
    stz tmp3

    ; header
    lda #1
    jsr xf_set_vera_data_txtcoords
    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    lda #CustomChars::BOX_UL
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #CustomChars::BOX_HORIZONTAL
    ldy #24
    :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        dey
        bne :-

    lda #CustomChars::BOX_UR
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; name line
    ldx tmp1
    inc tmp2
    ldy tmp2
    lda #1
    jsr xf_set_vera_data_txtcoords

    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

    lda #CustomChars::BOX_VERTICAL
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ldy #0
    :
        lda text1,y
        beq :+
        sta Vera::Reg::Data0 ; character
        stx Vera::Reg::Data0 ; color
        iny
        bra :-
    :

    ; name field itself
    ldx #(XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR)
    ldy #1
    :
        lda (InstState::lookup_addr),y
        beq :+
        sta Vera::Reg::Data0 ; character
        stx Vera::Reg::Data0 ; color
        iny
        cpy #16
        bcc :-
    :

    ; name field pad out the nulls with spaces
    lda #$20
    :
        cpy #16
        bcs :+
        sta Vera::Reg::Data0 ; character
        stx Vera::Reg::Data0 ; color
        iny
        bra :-
    :

    ; instrument type
    lda (InstState::lookup_addr)
    asl
    asl
    tay
    ldx #0
    :
        lda InstState::instrument_type,y
        sta Vera::Reg::Data0 ; character
        lda InstState::instrument_type_color,y
        sta Vera::Reg::Data0 ; color
        iny
        inx
        cpx #4
        bcc :-

    ldx #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    lda #CustomChars::BOX_VERTICAL
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0


    rts

text1: .asciiz "Name:"
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
