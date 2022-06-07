; Instrument state scope
; This holds the state of the instrument table,
; a few constants, and some utility functions for changing that state
.scope InstState

;Instrument record: 32 bytes
;00 type
;01-0F name

;Type 01 - PSG
;10 - [7] right channel [6] left channel [1:0] Waveform
;11 - Volume Envelope (to emulate ADSR)
;12 - Pitch Envelope (arpeggios, grace notes)
;13 - Finetune Envelope (vibratos, dips, scoops)
;14 - Duty Envelope
;15 - Waveform Envelope

;Type 02 - YM
;10 - [7] right channel [6] left channel [5:3] feedback [2:0] Alg
;11 - Volume Envelope
;12 - Pitch Envelope (arpeggios, grace notes)
;13 - Finetune Envelope (vibratos, dips, scoops)

;Type 03 - YM NOISE
;10 - [7] right channel [6] left channel [5:3] feedback [2:0] Alg
;11 - Volume Envelope
;12 - Pitch Envelope (arpeggios, grace notes)
;13 - Finetune Envelope (vibratos, dips, scoops)
;14 - Noisefreq Envelope

;Type 04 - LAYER
;10-17 - Instruments 1-8, FF to disable


; FM param record: 32 bytes
;00 - PMS
;01 - AMS
;  all of the below are in register order, op 0 -> 1 -> 2 -> 3
;  AKA M1 -> M2 -> C1 -> C2
;08-0B - DT1_MUL
;0C-0F - TL
;10-13 - KS_AR
;14-17 - AMSEN_DIR
;18-1B - DT2_D2R
;1C-1F - D1L_RR


y_position: .res 1 ; which instrument row are we in
max_instrument: .byte $FE ; the last instrument
base_bank: .byte $02
fm_base_bank: .byte $05
envelope_base_bank: .byte $03

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

set_fm_bank:
    lda fm_base_bank
    sta X16::Reg::RAMBank
    rts

set_fm_lookup_addr: ; input .Y = row/instrument
    lda fm_base_bank
    sta X16::Reg::RAMBank
    bra set_lookup_addr_nobank

set_lookup_addr: ; input: .Y = row/instrument
    lda base_bank
    sta X16::Reg::RAMBank
set_lookup_addr_nobank:
    stz lookup_addr+1

    tya
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

.proc set_lookup_addr_envelope ; input: .A = envelope number
    stz lookup_addr+1
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
    tax
    lda #$A0
    clc
    adc lookup_addr
    cmp #$C0
    ldy envelope_base_bank
    bcc :+
        iny
        sec
        sbc #$20
    :
    sta lookup_addr
    sty X16::Reg::RAMBank

    rts
.endproc

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
