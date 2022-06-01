.proc tick

check_playback_start:
    lda xf_state
    cmp #XF_STATE_PLAYBACK_START
    bne check_playback

    jsr panic


    lda #XF_STATE_PLAYBACK
    sta xf_state
check_playback:
    lda xf_state
    cmp #XF_STATE_PLAYBACK
    bne check_playback_stop



    jsr Grid::Func::increment_y_without_starting_selection

check_playback_stop:
    lda xf_state
    cmp #XF_STATE_PLAYBACK_STOP
    bne end

    jsr panic
    lda #XF_STATE_GRID
    sta xf_state
    inc redraw
end:
    rts
.endproc
