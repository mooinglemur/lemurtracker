.proc set_modkeys
    ; sets or clears bits in the modkeys variable
    ; bit 0 - $12 - left shift
    ; bit 1 - $59 - right shift
    ; bit 2 - $14 - left ctrl
    ; bit 3 - $E0 $14 - right ctrl
    ; bit 4 - $11 - left alt
    ; bit 5 - $E0 $11 - right alt/altgr

    lda #0
    ldx scancode
    cpx #$12
    bne @not_lshift
    lda #1
    bra @end
@not_lshift:
    cpx #$59
    bne @not_rshift
    lda #2
    bra @end
@not_rshift:
    cpx #$14
    bne @not_ctrl
    lda #4
    ldx scancode+1
    cpx #$E0
    bne @end
    lda #8
    bra @end
@not_ctrl:
    cpx #$11
    bne @not_alt
    lda #16
    ldx scancode+1
    cpx #$E0
    bne @end
    lda #32
@not_alt:
@end:
    cpy #0
    beq @keydown
@keyup:
    eor #$ff
    and modkeys
    sta modkeys
    bra @exit
@keydown:
    ora modkeys
    sta modkeys
@exit:
    rts

.endproc
