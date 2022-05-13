.scope SeqState
; We don't use x_position here.  We use Grid::x_position instead
;x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
max_row: .res 1 ; the last row shown in the sequencer
max_pattern: .res 1; the highest patten number we can fit in ram
mix: .res 1 ; which mix we're displaying
base_bank: .res 1 ; what bank are we going to use for the seq table
iterator: .res 1

NUM_CHANNELS = 8
SEQUENCER_LOCATION_X = 1
SEQUENCER_LOCATION_Y = 45
SEQUENCER_GRID_ROWS = 9

MIX_LIMIT = 8
ROW_LIMIT = 128 ; hard limit, row count

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
mix0_lookup_addr: .res 2 ; storage for offset into banked ram but for mix 0
.popseg

; selection_active = 0 for no selection
; bitfield
;     0 - selecting
;     1 - selection done
;     2 - 0 = selecting downward, 1 = selecting upward
;     3 - 0 = selecting rightward, 1 = selecting leftward

.pushseg
.segment "ZEROPAGE"
selection_active: .res 1
.popseg
selection_top_y: .res 1
selection_bottom_y: .res 1

tmpcolor: .res 1

set_ram_bank:
    lda base_bank
    sta x16::Reg::RAMBank
    rts

set_lookup_addr: ; input: .Y = row
    lda base_bank
    sta x16::Reg::RAMBank

    stz lookup_addr+1

    tya ; the row we're drawing
    asl
    rol lookup_addr+1
    asl
    rol lookup_addr+1
    asl
    rol lookup_addr+1
    sta lookup_addr
    sta mix0_lookup_addr

    lda SeqState::mix
    asl
    asl
    clc
    adc #$A0
    adc lookup_addr+1
    sta lookup_addr+1
    and #$A3
    sta mix0_lookup_addr+1

    rts

update_grid_patterns:
    ldy SeqState::y_position
    jsr SeqState::set_lookup_addr
    ldy #0
@loop:
    ldx #0
    lda (SeqState::lookup_addr),y
    cmp #$FF
    bcc :+
        lda (SeqState::mix0_lookup_addr),y
        ldx #1
    :
    sta GridState::channel_to_pattern,y
    txa
    sta GridState::channel_is_inherited,y
    iny
    cpy #GridState::NUM_CHANNELS
    bcc @loop

    rts

init:
    ; clear sequencer bank memory
    ; set row 0 of mix 0 to all $00
    ; and all other rows of all mixes to $FF
    stz SeqState::mix
    ldy #0
    jsr SeqState::set_lookup_addr
    lda #0
@mainloop:
    ldy #0
@rowloop:
    sta (SeqState::lookup_addr),y
    iny
    cpy #8
    bcc @rowloop
    lda SeqState::lookup_addr
    clc
    adc #8
    sta SeqState::lookup_addr
    lda SeqState::lookup_addr+1
    adc #0
    cmp #$C0
    bcs @end
    sta SeqState::lookup_addr+1
    lda #$FF
    bra @mainloop
@end:
    rts


.endscope
