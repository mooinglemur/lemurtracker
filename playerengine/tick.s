.proc tick

check_playback_start:
    lda xf_state
    cmp #XF_STATE_PLAYBACK_START
    bne check_playback

    jsr panic
    inc redraw

    lda #$FF
    sta delay_sub
    sta delay

    jsr play_row

    lda #XF_STATE_PLAYBACK
    sta xf_state
check_playback:
    lda xf_state
    cmp #XF_STATE_PLAYBACK
    bne check_playback_stop

    lda base_bank
    sta X16::Reg::RAMBank
    dec delay
    bpl :+
        jsr Grid::Func::increment_y_without_starting_selection
        jsr play_row
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


;; temp
.proc play_row
    lda base_bank
    sta X16::Reg::RAMBank

    lda speed_sub
    clc
    adc delay_sub
    sta delay_sub
    lda speed
    adc delay
    sta delay

    rts
.endproc
