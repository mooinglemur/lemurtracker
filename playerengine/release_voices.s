.proc release_voices; x = channel
    ; if channel was not in use, just return
    lda channel_to_instrument,x
    cmp #$FF
    beq end

    stx ltmp1

    lda #0
    sta channel_trigger,x
    sta channel_note,x

    lda #0
    sta channel_repatch,x

    lda #$FF
    sta channel_to_instrument,x

    ; first, release FM
    ldy #0
fm_loop:
    lda ym_slot_to_channel,y
    cmp ltmp1
    bne :+
        lda #0
        sta ym_slot_to_channel,y
        sta ym_slot_to_instrument,y
        jsr ym_wait
        lda #YM2151::Reg::KON
        sta X16::Reg::YM2151::Ctrl
        nop
        nop
        sty X16::Reg::YM2151::Data
    :
    iny
    cpy #8
    bcc fm_loop


    ; and cut PSG
    ldy #0
    VERA_SET_ADDR Vera::VRAM_psg+2, 4
psg_loop:
    lda psg_slot_to_channel,y
    cmp ltmp1
    bne :+
        lda #0
        sta psg_slot_to_channel,y
        sta psg_slot_to_instrument,y
        stz Vera::Reg::Data0
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
