.proc decrement_mix
    lda SeqState::mix
    beq :+
        dec
    :
    sta SeqState::mix
    inc redraw
    rts
.endproc
