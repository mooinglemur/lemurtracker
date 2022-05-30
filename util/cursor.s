.proc cursor    ; .x = lsb of data structure, y = msb of data structure
                ; .a = cursor position
                ; clobbers:
                ;  zp_tmp1/zp_tmp2: structure ptr
                ;  Util::tmp1: row offset
                ;  Util::tmp2: column offset
                ;  Util::tmp3: cursor position (field offset)
                ;  Util::tmp4: cursor length
                ; structure:
                ;   start_y, start_x
                ;   [row,col,length]...

    stx zp_tmp1            ;
    sty zp_tmp2
    sta tmp3

    lda (zp_tmp1)
    sta tmp1
    ldy #1
    lda (zp_tmp1),y
    sta tmp2

    ; multiply by 3
    lda tmp3
    asl
    clc
    adc tmp3
    ; offset
    adc #2
    tay
    lda (zp_tmp1),y
    adc tmp1
    sta tmp1
    iny
    lda (zp_tmp1),y
    adc tmp2
    sta tmp2
    iny
    lda (zp_tmp1),y
    sta tmp4

    lda tmp2
    eor #$FF
    tax
    ldy tmp1
    lda #2
    jsr set_vera_data_txtcoords

    ldx tmp4
    lda #(XF_NOTE_ENTRY_BG_COLOR|XF_BASE_FG_COLOR)
    :
        sta Vera::Reg::Data0
        dex
        bne :-

    rts
.endproc
