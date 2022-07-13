.proc tick

check_playback_start:
    lda xf_state
    cmp #XF_STATE_PLAYBACK_START
    bne check_playback

    jsr panic
    inc redraw

    lda #$FF
    sta PlayerState::delay_sub
    sta PlayerState::delay

    jsr load_row

    lda #XF_STATE_PLAYBACK
    sta xf_state
check_playback:
    lda xf_state
    cmp #XF_STATE_PLAYBACK
    bne check_playback_stop
   

    lda PlayerState::base_bank
    sta X16::Reg::RAMBank
    dec PlayerState::delay
    bpl :+
        jsr Grid::Func::increment_y_without_starting_selection
        jsr load_row
    :

    bra end

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


.proc finalize_tick
    ;
    rts
.endproc
