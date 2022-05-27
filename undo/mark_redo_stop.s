mark_redo_stop: ; affects .A, .Y
    ; this does nothing but ensure the next event slot is marked as a stop point
    ; so that redo stops at the right point


    ; temporarily advance the pointer
    jsr advance_undo_pointer
    ; if we're clobbering a start point, we need to decrement our undo stack
    ldy #1
    lda (lookup_addr),y
    cmp #1
    bne :+
    ;; actually, if undo_size does dip below zero, it means we've wrapped around
    ;; and stored more data in one group than can fit in the entire buffer
    ;; so I think we actually want to allow it to drop below zero

        lda undo_size
        sec
        sbc #1
        sta undo_size
        lda undo_size+1
        sbc #0
        sta undo_size+1
    :

    ; mark the stop point

    lda #0
    sta (lookup_addr),y

    ; restore the old pointer
    jsr reverse_undo_pointer

    rts
