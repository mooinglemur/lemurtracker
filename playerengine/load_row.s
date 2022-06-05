.proc load_row
    ; tmp8b - buffer to hold cell
    ; tmp1 - channel

    ; load the row
    jsr SeqState::update_grid_patterns

    stz tmp1
channel_loop:
    ldx tmp1
    ldy GridState::y_position
    jsr GridState::set_lookup_addr
    ; copy cell to low ram

    ldy #0
    :
        lda (GridState::lookup_addr),y
        sta tmp8b,y
        iny
        cpy #8
        bcc :-

    ; switch back to PlayerEngine bank
    lda base_bank
    sta X16::Reg::RAMBank

    ; did the instrument change?
    ldx tmp1
    lda channel_to_instrument,x
    cmp tmp8b+1
    beq same_instrument

    ; for each channel
    ;   handle dynamic instrument (re)assignments and changes
    ;       FM: KOFF (delayed triggers should allow an FM note to decay)
    ;       PSG: Set volume 0 (delayed triggers will cut a PSG note)
    ;           delayed triggers will also stop the previous note's macros
    ;       set channel_repatch,x to 1
    ;       apply patch to shadow parameters only
    ;   set envelope offset pointers to $00 and macro delay to 0
    ;   set channel_trigger,x to 1


    ; release current voices - cut PSG, release FM
    ; x is channel
    jsr release_voices
    ldx tmp1
    lda #1
    sta channel_repatch,x

    ; now assign the instrument
    lda tmp8b+1
    jsr assign_voices ; x = channel, a = instrument



same_instrument:
    ; then process all of the effects (including delay triggers which reset channel_trigger)




    inc tmp1
    ldx tmp1
    cpx #GridState::NUM_CHANNELS
    bcc channel_loop

    ; now add speed(_sub) to delay(_sub)
    lda base_bank
    sta X16::Reg::RAMBank
    lda speed_sub
    clc
    adc delay_sub
    sta delay_sub
    lda speed
    adc delay
    sta delay

    rts
.endproc
