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
    bcs end ; don't append when at end
    ldy constraint
    cpy #CONSTRAINT_HEX
    beq hex
text:
    sta textfield,x
    inc cursor_position
    lda entrymode
    cmp #ENTRYMODE_FILL
    bne end
    ldx cursor_position
    cpx width
    bcc end
    clc
    jmp (callback)
hex:
    cmp #$30
    bcc end
    cmp #$3A
    bcc text
    cmp #$41
    bcc end
    cmp #$47
    bcc text
    cmp #$61
    bcc end
    cmp #$67
    bcs end
    sbc #$1F ; subtracts and extra with carry clear
    bra text
control_code:
    cmp #13 ; enter
    bne :+
        clc
        jmp (callback)
    :
    cmp #$82 ; left
    bne :+
        ldx cursor_position
        dex
        bmi end
        stx cursor_position
        bra end
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
    cmp #$1B ; ESC
    bne :+
        sec
        jmp (callback)
    :
end:
    rts
.endproc

.proc draw
    ldx x_position
    ldy y_position
    lda #2
    jsr xf_set_vera_data_txtcoords

    ldx #0
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
    jsr xf_set_vera_data_txtcoords

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
    jsr xf_set_vera_data_txtcoords
    lda #TF_CURSOR_COLOR
    sta Vera::Reg::Data0
end:
    rts





    rts

.endproc

.endscope
