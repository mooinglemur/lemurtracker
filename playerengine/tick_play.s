.proc tick_play
    ; loop through channels
    ; if channel_trigger is 0, check to see if note is playing
    ;  if it is already in the cut state, do nothing
    ;  otherwise advance the envelopes
    ; if channel_trigger is 1, start note playback (or process release/cut) and decrement channel_trigger
    ;  if release, advance envelopes to F2 release point or end
    ; if channel_trigger > 1, decrement channel_trigger and move on


    lda PlayerState::base_bank
    sta X16::Reg::RAMBank
    stz loop_idx
    ldx loop_idx
channel_loop:        
    ; .X is already set to loop_idx here
    lda PlayerState::channel_trigger,x
    beq trigger_is_zero
    ; .A is set to channel_trigger,x
    dec PlayerState::channel_trigger,x
    bne end_loop ; channel_trigger is not zero yet even after decrement

    ; trigger note now, because channel_trigger,x was 1, and is now zero
    jsr trigger_note ; input: .X = channel number; clobbers .X, so we need to restore it afterwards
    ldx loop_idx

trigger_is_zero:
    ; trigger is 0. is note playing?
    lda PlayerState::channel_note,x
    beq end_loop ; do nothing, because note is not playing
    ; advance the envelope pointers (it also resets the *_slot_playing upon note cut/release)
    jsr advance_envelopes ; .X is the channel number

end_loop:
    inc loop_idx
    ldx loop_idx
    cpx #8
    bne channel_loop

    rts
loop_idx: .res 1
.endproc