.proc tick
    lda xf_state
    cmp #XF_STATE_PLAYBACK
    bne end

    lda framecounter
    and #7
    bne end

    jsr Grid::Func::increment_y_without_starting_selection

end:
    rts
.endproc
