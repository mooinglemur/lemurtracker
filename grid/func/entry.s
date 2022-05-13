entry:
    sta tmp1

    stz GridState::selection_active

    ldx GridState::x_position
    ldy GridState::y_position
    jsr GridState::set_lookup_addr

    lda GridState::cursor_position
    cmp #3
    beq @insth
    cmp #4
    beq @instl
    cmp #5
    bne :+
        jmp @vol
    :
    cmp #6
    bne :+
        jmp @eff
    :
    cmp #7
    bne :+
        jmp @effh
    :
    jmp @effl
@end:
    inc redraw
    rts
@savecell:
    pha
    ldx GridState::x_position
    ldy GridState::y_position
    jsr Undo::store_grid_cell
    jsr Undo::mark_checkpoint

    ldx GridState::x_position
    ldy GridState::y_position
    jsr GridState::set_lookup_addr

    pla
    rts
@insth: ; changing the instrument high nybble
    lda (GridState::lookup_addr)
    beq @end
    lda tmp1
    jsr @key_to_hexh
    cmp #$ff
    beq @end
    jsr @savecell
    sta tmp2
    ldy #1
    lda (GridState::lookup_addr),y
    and #$0f
    ora tmp2
    cmp #$ff ; max instrument is fe
    bne :+
        dec
    :
    sta (GridState::lookup_addr),y
    sta InstState::y_position
    jsr increment_cursor
    bra @end
@instl: ; changing the instrument low nybble
    lda (GridState::lookup_addr)
    beq @end
    lda tmp1
    jsr @key_to_hex
    cmp #$ff
    beq @end
    jsr @savecell
    sta tmp2
    ldy #1
    lda (GridState::lookup_addr),y
    and #$f0
    ora tmp2
    cmp #$ff ; max instrument is fe
    bne :+
        dec
    :
    sta (GridState::lookup_addr),y
    sta InstState::y_position
    jsr increment_y_steps_strict
    jsr decrement_cursor
    bra @end
@vol: ; changing the volume
    lda tmp1
    jsr @key_to_vol
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    ldy #2
    sta (GridState::lookup_addr),y
    jsr increment_y_steps_strict
    jmp @end
@eff: ; changing the effect opcode
    lda tmp1
    jsr @key_to_eff
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    ldy #3
    sta (GridState::lookup_addr),y
    cmp #0
    bne :+
        iny
        sta (GridState::lookup_addr),y
        iny
        sta (GridState::lookup_addr),y
        jsr increment_y_steps_strict
        jmp @end
    :
    jsr increment_cursor
    jmp @end
@effh: ; changing the effect high nybble
    ldy #3 ; don't allow entry unless an effect opcode exists
    lda (GridState::lookup_addr),y
    bne :+
        jmp @end
    :

    lda tmp1
    cmp #$89
    bne :+
        jsr decrement_cursor
        lda #$89
        jmp @eff
    :
    jsr @key_to_hexh
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    sta tmp2
    ldy #4
    lda (GridState::lookup_addr),y
    and #$0f
    ora tmp2
    sta (GridState::lookup_addr),y
    jsr increment_cursor
    jmp @end
@effl: ; changing the effect low nybble
    ldy #3 ; don't allow entry unless an effect opcode exists
    lda (GridState::lookup_addr),y
    bne :+
        jmp @end
    :


    lda tmp1
    cmp #$89
    bne :+
        jsr decrement_cursor
        jsr decrement_cursor
        lda #$89
        jmp @eff
    :
    jsr @key_to_hex
    cmp #$ff
    bne :+
        jmp @end
    :
    jsr @savecell
    sta tmp2
    ldy #4
    lda (GridState::lookup_addr),y
    and #$f0
    ora tmp2
    sta (GridState::lookup_addr),y
    jsr increment_y_steps_strict
    jsr decrement_cursor
    jsr decrement_cursor
    jmp @end
@key_to_hexh:
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @kthhnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@kthhnum:
    sec
    sbc #$30
    asl
    asl
    asl
    asl
    rts
@returnff:
    lda #$ff
    rts
@key_to_hex:
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @kthnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@kthnum:
    sec
    sbc #$30
    rts
@return0:
    lda #0
    rts
@key_to_vol: ; returns n+1 or 0 for delete
    cmp #$89
    beq @return0
    cmp #$30
    bcc @returnff
    cmp #$3A
    bcc @ktvnum
    cmp #$41
    bcc @returnff
    cmp #$47
    bcs @returnff
    sec
    sbc #$07
@ktvnum:
    sec
    sbc #$2F
    rts
@key_to_eff:
    cmp #$89
    beq @return0
    cmp #$30
    beq @return0 ; 0 = empty effect
    bcc @returnff
    cmp #$3A
    bcc @return
    cmp #$41
    bcc @returnff
    cmp #$5B
    bcs @returnff
@return:
    rts
