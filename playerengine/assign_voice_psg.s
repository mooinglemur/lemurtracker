.proc assign_voice_psg ; .A = instrument number, .X = channel,
    sta tmp_instrument
    stx tmp_channel

    ; copy the instrument state out
    ldy #$10
    ldx #0
    :
        lda (InstState::lookup_addr),y
        sta ltmpb,x
        inx
        iny
        cpy #$16
        bcc :-

    ; we're now in the playerengine bank for the rest of the routine
    lda PlayerState::base_bank
    sta X16::Reg::RAMBank

    ; find a free slot
    ldy #0
    :
        lda PlayerState::psg_slot_to_channel,y
        cmp #$FF
        beq found
        iny
        cpy #16
        bcc :-

    ; didn't find one, find a voice not in our channel that's released
    ldy #0
    :
        lda PlayerState::psg_slot_to_channel,y
        cmp tmp_channel
        beq :+
        cmp PlayerState::psg_slot_playing,y
        beq found
    :
        iny
        cpy #16
        bcc :--

    ; didn't find one, steal one arbitrarily that's not in our channel
    ldx #16
    :
        inc PlayerState::theft
        lda PlayerState::theft
        and #$0F
        tay
        lda PlayerState::psg_slot_to_channel,y
        cmp tmp_channel
        bne found
        dex
        bne :-

    ; we didn't find anything eligible, give up
    bra end

found:
    lda PlayerState::psg_slot_to_channel,y
    cmp #$FF
    beq :+
        phy
        tya
        tax
        jsr release_voices ; invalidate the instrument and release all voices
                           ; in the channel whose voice we're stealing
        ply
    :

    lda ltmpb
    and #%11000000
    clc
    rol
    rol
    rol
    sta PlayerState::psg_rl,y

    lda ltmpb
    and #%00000011
    sta PlayerState::psg_wf,y

    lda ltmpb+1 ; Volume envelope
    sta PlayerState::psg_slot_volume_envelope_index,y

    lda ltmpb+2 ; Pitch envelope
    sta PlayerState::psg_slot_pitch_envelope_index,y

    lda ltmpb+3 ; Fineptch envelope
    sta PlayerState::psg_slot_finepitch_envelope_index,y

    lda ltmpb+4 ; Duty envelope
    sta PlayerState::psg_slot_duty_envelope_index,y

    lda ltmpb+5 ; Waveform envelope
    sta PlayerState::psg_slot_waveform_envelope_index,y

    lda #0
    sta PlayerState::psg_slot_playing,y
    lda tmp_channel
    sta PlayerState::psg_slot_to_channel,y
    lda tmp_instrument
    sta PlayerState::psg_slot_to_instrument,y

end:
    rts
tmp_channel: .res 1
tmp_instrument: .res 1
ltmpb: .res 8
.endproc
