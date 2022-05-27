unmark_checkpoint: ; if we want to chain two discrete ops in code
                   ; where the first marks a chackpoint, this function
                   ; can undo it

    lda checkpoint
    cmp #2
    beq @end

    lda #2
    sta checkpoint

    lda undo_size
    sec
    sbc #1
    sta undo_size
    lda undo_size+1
    sbc #0
    sta undo_size+1
@end:
    rts
