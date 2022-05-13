.scope GridState
NUM_CHANNELS = 8
MAX_OCTAVE = 8 ; max octave for the editor (Z key is C in that octave)
MAX_STEP = 15

; vars that keep state
x_position: .res 1 ; which tracker column (channel) are we in
y_position: .res 1 ; which tracker row are we in
tmp_y_position: .res 1 ; store y_position at the beginning of draw to
                       ; avoid artifacts if y_position is changed in IRQ
                       ; during draw
cursor_position: .res 1 ; within the column (channel) where is the cursor?
global_pattern_length: .res 1 ; set on file create/file load
base_bank: .res 1 ; where does tracker data start
channel_to_pattern: .res NUM_CHANNELS ; which pattern is referenced in each channel
channel_is_inherited: .res NUM_CHANNELS ; boolean of whether the channel data is inherited from mix 0
notechardata: .res 9*NUM_CHANNELS ; temp storage for characters based on pattern data
entrymode: .res 1
short_hilight_interval: .res 1
long_hilight_interval: .res 1

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
selection_left_x: .res 1
selection_bottom_y: .res 1
selection_right_x: .res 1

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2 ; storage for offset in banked ram
.popseg

; vars that affect entry
octave: .res 1
step: .res 1

note_val:    .byte CustomChars::NOTE_C,CustomChars::NOTE_C,CustomChars::NOTE_D
             .byte CustomChars::NOTE_D,CustomChars::NOTE_E,CustomChars::NOTE_F
             .byte CustomChars::NOTE_F,CustomChars::NOTE_G,CustomChars::NOTE_G
             .byte CustomChars::NOTE_A,CustomChars::NOTE_A,CustomChars::NOTE_B
note_sharp:  .byte "-#-#--#-#-#-"
note_octave: .byte "0123456789"


column_fg_color: .byte XF_BASE_FG_COLOR,XF_BASE_FG_COLOR,XF_BASE_FG_COLOR
                 .byte XF_INST_FG_COLOR,XF_INST_FG_COLOR,XF_VOL_FG_COLOR
                 .byte XF_EFFECT_FG_COLOR,XF_EFFECT_FG_COLOR,XF_EFFECT_FG_COLOR
column_fg_color_mix: .byte XF_DIM_FG_COLOR,XF_DIM_FG_COLOR,XF_DIM_FG_COLOR
                     .byte XF_BASE_FG_COLOR,XF_BASE_FG_COLOR,XF_DIM_FG_COLOR
                     .byte XF_BASE_FG_COLOR,XF_BASE_FG_COLOR,XF_BASE_FG_COLOR


.proc set_lookup_addr ; takes in .X, .Y for tracker position, affects .A, lookup_addr
    stz lookup_addr
    stz lookup_addr+1
    ; for global_pattern_length > 64 we're doing one bank per multitrack pattern
    ; otherwise we do two patterns per bank
    lda global_pattern_length
    cmp #$41
    bcs big_patterns
small_patterns:
    lda channel_to_pattern,x ; which pattern are we loading
    lsr
    ror lookup_addr
    lsr lookup_addr
    bra add_base_bank
big_patterns:
    lda channel_to_pattern,x ; which pattern are we loading
add_base_bank:
    clc
    adc base_bank
    sta x16::Reg::RAMBank
    tya
    clc
    adc lookup_addr
    sta lookup_addr

    ; multiply by 64 (8 channels, 8 bytes per entry)
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
    rol lookup_addr+1
    asl lookup_addr
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

    rts

.endproc

.endscope
