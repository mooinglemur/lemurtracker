.proc panic
    lda PlayerState::base_bank
    sta X16::Reg::RAMBank

    ; clear all mappings
    lda #$FF

    sta PlayerState::pcm_slot_to_channel
    sta PlayerState::pcm_slot_to_instrument

    ldx #0
    :
        sta PlayerState::psg_slot_to_channel,x
        sta PlayerState::psg_slot_to_instrument,x
        sta PlayerState::ym_slot_to_channel,x
        sta PlayerState::ym_slot_to_instrument,x
        inx
        cpx #8
        bcc :-
    :
        sta PlayerState::psg_slot_to_channel,x
        sta PlayerState::psg_slot_to_instrument,x
        inx
        cpx #16
        bcc :-

    ; reset all effects
    ldx #0
    :
        lda #0
        sta PlayerState::channel_volume_rate_sub,x
        sta PlayerState::channel_volume_rate,x
        sta PlayerState::channel_volume_sub,x

        sta PlayerState::channel_pitch_rate_sub,x
        sta PlayerState::channel_pitch_rate,x
        sta PlayerState::channel_pitch_target,x
        sta PlayerState::channel_pitch_sub,x
        sta PlayerState::channel_pitch,x

        sta PlayerState::channel_finepitch_rate_sub,x
        sta PlayerState::channel_finepitch_rate,x
        sta PlayerState::channel_finepitch_target,x
        sta PlayerState::channel_finepitch_sub,x
        sta PlayerState::channel_finepitch,x

        sta PlayerState::channel_vibrato_rate_sub,x
        sta PlayerState::channel_vibrato_rate,x
        sta PlayerState::channel_vibrato_target,x
        sta PlayerState::channel_vibrato_sub,x
        sta PlayerState::channel_vibrato,x

        sta PlayerState::channel_tremolo_rate_sub,x
        sta PlayerState::channel_tremolo_rate,x
        sta PlayerState::channel_tremolo_target,x
        sta PlayerState::channel_tremolo_sub,x
        sta PlayerState::channel_tremolo,x

        sta PlayerState::channel_portamento,x

        lda #$7F
        sta PlayerState::channel_volume,x
        sta PlayerState::channel_volume_target,x

        lda #$FF
        sta PlayerState::channel_to_instrument,x

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
