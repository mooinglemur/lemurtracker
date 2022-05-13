get_first_unused_patterns:
    jsr SeqState::set_ram_bank
    stz SeqState::lookup_addr
    lda #$A0
    sta SeqState::lookup_addr+1

    ; zero out tmp8b
    lda #0
    ldy #0
    :
        sta tmp8b,y
        iny
        cpy #8
        bcc :-
@mainloop:
    ldy #0
@rowloop:
    lda (SeqState::lookup_addr),y
    cmp #$ff
    beq @next
    cmp tmp8b,y
    bcc @next
    cmp SeqState::max_pattern
    bcc :+
        lda SeqState::max_pattern
        dec
    :
    sta tmp8b,y
@next:
    iny
    cpy #8
    bcc @rowloop
    lda SeqState::lookup_addr
    clc
    adc #8
    sta SeqState::lookup_addr
    lda SeqState::lookup_addr+1
    adc #0
    cmp #$C0
    bcs @end
    sta SeqState::lookup_addr+1
    bra @mainloop
@end:
    rts
