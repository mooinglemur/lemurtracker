.proc assign_voices ; a = instrument number, x = channel number
    stx ltmp1
    sta ltmp2

    tay
    jsr InstState::set_lookup_addr
    lda (InstState::lookup_addr) ; instrument type
    beq end ; empty instrument, notes are going into the ether
    ldx ltmp1
    cmp #1
    bne :+
        lda ltmp2
        jmp assign_voice_psg
    :
    cmp #2
    bne :+
        lda ltmp2
        jmp assign_voice_ym
    :
    cmp #3
    bne :+
        lda ltmp2
        jmp assign_voice_ymnoise
    :
    cmp #4
    bne end ; unsupported type

    ; multilayered instrument, we must call assign for each one
    lda #$10
    sta ltmp3 ; layered instrument index starts at $10
layer_loop:
    ldy ltmp2
    jsr InstState::set_lookup_addr
    ldy ltmp3
    lda (InstState::lookup_addr),y ; instrument number
    sta ltmp4
    cmp #$FF
    beq layer_loop_end
    tay
    jsr InstState::set_lookup_addr
    lda (InstState::lookup_addr) ; instrument type
    beq layer_loop_end
    ldx ltmp1
    cmp #1
    bne :+
        lda ltmp4
        jmp assign_voice_psg
    :
    cmp #2
    bne :+
        lda ltmp4
        jmp assign_voice_ym
    :
    cmp #3
    bne :+
        lda ltmp4
        jmp assign_voice_ymnoise
    :
    ; every other instrument type invalid, including nested layer
layer_loop_end:
    inc ltmp3
    lda ltmp3
    cmp #$18 ; layered instrument index stops at $17
    bcc layer_loop

end:
    rts
ltmp1: .res 1 ; channel
ltmp2: .res 1 ; master instrument
ltmp3: .res 1 ; layer index when looping
ltmp4: .res 1 ; layer sub-instrument
.endproc


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
    lda base_bank
    sta X16::Reg::RAMBank

    ; find a free slot
    ldy #0
    :
        lda psg_slot_to_channel,y
        beq found
        iny
        cpy #16
        bcc :-

    ; didn't find one, find a voice not in our channel that's released
    ldy #0
    :
        lda psg_slot_to_channel,y
        cmp tmp_channel
        beq :+
        cmp psg_slot_playing,y
        beq found
    :
        iny
        cpy #16
        bcc :--

    ; didn't find one, steal one arbitrarily that's not in our channel
    ldx #16
    :
        inc theft
        lda theft
        and #$0F
        tay
        lda psg_slot_to_channel,y
        cmp tmp_channel
        bne found
        dex
        bne :-

    ; we didn't find anything eligible, give up
    bra end

found:
    lda psg_slot_to_channel,y
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
    sta psg_rl,y

    lda ltmpb
    and #%00000011
    sta psg_wf,y

    lda ltmpb+1 ; Volume envelope
    sta psg_slot_volume_envelope_index,y

    lda ltmpb+2 ; Pitch envelope
    sta psg_slot_pitch_envelope_index,y

    lda ltmpb+3 ; Fineptch envelope
    sta psg_slot_finepitch_envelope_index,y

    lda ltmpb+4 ; Duty envelope
    sta psg_slot_duty_envelope_index,y

    lda ltmpb+5 ; Waveform envelope
    sta psg_slot_waveform_envelope_index,y

    lda #0
    sta psg_slot_playing,y
    lda tmp_channel
    sta psg_slot_to_channel,y
    lda tmp_instrument
    sta psg_slot_to_instrument,y

end:
    rts
tmp_channel: .res 1
tmp_instrument: .res 1
ltmpb: .res 8
.endproc

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
    lda base_bank
    sta X16::Reg::RAMBank

    ; find a free slot
    ldy #0
    :
        lda ym_slot_to_channel,y
        beq found
        iny
        cpy #8
        bcc :-

    ; didn't find one, find a voice not in our channel that's released
    ldy #0
    :
        lda ym_slot_to_channel,y
        cmp tmp_channel
        beq :+
        cmp ym_slot_playing,y
        beq found
    :
        iny
        cpy #8
        bcc :--

    ; didn't find one, steal one arbitrarily that's not in our channel
    ldx #8
    :
        inc theft
        lda theft
        and #$07
        tay
        lda ym_slot_to_channel,y
        cmp tmp_channel
        bne found
        dex
        bne :-

    ; we didn't find anything eligible, give up
    jmp end

found:
    lda ym_slot_to_channel,y
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
    sta ym_rl,y

    lda ltmpb
    and #%00111000
    lsr
    lsr
    lsr
    sta ym_fb,y

    lda ltmpb
    and #%00000111
    sta ym_con,y

    lda ltmpb+1 ; Volume envelope
    sta ym_slot_volume_envelope_index,y

    lda ltmpb+2 ; Pitch envelope
    sta ym_slot_pitch_envelope_index,y

    lda ltmpb+3 ; Fineptch envelope
    sta ym_slot_finepitch_envelope_index,y

    lda #0
    sta ym_slot_playing,y
    lda tmp_channel
    sta ym_slot_to_channel,y
    lda tmp_instrument
    sta ym_slot_to_instrument,y

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
    lda base_bank
    sta X16::Reg::RAMBank

    ; copy FM parameters to YM shadow
    lda ltmpb+0 ; PMS
    sta ym_pms,y

    lda ltmpb+1 ; AMS
    sta ym_ams,y

    lda ltmpb+8 ; DT1_MUL (DT1) M1
    lsr
    lsr
    lsr
    lsr
    sta ym_dt1,y

    lda ltmpb+8 ; DT1_MUL (MUL) M1
    and #7
    sta ym_mul,y

    lda ltmpb+9 ; DT1_MUL (DT1) M2
    lsr
    lsr
    lsr
    lsr
    sta ym_dt1+8,y

    lda ltmpb+9 ; DT1_MUL (MUL) M2
    and #7
    sta ym_mul+8,y

    lda ltmpb+10 ; DT1_MUL (DT1) C1
    lsr
    lsr
    lsr
    lsr
    sta ym_dt1+16,y

    lda ltmpb+10 ; DT1_MUL (MUL) C1
    and #7
    sta ym_mul+16,y

    lda ltmpb+11 ; DT1_MUL (DT1) C2
    lsr
    lsr
    lsr
    lsr
    sta ym_dt1+24,y

    lda ltmpb+11 ; DT1_MUL (MUL) C2
    and #7
    sta ym_mul+24,y

    lda ltmpb+12 ; TL M1
    sta ym_tl,y

    lda ltmpb+13 ; TL M2
    sta ym_tl+8,y

    lda ltmpb+14 ; TL C1
    sta ym_tl+16,y

    lda ltmpb+15 ; TL C2
    sta ym_tl+24,y

    lda ltmpb+16 ; KS_AR (KS) M1
    clc
    rol
    rol
    rol
    sta ym_ks,y

    lda ltmpb+16 ; KS_AR (AR) M1
    and #31
    sta ym_ar,y

    lda ltmpb+17 ; KS_AR (KS) M2
    clc
    rol
    rol
    rol
    sta ym_ks+8,y

    lda ltmpb+17 ; KS_AR (AR) M2
    and #31
    sta ym_ar+8,y

    lda ltmpb+18 ; KS_AR (KS) C1
    clc
    rol
    rol
    rol
    sta ym_ks+16,y

    lda ltmpb+18 ; KS_AR (AR) C1
    and #31
    sta ym_ar+16,y

    lda ltmpb+19 ; KS_AR (KS) C2
    clc
    rol
    rol
    rol
    sta ym_ks+24,y

    lda ltmpb+19 ; KS_AR (AR) C2
    and #31
    sta ym_ar+24,y

    lda ltmpb+20 ; AMSEN_D1R (AMSEN) M1
    and #$80
    sta ym_amsen,y

    lda ltmpb+20 ; AMSEN_D1R (D1R) M1
    and #31
    sta ym_d1r,y

    lda ltmpb+21 ; AMSEN_D1R (AMSEN) M2
    and #$80
    sta ym_amsen+8,y

    lda ltmpb+21 ; AMSEN_D1R (D1R) M2
    and #31
    sta ym_d1r+8,y

    lda ltmpb+22 ; AMSEN_D1R (AMSEN) C1
    and #$80
    sta ym_amsen+16,y

    lda ltmpb+22 ; AMSEN_D1R (D1R) C1
    and #31
    sta ym_d1r+16,y

    lda ltmpb+23 ; AMSEN_D1R (AMSEN) C2
    and #$80
    sta ym_amsen+24,y

    lda ltmpb+23 ; AMSEN_D1R (D1R) C2
    and #31
    sta ym_d1r+24,y

    lda ltmpb+24 ; DT2_D2R (DT2) M1
    clc
    rol
    rol
    rol
    sta ym_dt2,y

    lda ltmpb+24 ; DT2_D2R (D2R) M1
    and #31
    sta ym_d2r,y

    lda ltmpb+25 ; DT2_D2R (DT2) M2
    clc
    rol
    rol
    rol
    sta ym_dt2+8,y

    lda ltmpb+25 ; DT2_D2R (D2R) M2
    and #31
    sta ym_d2r+8,y

    lda ltmpb+26 ; DT2_D2R (DT2) C1
    clc
    rol
    rol
    rol
    sta ym_dt2+16,y

    lda ltmpb+26 ; DT2_D2R (D2R) C1
    and #31
    sta ym_d2r+16,y

    lda ltmpb+27 ; DT2_D2R (DT2) C2
    clc
    rol
    rol
    rol
    sta ym_dt2+24,y

    lda ltmpb+27 ; DT2_D2R (D2R) C2
    and #31
    sta ym_d2r+24,y

    lda ltmpb+28 ; D1L_RR (D1L) M1
    lsr
    lsr
    lsr
    lsr
    sta ym_d1l,y

    lda ltmpb+28 ; D1L_RR (RR) M1
    and #15
    sta ym_rr,y

    lda ltmpb+29 ; D1L_RR (D1L) M2
    lsr
    lsr
    lsr
    lsr
    sta ym_d1l+8,y

    lda ltmpb+29 ; D1L_RR (RR) M2
    and #15
    sta ym_rr+8,y

    lda ltmpb+30 ; D1L_RR (D1L) C1
    lsr
    lsr
    lsr
    lsr
    sta ym_d1l+16,y

    lda ltmpb+30 ; D1L_RR (RR) C1
    and #15
    sta ym_rr+16,y

    lda ltmpb+31 ; D1L_RR (D1L) C2
    lsr
    lsr
    lsr
    lsr
    sta ym_d1l+24,y

    lda ltmpb+31 ; D1L_RR (RR) C2
    and #15
    sta ym_rr+24,y


end:
    rts
tmp_channel: .res 1
tmp_instrument: .res 1
ltmpb: .res 32
.endproc

.proc assign_voice_ymnoise

    rts
ltmpb: .res 8
.endproc
