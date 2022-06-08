.proc assign_voice_ym; in: .A = instrument number, .X = channel,
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

    ; find a free slot
    ldy #0
    :
        lda PlayerState::ym_slot_to_channel,y
        cmp #$FF
        beq found
        iny
        cpy #8
        bcc :-

    ; didn't find one, find a voice not in our channel that's released
    ldy #0
    :
        lda PlayerState::ym_slot_to_channel,y
        cmp tmp_channel
        beq :+
        cmp PlayerState::ym_slot_playing,y
        beq found
    :
        iny
        cpy #8
        bcc :--

    ; didn't find one, steal one arbitrarily that's not in our channel
    ldx #8
    :
        inc PlayerState::theft
        lda PlayerState::theft
        and #$07
        tay
        lda PlayerState::ym_slot_to_channel,y
        cmp tmp_channel
        bne found
        dex
        bne :-

    ; we didn't find anything eligible, give up
    jmp end

found:
    lda PlayerState::ym_slot_to_channel,y
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
    sta PlayerState::ym_rl_fb_con,y

    lda ltmpb+1 ; Volume envelope
    sta PlayerState::ym_slot_volume_envelope_index,y

    lda ltmpb+2 ; Pitch envelope
    sta PlayerState::ym_slot_pitch_envelope_index,y

    lda ltmpb+3 ; Fineptch envelope
    sta PlayerState::ym_slot_finepitch_envelope_index,y

    lda #0
    sta PlayerState::ym_slot_playing,y
    lda tmp_channel
    sta PlayerState::ym_slot_to_channel,y
    lda tmp_instrument
    sta PlayerState::ym_slot_to_instrument,y

    phy
    ; now load the FM parameters into the buffer
    jsr InstState::set_fm_bank
    ldy #0
    :
        lda (InstState::lookup_addr),y
        sta ltmpb,y
        iny
        cpy #32
        bcc :-
    ply
    ; switch back to playerengine bank
    lda PlayerState::base_bank
    sta X16::Reg::RAMBank

    ; copy FM parameters to YM shadow
    lda ltmpb+0 ; PMS
    sta PlayerState::ym_pms,y

    lda ltmpb+1 ; AMS
    sta PlayerState::ym_ams,y

    lda ltmpb+8 ; DT1_MUL M1
    sta PlayerState::ym_dt1_mul,y
    lda ltmpb+9 ; DT1_MUL M2
    sta PlayerState::ym_dt1_mul+8,y
    lda ltmpb+10 ; DT1_MUL C1
    sta PlayerState::ym_dt1_mul+16,y
    lda ltmpb+11 ; DT1_MUL C2
    sta PlayerState::ym_dt1_mul+24,y

    lda ltmpb+12 ; TL M1
    sta PlayerState::ym_tl,y
    lda ltmpb+13 ; TL M2
    sta PlayerState::ym_tl+8,y
    lda ltmpb+14 ; TL C1
    sta PlayerState::ym_tl+16,y
    lda ltmpb+15 ; TL C2
    sta PlayerState::ym_tl+24,y

    lda ltmpb+16 ; KS_AR M1
    sta PlayerState::ym_ks_ar,y
    lda ltmpb+17 ; KS_AR M2
    sta PlayerState::ym_ks_ar+8,y
    lda ltmpb+18 ; KS_AR C1
    sta PlayerState::ym_ks_ar+16,y
    lda ltmpb+19 ; KS_AR C2
    sta PlayerState::ym_ks_ar+24,y

    lda ltmpb+20 ; AMSEN_D1R M1
    sta PlayerState::ym_amsen_d1r,y
    lda ltmpb+21 ; AMSEN_D1R M2
    sta PlayerState::ym_amsen_d1r+8,y
    lda ltmpb+22 ; AMSEN_D1R C1
    sta PlayerState::ym_amsen_d1r+16,y
    lda ltmpb+23 ; AMSEN_D1R C2
    sta PlayerState::ym_amsen_d1r+24,y

    lda ltmpb+24 ; DT2_D2R M1
    sta PlayerState::ym_dt2_d2r,y
    lda ltmpb+25 ; DT2_D2R M2
    sta PlayerState::ym_dt2_d2r+8,y
    lda ltmpb+26 ; DT2_D2R C1
    sta PlayerState::ym_dt2_d2r+16,y
    lda ltmpb+27 ; DT2_D2R C2
    sta PlayerState::ym_dt2_d2r+24,y

    lda ltmpb+28 ; D1L_RR M1
    sta PlayerState::ym_d1l_rr,y
    lda ltmpb+29 ; D1L_RR M2
    sta PlayerState::ym_d1l_rr+8,y
    lda ltmpb+30 ; D1L_RR C1
    sta PlayerState::ym_d1l_rr+16,y
    lda ltmpb+31 ; D1L_RR C2
    sta PlayerState::ym_d1l_rr+24,y

end:
    rts
tmp_channel: .res 1
tmp_instrument: .res 1
ltmpb: .res 32
.endproc
