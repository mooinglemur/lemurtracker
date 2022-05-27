advance_undo_pointer: ; affects .A
    ; check to see if the next event is going to wrap around the buffer
    lda lookup_addr
    cmp #$F0
    bne @no_wrap
    lda lookup_addr+1
    cmp #$BF
    bne @no_wrap
    ; we are going to wrap
    stz lookup_addr
    lda #$A0
    sta lookup_addr+1
    inc current_bank_offset
    lda current_bank_offset
    cmp #NUM_BANKS
    bcc @ptr_advanced
    stz current_bank_offset
    bra @ptr_advanced
@no_wrap:
    lda lookup_addr
    clc
    adc #16
    sta lookup_addr
    lda lookup_addr+1
    adc #0
    sta lookup_addr+1
@ptr_advanced:
    jsr set_ram_bank
    rts
