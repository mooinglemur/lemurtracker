.proc name_entry
    ; The name takes up the first half of the instrument
    ; so we only need to store the undo state of the first two regions
    ldy InstState::y_position
    lda #0
    jsr Undo::store_instrument ; 1/2
    ldy InstState::y_position
    lda #8
    jsr Undo::store_instrument ; 2/2

    jsr Undo::mark_checkpoint

    ldy InstState::y_position
    jsr InstState::set_lookup_addr

    ldy #1
    ldx #0
    :
        lda TextField::textfield,x
        sta (InstState::lookup_addr),y
        inx
        iny
        cpy #$10
        bcc :-

end:
    inc redraw
    rts
.endproc
