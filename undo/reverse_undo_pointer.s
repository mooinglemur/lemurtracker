reverse_undo_pointer: ; affects .A, we run this after applying an undo event
    ; check to see if the next event is going to wrap around the buffer
    lda lookup_addr
    bne @no_wrap
    lda lookup_addr+1
    cmp #$A0
    bne @no_wrap
    ; we are going to wrap
    lda #$F0
    sta lookup_addr
    lda #$BF
    sta lookup_addr+1
    dec current_bank_offset
    bpl @ptr_advanced
    lda #(NUM_BANKS-1)
    sta current_bank_offset
    bra @ptr_advanced
@no_wrap:
    lda lookup_addr
    sec
    sbc #16
    sta lookup_addr
    lda lookup_addr+1
    sbc #0
    sta lookup_addr+1
@ptr_advanced:
    jsr set_ram_bank
    rts
