.proc name_entry_start ; dispatched before passing control to text entry

    lda #TextField::CONSTRAINT_ASCII
    sta TextField::constraint
    lda #TextField::ENTRYMODE_NORMAL
    sta TextField::entrymode
    stz TextField::insertmode
    stz TextField::gridmode
    lda #15
    sta TextField::width
    lda #1
    sta TextField::preserve
    ldy InstState::y_position
    jsr InstState::set_lookup_addr
    ldy #15
    ldx #14
    :
        lda (InstState::lookup_addr),y
        sta TextField::textfield,x
        dex
        dey
        bne :-
    ldx #(Instruments::Func::EDITBOX_X+7)
    ldy #(Instruments::Func::EDITBOX_Y+3)
    lda #0
    jmp TextField::start
.endproc

.proc name_entry_end ; dispatched after finalizing entry

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

    ldy #15
    ldx #14
    :
        lda TextField::textfield,x
        sta (InstState::lookup_addr),y
        dex
        dey
        bne :-

end:
    inc redraw
    rts
.endproc
