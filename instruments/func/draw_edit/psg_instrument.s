.proc draw_edit_psg_instrument
    ldy #$10
    lda (InstState::lookup_addr),y
    and #3


    ldx #<dialog
    ldy #>dialog
    jsr Util::dialog

    ldx #<cursor
    ldy #>cursor
    lda InstState::edit_field_idx
    jsr Util::cursor

    rts

dialog: .byte EDITBOX_Y,EDITBOX_X,14,23
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR)

        .byte 2,1,2
        .word header1
        .byte $D0,3

        .byte 2,1,6
        .word header2
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),17

        .byte 1,2 ; separator

        .byte 2,3,1
        .word name
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),4

        .byte 3,3,7
        .byte InstState::lookup_addr,1
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),15

        .byte 1,4 ; separator

        .byte 2,5,9
        .word output
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),10

        .byte 2,6,1
        .word left
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),6

        .byte 7,6,7
        .byte InstState::lookup_addr,$10
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),$80

        .byte 2,6,8
        .word right
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),14

        .byte 7,6,22
        .byte InstState::lookup_addr,$10
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),$40

        .byte 2,6,23
        .word rbracket
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),1

        .byte 1,7 ; separator

        .byte 2,8,8
        .word waveform
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),8

        .byte 8,9,1
        .word lbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),0

        .byte 2,9,2
        .word pul
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3

        .byte 8,9,5
        .word rbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),0

        .byte 8,9,7
        .word lbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,9,8
        .word saw
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3

        .byte 8,9,11
        .word rbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 8,9,13
        .word lbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),2

        .byte 2,9,14
        .word tri
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3

        .byte 8,9,17
        .word rbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),2

        .byte 8,9,19
        .word lbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3

        .byte 2,9,20
        .word noi
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3

        .byte 8,9,23
        .word rbracket_callback
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),3


        .byte 1,10 ; separator

        .byte 2,11,2
        .word envmacro
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),20

        .byte 2,12,1
        .word volume
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),6

        .byte 5,12,9
        .byte InstState::lookup_addr,$11
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,13,1
        .word pitch
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),5

        .byte 5,13,9
        .byte InstState::lookup_addr,$12
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,13,13
        .word fine
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),4

        .byte 5,13,21
        .byte InstState::lookup_addr,$13
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,14,1
        .word duty
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),4

        .byte 5,14,9
        .byte InstState::lookup_addr,$14
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 2,14,13
        .word wave
        .byte (XF_BASE_BG_COLOR|XF_BASE_FG_COLOR),4

        .byte 5,14,21
        .byte InstState::lookup_addr,$15
        .byte (XF_HILIGHT_BG_COLOR_1|XF_BASE_FG_COLOR),1

        .byte 0

header1:  .asciiz "PSG"
header2:  .asciiz "Instrument Editor"
name:     .asciiz "Name"
output:   .asciiz "Output"
left:     .asciiz "Left ["
right:    .asciiz "]      Right ["
rbracket: .asciiz "]"
waveform: .asciiz "Waveform"
pul:      .asciiz "Pul"
saw:      .asciiz "Saw"
tri:      .asciiz "Tri"
noi:      .asciiz "Noi"
envmacro: .asciiz "Envelopes and Macros"
volume:   .asciiz "Volume"
pitch:    .asciiz "Pitch"
fine:     .asciiz "Fine"
duty:     .asciiz "Duty"
wave:     .asciiz "Wave"

cursor:  .byte EDITBOX_Y,EDITBOX_X
         .byte 3,7,15 ; name
         .byte 6,7,1 ; left
         .byte 6,22,1 ; right
         .byte 9,1,5 ; pul
         .byte 9,7,5 ; saw
         .byte 9,13,5 ; tri
         .byte 9,19,5 ; noi
         .byte 12,9,2 ; volume
         .byte 13,9,2 ; pitch
         .byte 13,21,2 ; fine
         .byte 14,9,2 ; duty
         .byte 14,21,2 ; wave
.endproc
