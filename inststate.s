; Instrument state scope
; This holds the state of the instrument table,
; a few constants, and some utility functions for changing that state
.scope InstState

y_position: .res 1 ; which instrument row are we in
max_instrument: .byte $FE ; the last instrument
base_bank: .byte $02

edit_field_idx: .res 1 ; the field in the instrument edit that is hilighted
                       ; the exact field depends on the type of instrument
edit_instrument_type: .res 1

INSTRUMENTS_LOCATION_X = 20
INSTRUMENTS_LOCATION_Y = 45
INSTRUMENTS_GRID_ROWS = 9
INSTRUMENTS_GRID_WIDTH = 19
NUM_CHANNELS = 8

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
.popseg

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
    asl
    rol lookup_addr+1
    asl
    rol lookup_addr+1

    sta lookup_addr

    lda #$A0
    adc lookup_addr+1
    sta lookup_addr+1

    rts


instrument_type: .byte " NUL"," PSG"," OPM"," NOI"," MUL"," PCM", " XXX"
instrument_type_color:
    .byte $00,$00,$00,$00 ; NUL
    .byte $00,$D0,$D0,$D0 ; PSG
    .byte $00,$A1,$A1,$A1 ; OPM
    .byte $00,$21,$21,$21 ; NOI
    .byte $00,$C1,$C1,$C1 ; MUL
    .byte $00,$61,$61,$61 ; PCM
    .byte $00,$01,$01,$01 ; XXX


.endscope
