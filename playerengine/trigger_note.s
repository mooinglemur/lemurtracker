.proc trigger_note ; input: .X = channel
    stx channel_num
    stz voice_idx
    ; loop through all PSG voices to see if it's in our channel
psg_voice_loop:
    ldy voice_idx
    lda PlayerState::psg_slot_to_channel,y
    cmp channel_num
    bne psg_voice_loop_end

    jsr trigger_note_psg ; input .Y = voice

psg_voice_loop_end:
    inc voice_idx
    ldy voice_idx
    cpy #16
    bcc psg_voice_loop


    ; loop through all YM voices to see if it's in our channel
    stz voice_idx
ym_voice_loop:
    ldy voice_idx
    lda PlayerState::ym_slot_to_channel,y
    cmp channel_num
    bne ym_voice_loop_end

    jsr trigger_note_ym ; input .Y = voice

ym_voice_loop_end:
    inc voice_idx
    ldy voice_idx
    cpy #8
    bcc ym_voice_loop

    rts
channel_num: .res 1
voice_idx: .res 1
.endproc