mark_checkpoint: ; no inputs, we call this to mark the last undo event as
                 ; the final event in a series that will get undone as a group
                 ; if the undo is called
    lda #1
    sta checkpoint
    clc
    adc undo_size
    sta undo_size
    lda undo_size+1
    adc #0
    sta undo_size+1

    rts
