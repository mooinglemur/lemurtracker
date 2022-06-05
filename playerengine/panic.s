.proc panic
    lda PlayerEngine::base_bank
    sta X16::Reg::RAMBank

    ; clear all mappings
    lda #$FF

    sta pcm_slot_to_channel
    sta pcm_slot_to_instrument

    ldx #0
    :
        sta psg_slot_to_channel,x
        sta psg_slot_to_instrument,x
        sta ym_slot_to_channel,x
        sta ym_slot_to_instrument,x
        inx
        cpx #8
        bcc :-
    :
        sta psg_slot_to_channel,x
        sta psg_slot_to_instrument,x
        inx
        cpx #16
        bcc :-

    ; reset all effects
    ldx #0
    :
        lda #0
        sta channel_volume_rate_sub,x
        sta channel_volume_rate,x
        sta channel_volume_sub,x

        sta channel_pitch_rate_sub,x
        sta channel_pitch_rate,x
        sta channel_pitch_target,x
        sta channel_pitch_sub,x
        sta channel_pitch,x

        sta channel_finepitch_rate_sub,x
        sta channel_finepitch_rate,x
        sta channel_finepitch_target,x
        sta channel_finepitch_sub,x
        sta channel_finepitch,x

        sta channel_vibrato_rate_sub,x
        sta channel_vibrato_rate,x
        sta channel_vibrato_target,x
        sta channel_vibrato_sub,x
        sta channel_vibrato,x

        sta channel_tremolo_rate_sub,x
        sta channel_tremolo_rate,x
        sta channel_tremolo_target,x
        sta channel_tremolo_sub,x
        sta channel_tremolo,x

        sta channel_portamento,x

        lda #$7F
        sta channel_volume,x
        sta channel_volume_target,x

        lda #$FF
        sta channel_to_instrument,x

        inx
        cpx #GridState::NUM_CHANNELS
        bcc :-

    ; set all PSG volumes to zero
    VERA_SET_ADDR Vera::VRAM_psg+2, 4
    ldx #16
    :
        stz Vera::Reg::Data0
        dex
        bne :-

    ; fast release and key off on all 8 YM voices
    ldx #YM2151::Reg::D1L_RR
    lda #$FF
    :
        jsr ym_wait
        stx X16::Reg::YM2151::Ctrl
        nop
        nop
        sta X16::Reg::YM2151::Data
        inx
        bmi :-

    lda #YM2151::Reg::KON
    sta X16::Reg::YM2151::Ctrl
    ldx #0
    :
        jsr ym_wait
        stx X16::Reg::YM2151::Data
        inx
        cmp #8
        bcc :-
    rts

.endproc
