increment_mix:
    lda SeqState::mix
    inc
    cmp #SeqState::MIX_LIMIT
    bcc :+
        dec
    :
    sta SeqState::mix
    inc redraw
    rts
