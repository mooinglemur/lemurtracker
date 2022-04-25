.scope Clipboard

base_bank: .res 1

content_type: .res 1
x_width: .res 1
y_height: .res 1

;00 - content_type
;       00 - effectively empty clipboard
;       01 - pattern
;       02 - sequencer


; temp space
tmp_paste_buffer: .res 8
.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2
tmp1: .res 1
.popseg

sel_x_iterator: .res 1
sel_y_iterator: .res 1
clip_x_iterator: .res 1
clip_y_iterator: .res 1

set_ram_bank:
    lda base_bank
    sta x16::Reg::RAMBank
    rts


set_lookup_addr:
    stz lookup_addr
    stz lookup_addr+1

    jsr set_ram_bank

    sty lookup_addr

    ; multiply by 64 (8 channels, 8 bytes per entry)
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    ; column/channel, multiply by 8
    txa
    asl
    asl
    asl
    clc
    adc lookup_addr
    sta lookup_addr
    lda lookup_addr+1
    adc #$A0 ; high ram start page
    sta lookup_addr+1

    rts


copy_grid_cells:

    ; if there's no selection, force select the currently active cell
    lda Grid::selection_active
    bne @selection_found
    lda #2
    sta Grid::selection_active
    lda Grid::x_position
    sta Grid::selection_left_x
    sta Grid::selection_right_x
    lda Grid::y_position
    sta Grid::selection_top_y
    sta Grid::selection_bottom_y
    inc redraw
@selection_found:
    lda Grid::selection_left_x
    sta sel_x_iterator
    lda Grid::selection_top_y
    sta sel_y_iterator
    stz clip_x_iterator
    stz clip_y_iterator
@loop:
    ; copy the current cell to the buffer
    ldx sel_x_iterator
    ldy sel_y_iterator
    jsr Grid::set_lookup_addr

    ldy #0
    :
        lda (Grid::lookup_addr),y
        sta tmp_paste_buffer,y
        iny
        cpy #8
        bcc :-

    ldx clip_x_iterator
    ldy clip_y_iterator
    jsr set_lookup_addr

    ldy #0
    :
        lda tmp_paste_buffer,y
        sta (lookup_addr),y

        iny
        cpy #8
        bcc :-

    ; increment x
    inc clip_x_iterator
    inc sel_x_iterator
    lda sel_x_iterator
    cmp Grid::selection_right_x
    beq @loop
    bcc @loop

    lda clip_x_iterator
    sta x_width

    ; reset x and increment y at the right edge of the selection
    stz clip_x_iterator
    lda Grid::selection_left_x
    sta sel_x_iterator

    inc clip_y_iterator
    inc sel_y_iterator

    ; check y bounds
    lda sel_y_iterator
    cmp Grid::selection_bottom_y
    beq @loop
    bcc @loop

    ; we've completed the copy operation
    ; or cop-eration for short
    lda sel_y_iterator
    sta y_height

    rts

paste_cells:  ; .A bitfield
              ; 0 merge paste,
              ; 1 paste notes
              ; 2 paste instruments
              ; 3 paste volumes
              ; 4 paste effects
    sta tmp1

    


    rts

.endscope
