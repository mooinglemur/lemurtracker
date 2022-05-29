.proc dialog ; .x = lsb of data structure, y = msb of data structure
                ;
                ; clobbers:
                ;  zp_tmp1/zp_tmp2: structure ptr
                ;  zp_tmp3/zp_tmp4: text ptr
                ;  Util::tmp1: row offset
                ;  Util::tmp2: column offset
                ;  Util::tmp3: final row offset
                ;  Util::tmp4: final column offset
                ;  Util::tmp5: dialog color
                ;  Util::tmp6: saved struct offset
                ;  Util::tmp7: scratch
                ;
                ; structure:
                ;   start_y, start_x. y_offset, x_offset, color
                ;   element_type, [args]
                ;
                ;   element types:
                ; 0 = done
                ; 1 = separator - args = y_offset
                ; 2 = text - args = y_offset, x_offset, lsb, msb, color, max_len
                ; 3 = indirect_text - args = y offset, x offset, zp, offset, color, max_len
                ; 4 = hex byte - args = y offset, x offset, lsb, msb, color, FF is null?
                ; 5 = hex byte indirect - args = y offset, x offset, zp, offset, color, FF is null?
                ; 6 = tick - args = y offset, x offset, lsb, msb, color, mask
                ; 7 = tick indirect - args = y offset, x offset, zp, offset, color, mask

    stx zp_tmp1
    sty zp_tmp2

    ; set vera pointer to top left of dialog
    ldy #1
    lda (zp_tmp1),y
    tax
    lda (zp_tmp1)
    tay
    lda #1
    jsr set_vera_data_txtcoords

    ; fill tmp3-tmp5 with values from structure
    ldy #2
    lda (zp_tmp1),y
    sta tmp3

    iny
    lda (zp_tmp1),y
    sta tmp4

    iny
    lda (zp_tmp1),y
    sta tmp5
    tax

    ; draw entire top of dialog
    ; upper left corner
    lda #CustomChars::BOX_UL
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #CustomChars::BOX_HORIZONTAL
    ldy #1
    sty tmp1 ; steal this #1 as the row offset for the next section
    ; top horizontal line
    :
        cpy tmp4
        beq :+
            bcs :++
        :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        bra :--
    :

    lda #CustomChars::BOX_UR
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; set up main loop
    lda #5 ; first element
    sta tmp6

mainloop: ; outer loop, once per row
    ; set vera pointer to beginning of row
    ldy #1
    lda (zp_tmp1),y
    tax
    lda (zp_tmp1)
    clc
    adc tmp1
    tay
    lda #1
    jsr set_vera_data_txtcoords

    lda tmp1
    cmp tmp3
    beq :+
        bcc :+
        jmp bottom_row
    :

    ldy tmp6
    lda (zp_tmp1),y ; element type
    cmp #1
    bne regular_row ; not separator
    iny
    lda (zp_tmp1),y ; is separator, check to see if it's for this row
    cmp tmp1
    bne regular_row
separator_row:
    ; draw left side
    lda #CustomChars::BOX_TLEFT
    ldx tmp5
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda #CustomChars::BOX_HORIZONTAL
    ldy #1
    ; horizontal line
    :
        cpy tmp4
        beq :+
            bcs :++
        :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        bra :--
    :

    ; right side
    lda #CustomChars::BOX_TRIGHT
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    inc tmp6
    inc tmp6 ; advance to next element
    inc tmp1 ; and advance to next line
    bra mainloop

regular_row:
    ; draw left side vertical bar
    lda #CustomChars::BOX_VERTICAL
    ldx tmp5
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    ldx #1
    stx tmp2

inner_loop:
    lda tmp2
    cmp tmp4
    beq :+
        bcc :+
        jmp finish_row
    :

    ; get next element
    ldy tmp6
    lda (zp_tmp1),y
    bne :+
        jmp finish_row
    :
    iny
    lda (zp_tmp1),y
    cmp tmp1
    beq :+
        bcc :+
        jmp finish_row
    :
    iny
    lda (zp_tmp1),y
    cmp tmp2
    beq :+
        ; We should be on the same line as the element, but not there yet
        ; plot a space character
        lda #$20
        ldx tmp5
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        inc tmp2
        bra inner_loop
    :
    ; We are now on a row/column where this element starts
    ldy tmp6
    lda (zp_tmp1),y
    cmp #2
    beq element_text
    cmp #3
    beq element_indirect_text
    cmp #4
    beq element_hex
    cmp #5
    beq element_hex_indirect
    cmp #6
    beq element_tick
    cmp #7
    beq element_tick_indirect
    jmp end ; panic return, shouldn't ever get here, but an unfinished dialog would be a clue that we did
element_text:
    jsr dialog_set_lookup
    bra do_text
element_indirect_text:
    jsr dialog_set_lookup_indirect
    bra do_text
element_hex:
    jsr dialog_set_lookup
    bra do_hex
element_hex_indirect:
    jsr dialog_set_lookup_indirect
    bra do_hex
element_tick:
    jsr dialog_set_lookup
    jmp do_tick
element_tick_indirect:
    jsr dialog_set_lookup_indirect
    jmp do_tick
do_text:
    lda tmp6
    clc
    adc #5
    tay
    lda (zp_tmp1),y ; color
    tax
    iny
    lda (zp_tmp1),y ; max length
    sta tmp7

    ldy #0
textloop:
    cpy tmp7
    bcs endtext

    lda (zp_tmp3),y
    beq spaceloop

    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    iny
    inc tmp2
    bra textloop
spaceloop:
    cpy tmp7
    bcs endtext
    lda #$20
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    iny
    inc tmp2
    bra spaceloop
endtext:
    lda tmp6
    clc
    adc #7
    sta tmp6
    jmp inner_loop
do_hex:
    inc tmp2
    inc tmp2
    lda tmp6
    clc
    adc #5
    tay
    lda (zp_tmp1),y ; color
    tax
    iny
    lda (zp_tmp1),y ; null flag (do we treat FF as null?)
    sta tmp7

    lda (zp_tmp3)
    cmp #$FF
    bne :+
        lda tmp7
        beq :+
        lda #'.' ; show null value and move on
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        bra endtext
    :

    stx tmp7 ; save color here because x will get clobbered
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0 ; most significant nybble
    lda tmp7
    sta Vera::Reg::Data0 ; color
    stx Vera::Reg::Data0 ; least significant nybble
    sta Vera::Reg::Data0 ; color
    bra endtext
do_tick:
    inc tmp2
    lda tmp6
    clc
    adc #5
    tay
    lda (zp_tmp1),y ; color
    tax
    iny
    lda (zp_tmp3)
    and (zp_tmp1),y ; AND mask to indicate whether tick should be on
    bne :+
        lda #$20 ; show space (no tick)
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        bra endtext
    :
    lda #'x' ; show tick
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0
    bra endtext

finish_row:
    ldy tmp2
    lda #$20 ; space
    ldx tmp5

    ; fill out the dialog's interior with space on this row
    :
        cpy tmp4
        beq :+
            bcs :++
        :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        bra :--
    :

    lda #CustomChars::BOX_VERTICAL
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    inc tmp1 ; advance to next line
    jmp mainloop

bottom_row:
    ; draw entire bottom of dialog
    ; lower left corner
    lda #CustomChars::BOX_LL
    sta Vera::Reg::Data0
    ldx tmp5
    stx Vera::Reg::Data0

    lda #CustomChars::BOX_HORIZONTAL
    ldy #1
    ; bottom horizontal line
    :
        cpy tmp4
        beq :+
            bcs :++
        :
        sta Vera::Reg::Data0
        stx Vera::Reg::Data0
        iny
        bra :--
    :

    lda #CustomChars::BOX_LR
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

end:
    rts

dialog_set_lookup:
    lda tmp6
    clc
    adc #3
    tay
    lda (zp_tmp1),y
    sta zp_tmp3
    iny
    lda (zp_tmp1),y
    sta zp_tmp4
    rts

dialog_set_lookup_indirect:
    lda tmp6
    clc
    adc #3
    tay
    lda (zp_tmp1),y ; returns zeropage location containing base address
    sta zp_tmp3
    stz zp_tmp4
    iny
    lda (zp_tmp1),y ; offset into text field
    sta tmp7 ; temp location
    lda (zp_tmp3) ; LSB of actual text address
    clc
    adc tmp7 ; immediately add offset, .A is now is absolute LSB
    pha ; stash it
    ldy #1
    lda (zp_tmp3),y ; MSB of actual text address
    adc #0 ; add carry if appropriate
    sta zp_tmp4 ; store MSB
    pla
    sta zp_tmp3 ; restore and store LSB
    rts

.endproc
