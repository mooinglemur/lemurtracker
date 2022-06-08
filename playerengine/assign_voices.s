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






.proc assign_voice_ymnoise

    rts
ltmpb: .res 8
.endproc
