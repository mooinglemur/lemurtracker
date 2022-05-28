.proc set_instrument_type
    pha ; instrument type

    sta InstState::edit_instrument_type
    inc redraw

    ; store the undo event (32 bytes takes 4 slots)

    ldy InstState::y_position
    lda #0
    jsr Undo::store_instrument ; 1/4
    ldy InstState::y_position
    lda #8
    jsr Undo::store_instrument ; 2/4
    ldy InstState::y_position
    lda #16
    jsr Undo::store_instrument ; 3/4
    ldy InstState::y_position
    lda #24
    jsr Undo::store_instrument ; 4/4

    jsr Undo::mark_checkpoint

    ldy InstState::y_position
    jsr InstState::set_lookup_addr

    pla
    beq set_instrument_type_blank

    ldy #XF_STATE_EDITINST
    sty xf_state

    cmp #1
    beq set_instrument_type_psg
    cmp #2
    beq set_instrument_type_ym
    cmp #3
    beq set_instrument_type_ymnoise
    cmp #4
    beq set_instrument_type_multi
;   bra set_instrument_type_blank
;   fall through
.endproc

.proc set_instrument_type_blank
    lda #0
    ldy #0
    :
        sta (InstState::lookup_addr),y
        iny
        cpy #32
        bcc :-

    rts
.endproc

.proc set_instrument_type_psg
    lda #1
    sta (InstState::lookup_addr) ; set instrument, preserve name if it exists
    ldy #$10
    lda %11000000 ; left+right, pulse wave
    sta (InstState::lookup_addr),y
    lda #$FF
    :
        iny
        sta (InstState::lookup_addr),y ; default macros
        cpy #$15
        bcc :-
    lda #$00
    :
        iny
        sta (InstState::lookup_addr),y ; null values
        cpy #$1F
        bcc :-
    rts
.endproc

.proc set_instrument_type_ym
    lda #2
    sta (InstState::lookup_addr) ; set instrument, preserve name if it exists
    ldy #$10
    lda %11000000 ; left+right, no feedback, alg 0
    sta (InstState::lookup_addr),y
    lda #$FF
    :
        iny
        sta (InstState::lookup_addr),y ; default macros and fm table
        cpy #$14
        bcc :-

    lda #$00
    :
        iny
        sta (InstState::lookup_addr),y ; null values
        cpy #$1F
        bcc :-
    rts
.endproc

.proc set_instrument_type_ymnoise
    lda #3
    sta (InstState::lookup_addr) ; set instrument, preserve name if it exists
    ldy #$10
    lda %11000000 ; left+right, no feedback, alg 0
    sta (InstState::lookup_addr),y
    lda #$FF
    :
        iny
        sta (InstState::lookup_addr),y ; default macros and fm table
        cpy #$14
        bcc :-

    lda #$00
    :
        iny
        sta (InstState::lookup_addr),y ; null values
        cpy #$1F
        bcc :-
    rts
.endproc

.proc set_instrument_type_multi
    lda #4
    sta (InstState::lookup_addr) ; set instrument, preserve name if it exists
    ldy #$10
    lda #$FF
    :
        iny
        sta (InstState::lookup_addr),y ; null instruments
        cpy #$17
        bcc :-

    lda #$00
    :
        iny
        sta (InstState::lookup_addr),y ; null values
        cpy #$1F
        bcc :-
    rts
.endproc
