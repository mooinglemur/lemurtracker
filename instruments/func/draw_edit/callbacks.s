.proc lbracket_callback
    ldx #'['
    bra bracket_callback
.endproc

.proc rbracket_callback
    ldx #']'
.endproc

.proc bracket_callback
    sta tmp
    ldy #$10
    lda (InstState::lookup_addr),y
    and #3
    cmp tmp
    beq :+
        ldx #' '
    :
    txa
    rts
    tmp: .res 1
.endproc
