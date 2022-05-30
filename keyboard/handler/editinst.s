.include "editinst/psg.s"

.proc editinst
    lda InstState::edit_instrument_type
    cmp #1
    bne :+
        jmp editinst_psg
    :
    cmp #2
    bne :+
        jmp editinst_ym
    :
    cmp #3
    bne :+
        jmp editinst_ymnoise
    :
    cmp #4
    bne :+
        jmp editinst_multi
    :

    ; No instrument selected, select which instrument

    jsr decode_scancode
    ldy #(fntbl-ktbl)
loop:
    lda keycode
    cmp ktbl-1,y
    beq match
    dey
    bne loop
    bra nomatch
match:
    dey
    tya
    asl
    tax
    jmp (fntbl,x)
nomatch:
entry:
noentry:
end:
    rts
ktbl:
    ; this is the static keymapping
    ;     ent esc up  dn
    .byte $0D,$1B,$80,$81
fntbl:
    .word key_enter
    .word key_esc
    .word key_up
    .word key_dn
key_enter:
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    lda InstState::edit_field_idx
    inc
    jmp Dispatch::set_instrument_type
key_esc:
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
key_up:
    lda InstState::edit_field_idx
    beq :+
        dec InstState::edit_field_idx
    :
    inc redraw
    rts
key_dn:
    lda InstState::edit_field_idx
    cmp #3
    beq :+
        inc InstState::edit_field_idx
    :
    inc redraw
    rts
.endproc



.proc editinst_ym
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
.endproc

.proc editinst_ymnoise
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
.endproc

.proc editinst_multi
    lda #XF_STATE_INSTRUMENTS
    sta xf_state
    inc redraw
    rts
.endproc
