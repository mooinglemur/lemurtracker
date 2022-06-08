.proc release_voices; x = channel
    ; if channel was not in use, just return
    lda PlayerState::channel_to_instrument,x
    cmp #$FF
    beq end

    stx ltmp1

    lda #0
    sta PlayerState::channel_trigger,x
    sta PlayerState::channel_note,x

    lda #0
    sta PlayerState::channel_repatch,x

    lda #$FF
    sta PlayerState::channel_to_instrument,x

    ; first, release FM
    ldy #0
fm_loop:
    lda PlayerState::ym_slot_to_channel,y
    cmp ltmp1
    bne :+
        lda #$FF
        sta PlayerState::ym_slot_to_channel,y
        sta PlayerState::ym_slot_to_instrument,y
        jsr ym_wait
        lda #YM2151::Reg::KON
        sta X16::Reg::YM2151::Ctrl
        nop
        nop
        sty X16::Reg::YM2151::Data
        lda #0
        sta PlayerState::ym_slot_playing,y
    :
    iny
    cpy #8
    bcc fm_loop


    ; and cut PSG
    ldy #0
    VERA_SET_ADDR Vera::VRAM_psg+2, 4
psg_loop:
    lda PlayerState::psg_slot_to_channel,y
    cmp ltmp1
    bne :+
        lda #$FF
        sta PlayerState::psg_slot_to_channel,y
        sta PlayerState::psg_slot_to_instrument,y
        stz Vera::Reg::Data0
        lda #0
        sta PlayerState::psg_slot_playing,y
        bra end_psg_loop
    :
    lda Vera::Reg::Data0 ; advance Data0 ptr
end_psg_loop:
    iny
    cpy #16
    bcc psg_loop



end:
    rts
ltmp1: .res 1
.endproc
