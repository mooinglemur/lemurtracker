.scope Grid

NUM_CHANNELS = 8

; vars that keep state
x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
cursor_position: .res 1 ; within the column (channel) where is the cursor?
global_frame_length: .res 1 ; set on file create/file load
base_bank: .res 1 ; where does tracker data start
channel_to_pattern: .res NUM_CHANNELS ; which pattern is referenced in each channel
notechardata: .res 9*NUM_CHANNELS ; temp storage for characters based on pattern data
iterator: .res 1

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
.popseg

; vars that affect entry
octave: .res 1
step: .res 1






draw: ; affects A,X,Y,xf_tmp1,xf_tmp2,xf_tmp3

    ; Top of grid
    VERA_SET_ADDR ($0206+$1B000),2

    ;lda #$A3
    ;sta VERA_data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_TOP_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_TOP
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_TOP_RIGHT
    sta Vera::Reg::Data0


    ; cycle through 40 rows
    ; start on row 3
    lda #3
    sta xf_tmp1
    lda y_position
    sec
    sbc #20
    sta xf_tmp2
    stz xf_tmp3

@rowstart:
    lda #(1 | $10) ; high bank, stride = 1
    sta $9F22

    lda xf_tmp1 ; row number
    clc
    adc #$b0
    sta $9F21

    lda #2 ; one character over
    sta $9F20

    lda xf_tmp3
    beq :+
        jmp @blankrow
    :

    lda xf_tmp2
    ldy xf_tmp1
    cpy #23
    bcs :++
        cmp y_position
        bcc :+
            jmp @blankrow
        :
        bra @filledrow
    :

    ldy xf_tmp2
    cpy global_frame_length
    bne :+
        inc xf_tmp3
    :
    cmp y_position
    bcs @filledrow

@filledrow:
    jsr xf_byte_to_hex
    ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    stx Vera::Reg::Data0
    sty Vera::Reg::Data0

    ; fetch note data from hiram. we can clobber registers here
    stz iterator

@fetch_notedata_loop:
    ldx iterator
    lda channel_to_pattern,x ; which pattern are we loading
    ; for simplicity, we're doing one bank per multitrack pattern
    clc
    adc base_bank
    sta x16::Reg::RAMBank
    lda xf_tmp2 ; the row we're drawing
    sta lookup_addr
    stz lookup_addr+1
    ; multiply by 64 (8 channels, 8 bytes per entry)
    ; .C will be clear here
    rol lookup_addr
    rol lookup_addr+1
    rol lookup_addr
    rol lookup_addr+1
    rol lookup_addr
    rol lookup_addr+1
    rol lookup_addr
    rol lookup_addr+1
    rol lookup_addr
    rol lookup_addr+1
    rol lookup_addr
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

    txa
    asl
    asl
    asl
    clc
    adc iterator
    tax

    ldy #0
    lda (lookup_addr),y
    ; note
    bne @note_exists

    lda #CustomChars::NOTE_DOT
    sta notechardata,x
    lda #'.'
    sta notechardata+1,x
    sta notechardata+2,x
    sta notechardata+3,x
    sta notechardata+4,x
    bra @get_effect

@note_exists:
    ldy #0
    sec
@note_and_octave_loop: ; after this loop, A will contain the note and Y will contain the octave
    cmp #24
    bcc @found_octave
    iny
    sbc #12
    bra @note_and_octave_loop
@found_octave:
    phy
    sec
    sbc #12
    tay
    lda note_val,y
    sta notechardata,x
    lda note_sharp,y
    sta notechardata+1,x
    ply
    lda note_octave,y
    sta notechardata+2,x

@get_instrument_number:

    ldy #1
    lda (lookup_addr),y
    phx
    jsr xf_byte_to_hex
    ply
    phx
    phy
    plx
    sta notechardata+3,x
    pla
    sta notechardata+4,x
@get_volume: ; byte should be 1-16 and displayed value should be shifted down one
    lda #'.'
    sta notechardata+5,x
    ldy #2
    lda (lookup_addr),y
    beq :+
        phx
        dec
        jsr xf_byte_to_hex
        txa
        plx
        sta notechardata+5,x
    :
@get_effect:
    ldy #3
    lda (lookup_addr),y
    bne :+
        lda #'.'
        sta notechardata+6,x
        sta notechardata+7,x
        sta notechardata+8,x
        bra @end_column
    :
    sta notechardata+6,x
@get_effect_arg:
    ldy #4
    lda (lookup_addr),y
    phx
    jsr xf_byte_to_hex
    ply
    phx
    phy
    plx
    sta notechardata+7,x
    pla
    sta notechardata+8,x


@end_column:
    inc iterator
    lda iterator
    cmp #NUM_CHANNELS
    bcs :+
        jmp @fetch_notedata_loop
    :

    ldy #(XF_BASE_BG_COLOR | XF_BASE_FG_COLOR)

    ; color current row
    lda xf_tmp2
    cmp y_position
    bne :+
        ldy #(XF_AUDITION_BG_COLOR | XF_BASE_FG_COLOR)
        bra @got_color
    :
    ; color every 16 rows
    lda xf_tmp2
    and #%11110000
    cmp xf_tmp2
    bne :+
        ldy #(XF_HILIGHT_BG_COLOR_2 | XF_BASE_FG_COLOR)
        bra @got_color
    :
    ; color every 4 rows
    lda xf_tmp2
    and #%11111100
    cmp xf_tmp2
    bne :+
        ldy #(XF_HILIGHT_BG_COLOR_1 | XF_BASE_FG_COLOR)
        bra @got_color
    :

@got_color:

    ldx #0
    :
        lda notechardata,x
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        inx
        cpx #NUM_CHANNELS*9
        bcc :-



    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sty Vera::Reg::Data0

    bra @endofrow
@blankrow:
    lda #$20
    ldy #%00000001 ; color value for blank row is 0 bg, 1 fg
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0
    sta Vera::Reg::Data0
    sty Vera::Reg::Data0

    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_LEFT
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        lda #' '
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_RIGHT
    sta Vera::Reg::Data0
    ldy #(XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)
    sty Vera::Reg::Data0

@endofrow:
    lda xf_tmp3
    bne :+
        inc xf_tmp2


    :
    inc xf_tmp1
    lda xf_tmp1
    cmp #43
    bcs :+
        jmp @rowstart
    :
; bottom of grid


    VERA_SET_ADDR ($2B06+$1B000),2
    ldx #NUM_CHANNELS
    :
        lda #CustomChars::GRID_BOTTOM_LEFT
        sta Vera::Reg::Data0
        lda #CustomChars::GRID_BOTTOM
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
        dex
        bne :-
    lda #CustomChars::GRID_BOTTOM_RIGHT
    sta Vera::Reg::Data0




; now put the cursor where it belongs
    lda #(1 | $20) ; high page, stride = 2
    sta $9F22

    lda #23 ; row number
    clc
    adc #$b0
    sta $9F21

    lda x_position
    asl
    asl
    asl
    clc
    adc x_position

    clc
    adc cursor_position
    adc #3
    asl
    inc

    sta $9F20

    lda #(XF_CURSOR_BG_COLOR | XF_BASE_FG_COLOR)
    sta Vera::Reg::Data0

    ldy cursor_position
    bne :+
        sta Vera::Reg::Data0
        sta Vera::Reg::Data0
    :



;    lda #$81
;    sta VERA_data0
;    lda #$91
;    sta VERA_data0



;@colorcursorline:
;    lda #(0 | $20) ; low page, stride = 2
;    sta $9F22
;
;    lda #23; row number
;    sta $9F21
;
;    lda #7 ; address color memory inside grid
;    sta $9F20
;
;    ldx #70
;    lda #%00100001
;    :
;        sta VERA_data0
;        dex
;        bne :-
;
    rts


note_val:    .byte CustomChars::NOTE_C,CustomChars::NOTE_C,CustomChars::NOTE_D
             .byte CustomChars::NOTE_D,CustomChars::NOTE_E,CustomChars::NOTE_F
             .byte CustomChars::NOTE_F,CustomChars::NOTE_G,CustomChars::NOTE_G
             .byte CustomChars::NOTE_A,CustomChars::NOTE_A,CustomChars::NOTE_B
note_sharp:  .byte "-#-#--#-#-#-"
note_octave: .byte "0123456789"

.endscope
