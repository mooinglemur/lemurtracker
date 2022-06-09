.proc assign_voice_ymnoise; in: .A = instrument number, .X = channel,
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

    ; we're now in the playerengine bank until we need to copy the YM data out
    lda PlayerState::base_bank
    sta X16::Reg::RAMBank

    ; make sure that if the noise-capable voice is in use that it isn't in our channel
    lda PlayerState::ym_slot_to_channel+7
    cmp tmp_channel
    bne found
    jmp end

found:
    lda PlayerState::ym_slot_to_channel+7
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
    sta PlayerState::ym_rl_fb_con+7

    lda ltmpb+1 ; Volume envelope
    sta PlayerState::ym_slot_volume_envelope_index+7

    lda ltmpb+2 ; Pitch envelope
    sta PlayerState::ym_slot_pitch_envelope_index+7

    lda ltmpb+3 ; Fineptch envelope
    sta PlayerState::ym_slot_finepitch_envelope_index+7

    lda ltmpb+4 ; Nosiefreq envelope
    sta PlayerState::ymnoise_slot_noisefreq_envelope_index

    lda #0
    sta PlayerState::ym_slot_playing+7
    lda tmp_channel
    sta PlayerState::ym_slot_to_channel+7
    lda tmp_instrument
    sta PlayerState::ym_slot_to_instrument+7


    ; now load the FM parameters into the buffer
    jsr InstState::set_fm_bank
    ldy #0
    :
        lda (InstState::lookup_addr),y
        sta ltmpb,y
        iny
        cpy #32
        bcc :-

    ; switch back to playerengine bank
    lda PlayerState::base_bank
    sta X16::Reg::RAMBank

    ; copy FM parameters to YM shadow
    lda ltmpb+0 ; PMS
    sta PlayerState::ym_pms+7

    lda ltmpb+1 ; AMS
    sta PlayerState::ym_ams+7

    lda ltmpb+8 ; DT1_MUL M1
    sta PlayerState::ym_dt1_mul+7
    lda ltmpb+9 ; DT1_MUL M2
    sta PlayerState::ym_dt1_mul+8+7
    lda ltmpb+10 ; DT1_MUL C1
    sta PlayerState::ym_dt1_mul+16+7
    lda ltmpb+11 ; DT1_MUL C2
    sta PlayerState::ym_dt1_mul+24+7

    lda ltmpb+12 ; TL M1
    sta PlayerState::ym_tl+7
    lda ltmpb+13 ; TL M2
    sta PlayerState::ym_tl+8+7
    lda ltmpb+14 ; TL C1
    sta PlayerState::ym_tl+16+7
    lda ltmpb+15 ; TL C2
    sta PlayerState::ym_tl+24+7

    lda ltmpb+16 ; KS_AR M1
    sta PlayerState::ym_ks_ar+7
    lda ltmpb+17 ; KS_AR M2
    sta PlayerState::ym_ks_ar+8+7
    lda ltmpb+18 ; KS_AR C1
    sta PlayerState::ym_ks_ar+16+7
    lda ltmpb+19 ; KS_AR C2
    sta PlayerState::ym_ks_ar+24+7

    lda ltmpb+20 ; AMSEN_D1R M1
    sta PlayerState::ym_amsen_d1r+7
    lda ltmpb+21 ; AMSEN_D1R M2
    sta PlayerState::ym_amsen_d1r+8+7
    lda ltmpb+22 ; AMSEN_D1R C1
    sta PlayerState::ym_amsen_d1r+16+7
    lda ltmpb+23 ; AMSEN_D1R C2
    sta PlayerState::ym_amsen_d1r+24+7

    lda ltmpb+24 ; DT2_D2R M1
    sta PlayerState::ym_dt2_d2r+7
    lda ltmpb+25 ; DT2_D2R M2
    sta PlayerState::ym_dt2_d2r+8+7
    lda ltmpb+26 ; DT2_D2R C1
    sta PlayerState::ym_dt2_d2r+16+7
    lda ltmpb+27 ; DT2_D2R C2
    sta PlayerState::ym_dt2_d2r+24+7

    lda ltmpb+28 ; D1L_RR M1
    sta PlayerState::ym_d1l_rr+7
    lda ltmpb+29 ; D1L_RR M2
    sta PlayerState::ym_d1l_rr+8+7
    lda ltmpb+30 ; D1L_RR C1
    sta PlayerState::ym_d1l_rr+16+7
    lda ltmpb+31 ; D1L_RR C2
    sta PlayerState::ym_d1l_rr+24+7

    ; activate the noise enable bit, and flush it to the YM
    lda PlayerState::ym_ne
    ora #$80
    sta PlayerState::ym_ne

    ldx #YM2151::Reg::NE_NFRQ

    jsr ym_wait
    stx X16::Reg::YM2151::Ctrl
    nop
    nop
    sta X16::Reg::YM2151::Data


end:
    rts
tmp_channel: .res 1
tmp_instrument: .res 1
ltmpb: .res 32
.endproc
