EDITBOX_X = 22
EDITBOX_Y = 10

.proc draw_edit
    ldy InstState::y_position
    jsr InstState::set_lookup_addr
    lda (InstState::lookup_addr)
    beq draw_edit_new_instrument
    cmp #1
    beq draw_edit_psg_instrument
    cmp #2
    beq draw_edit_ym_instrument

    ; fall back to inst
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw

    rts

.endproc

.proc draw_edit_new_instrument
    VERA_SET_ADDR ((EDITBOX_Y*256)+((EDITBOX_X)*2)+Vera::VRAM_text),2

    lda #CustomChars::BOX_UL
    sta Vera::Reg::Data0
    ldx #32
    lda #CustomChars::BOX_HORIZONTAL
    :
        sta Vera::Reg::Data0
        dex
        bne :-

    lda #CustomChars::BOX_UR
    sta Vera::Reg::Data0

    rts
.endproc

.proc draw_edit_psg_instrument
    rts
.endproc

.proc draw_edit_ym_instrument
    rts
.endproc
