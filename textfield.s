; handle arbitrary text entry, as well as restricted (hex)
.scope TextField

callback: .res 2
textfield: .res 64
width: .res 1
cursor_position: .res 1
x_position: .res 1
y_position: .res 1
constraint: .res 1
preserve: .res 1
insertmode: .res 1
entrymode: .res 1
gridmode: .res 1


tmp1: .res 1

CONSTRAINT_ASCII = 1
CONSTRAINT_HEX = 2
CONSTRAINT_FILENAME = 3

ENTRYMODE_NORMAL = 0
ENTRYMODE_FILL = 1

TF_BASE_COLOR = $91
TF_CURSOR_COLOR = $F1

.proc start
    ; expects callback, width, and constraint to be set
    ; .X and .Y contain the screen x/y text area where
    ; the field is to appear, sets state to XF_STATE_TEXT
    ; textfield and cursor will be preserved if preserve is set
    ; callback will be called: with carry set if aborted (escape)
    ; or with carry clear if the user pressed enter

    ; if .A is nonzero, treat it as the first character typed
    stx x_position
    sty y_position
    ldx preserve
    bne after_init

    stz cursor_position

    ldx #0
    :
        stz textfield,x
        inx
        cpx #64
        bcc :-

after_init:
    ldx #XF_STATE_TEXT
    stx xf_state

    cmp #0 ; .A is untouched up to this point
    beq :+
        jmp entry
    :
    rts

.endproc


.proc entry
    ; .A contains the (ascii) character or control code
    cmp #0
    bne :+
        jmp end
    :
    cmp #32
    bcc control_code
    cmp #127
    bcs control_code
    ldx cursor_position
    cpx width
    bcc :+
        jmp end ; don't append when at end
    :
    ldy constraint
    cpy #CONSTRAINT_HEX
    beq hex
text:
    ldy insertmode
    beq :++
        pha
        ldy width
        dey
        lda textfield,y
        tay
        pla
        cpy #0
        beq :+
            jmp end
        :
        jsr insert
    :
    sta textfield,x
    inc cursor_position
    lda entrymode
    cmp #ENTRYMODE_FILL
    beq :+
        jmp end
    :
    ldx cursor_position
    cpx width
    bcs :+
        jmp end
    :
    clc
    jmp (callback)
hex:
    cmp #$30
    bcs :+
        jmp end
    :
    cmp #$3A
    bcc text
    cmp #$41
    bcs :+
        jmp end
    :
    cmp #$47
    bcc text
    cmp #$61
    bcs :+
        jmp end
    :
    cmp #$67
    bcc :+
        jmp end
    :
    sbc #$1F ; subtracts an extra with carry clear
    bra text
control_code:
    cmp #13 ; enter
    bne :+
        clc
        jmp (callback)
    :

    cmp #$84 ; home
    bne :+
        stz cursor_position
        jmp end
    :

    cmp #$82 ; left
    bne :++
        ldx cursor_position
        dex
        bpl :+
            jmp end
        :
        stx cursor_position
        jmp end
    :
    cmp #$83 ; right
    bne :++
        ldx cursor_position
        lda textfield,x
        beq end
        inx
        cpx width
        beq :+
            bcs end
        :
        stx cursor_position
        bra end
    :

    cmp #$85 ; end
    bne :+++
        ldx #0
        :
            lda textfield,x
            beq :+
            inx
            cpx width
            bcc :-
        :
        stx cursor_position
        bra end
    :

    cmp #$08 ; backspace
    bne :+++
        ldx cursor_position
        beq end

        txa
        tay
        dey
        :
            cpy width
            bcs :+
            lda textfield,x
            sta textfield,y
            inx
            iny
            bra :-
        :
        stz textfield,x
        dec cursor_position
        bra end
    :

    cmp #$89 ; delete
    bne :+++
        ldx cursor_position
        cpx width
        bcs end

        txa
        tay
        inx
        :
            cpy width
            bcs :+
            lda textfield,x
            sta textfield,y
            inx
            iny
            bra :-
        :
        stz textfield,x
        bra end
    :

    cmp #$88 ; ins
    bne :+
        lda insertmode
        and #1
        eor #1
        sta insertmode
    :

    cmp #$1B ; ESC
    bne :+
        sec
        jmp (callback)
    :
end:
    rts
.endproc

.proc insert
    pha

    ldy width
    dey
    ldx width
    dex
    dex
    :
        cpy cursor_position
        beq end
        bcc end
        lda textfield,x
        sta textfield,y
        dex
        dey
        bra :-
end:
    ldx cursor_position
    pla
    rts
.endproc

.proc draw
    ldx x_position
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    ; draw first character, optionally with gridline
    lda textfield
    bne :+
        ldx gridmode
        beq end_string
    :
    ldx gridmode
    beq first_character
    ; we are in grid mode, use a grid tile if possible
    cmp #0
    bne :+ ; null
        lda #CustomChars::GRID_LEFT
        bra first_character
    :
    cmp #$20 ; space
    bne :+
        lda #CustomChars::GRID_LEFT
        bra first_character
    :
    cmp #$30 ; numeral 0
    bcc first_character
    cmp #$5B ; one after Z
    bcs first_character
    adc #$50 ; carry is clear, gets the numbers into the right range
    cmp #$8A ; letters or numbers?
    bcc first_character ; numbers, we're in the correct place
    sbc #$07 ; carry is set, we're probably a letter, so shift down to the correct place
    cmp #$8A ; are we really letters though?
    bcs first_character ; ah, we are
    sbc #$48 ; oh no, we're not letters, carry is clear so we're really subtracting $49
             ; go back to where we started
first_character:
    sta Vera::Reg::Data0
rest_of_characters:
    ldx #1
    cpx width
    beq end_field
    :
        lda textfield,x
        beq end_string
        sta Vera::Reg::Data0
        inx
        cpx width
        bcc :-
        bra end_field
end_string:
    lda #$20
    :
        sta Vera::Reg::Data0
        inx
        cpx width
        bcc :-
end_field:
    ; color it in
    lda x_position
    eor #$FF
    tax
    ldy y_position
    lda #2
    jsr Util::set_vera_data_txtcoords

    lda #TF_BASE_COLOR
    ldx #0
    :
        sta Vera::Reg::Data0
        inx
        cpx width
        bcc :-
cursor:
    lda cursor_position
    cmp width
    bcs end ; don't display the cursor if it's past the end of the window

    lda cursor_position
    clc
    adc x_position
    eor #$FF
    tax
    ldy y_position
    lda #1
    jsr Util::set_vera_data_txtcoords
    lda #TF_CURSOR_COLOR
    sta Vera::Reg::Data0
    ; insert mode indicator
    lda insertmode
    beq end

    ; blinky insert indicator
    lda framecounter
    and #32
    beq end

    lda x_position
    clc
    adc cursor_position
    tax
    ldy y_position
    lda #1
    jsr Util::set_vera_data_txtcoords
    lda #CustomChars::INSERT_INDICATOR
    sta Vera::Reg::Data0
end:
    rts
.endproc

.proc get_byte_from_hex
    lda textfield
    beq zero
    jsr Util::hex_char_to_nybble
    sta tmp1
    ldy textfield+1
    beq end
    asl
    asl
    asl
    asl
    sta tmp1
    lda textfield+1
    jsr Util::hex_char_to_nybble
    ora tmp1
    rts
zero:
    lda #0
end:
    rts
.endproc

.endscope
