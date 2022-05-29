
.proc draw
    ; Top of grid
    ldy #DEBUGPANEL_LOCATION_Y
    sty y_position
    stz tmp1

    ; do all of the headings
headingloop:
    ldx #DEBUGPANEL_LOCATION_X
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda tmp1
    asl
    asl
    tay
    lda headings,y
    beq values


    sta Vera::Reg::Data0
    lda headings+1,y
    sta Vera::Reg::Data0
    lda headings+2,y
    sta Vera::Reg::Data0
    lda headings+3,y
    sta Vera::Reg::Data0

    inc y_position
    inc y_position
    inc y_position
    inc tmp1
    bra headingloop


values:

    ; Stat
    ldx #(DEBUGPANEL_LOCATION_X+2)
    ldy #DEBUGPANEL_LOCATION_Y
    iny
    sty y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda xf_state
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; PS/2
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda KeyboardState::scancode+1
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda KeyboardState::scancode
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; ModK
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X+2)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda KeyboardState::modkeys
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; Undo
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda Undo::undo_size+1
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Undo::undo_size
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; Redo
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda Undo::redo_size+1
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Undo::redo_size
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; UnBk
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X+2)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda Undo::current_bank_offset
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; UnPt
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda Undo::lookup_addr+1
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda Undo::lookup_addr
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    ; FrCt
    inc y_position
    inc y_position
    inc y_position
    ldx #(DEBUGPANEL_LOCATION_X)
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda framecounter+1
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0

    lda framecounter
    jsr Util::byte_to_hex
    sta Vera::Reg::Data0
    stx Vera::Reg::Data0


    rts


tmp1: .res 1

headings: .byte "Stat","PS/2","ModK","Undo","Redo","UnBk","UnPt","FrCt",$00

.endproc
