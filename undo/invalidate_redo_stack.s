invalidate_redo_stack:
    lda lookup_addr
    pha
    lda lookup_addr+1
    pha
    lda current_bank_offset
    pha

@loop:
    ;return if zero
    lda redo_size
    bne @continue_loop
    lda redo_size+1
    bne @continue_loop
    bra @end
@continue_loop:
    jsr advance_undo_pointer
    ldy #1
    lda (lookup_addr),y
    cmp #1
    bne @continue_loop
    lda #0
    sta (lookup_addr),y

    lda redo_size
    sec
    sbc #1
    sta redo_size
    lda redo_size+1
    sbc #0
    sta redo_size+1
    bra @loop
@end:
    pla
    sta current_bank_offset
    pla
    sta lookup_addr+1
    pla
    sta lookup_addr
    rts
