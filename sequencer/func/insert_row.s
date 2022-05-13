insert_row: ; uses tmp1,tmp2,tmp3,tmp4
    sta tmp1 ; number of rows we're inserting
    ; if we would exceed max rows, return with error
    clc
    adc SeqState::max_row
    cmp #SeqState::ROW_LIMIT
    bcc :+
        ; carry is already set to indicate error
        rts
    :

    lda SeqState::mix
    pha ; preserve currently selected mix

    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_max_row ; makes sure undo returns us to the correct mix and position

    ; we need to shift everything from cursor position down
    ; to the end of the sequencer, (in all mixes!)
    lda #0
    sta SeqState::mix
@mixloop:
    lda SeqState::max_row
    sta tmp2 ; tmp3 is the src cursor
    clc
    adc tmp1
    sta tmp3 ; tmp3 is the dest cursor
@loop:
    ldy tmp3
    ldx GridState::x_position
    jsr Undo::store_sequencer_row

    ldy tmp2
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda (SeqState::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ldy tmp3
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-

    dec tmp2
    dec tmp3
    lda tmp2
    bmi @fill_loop ; in case we wrapped around to FF
    cmp SeqState::y_position
    bcs @loop
@fill_loop:
    ; tmp2 is now in the row above our insert
    ; tmp3 is now in a row that we must nullify (in mixes 1-7)
    ; or populate (in mix 0)
    ldy tmp3
    ldx GridState::x_position
    jsr Undo::store_sequencer_row
    ldy tmp3
    jsr SeqState::set_lookup_addr

    lda SeqState::mix
    beq @mix0


    lda #$FF
    ldy #0
    :
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
    bra @check_fill
@mix0:
    jsr Sequencer::Func::get_first_unused_patterns ; stores in tmp8b

    ldy tmp3
    jsr SeqState::set_lookup_addr

    ldy #0
    :
        lda tmp8b,y
        inc
        sta (SeqState::lookup_addr),y
        iny
        cpy #8
        bcc :-
@check_fill:
    dec tmp3
    lda tmp3
    bmi @check_mix
    cmp SeqState::y_position
    bcs @fill_loop
@check_mix: ; Chex mix
    inc SeqState::mix
    lda SeqState::mix
    cmp #SeqState::MIX_LIMIT
    bcs :+
        jmp @mixloop
    :
@finalize:
    pla ; restore active mix
    sta SeqState::mix
    ldx GridState::x_position
    ldy SeqState::y_position
    jsr Undo::store_sequencer_max_row ; makes sure redo returns us to the correct mix too
    jsr Undo::mark_checkpoint
    lda SeqState::max_row
    clc
    adc tmp1
    sta SeqState::max_row
    inc redraw
@end:
    ; carry should already be clear to indicate no error
    rts
