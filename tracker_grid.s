.scope Grid

NUM_CHANNELS = 8

; vars that keep state
x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
cursor_position: .res 1 ; within the column (channel) where is the cursor?
global_frame_length: .res 1 ; set on file create/file load
base_bank: .res 1 ; where does tracker data start
channel_to_pattern: .res NUM_CHANNELS ; which pattern is referenced in each channel
notedata: .res 9*NUM_CHANNELS ; temp storage for characters based on pattern data
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
    adc #base_bank
    sta x16::Reg::RAMBank
    lda xf_tmp2 ; the row we're drawing
    sta lookup_addr
    stz lookup_addr+1
    ; multiply by 64 (8 channels, 8 bytes per entry)
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
    adc #0 ; not sure if...
    sta lookup_addr+1 ; ...these are needed since we shouldn't wrap

    ldy #0
    lda (lookup_addr),y
    ; note








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
        lda #CustomChars::NOTE_DOT
        sta Vera::Reg::Data0
        sty Vera::Reg::Data0
        lda #'.'
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
        inx
        cpx #NUM_CHANNELS
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


note_val:    .byte 1
note_sharp:  .byte 1
note_octave: .byte $30,$31,$32,$33,$34,$35,$36,$37

.endscope
