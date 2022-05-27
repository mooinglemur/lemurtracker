.scope Undo

base_bank: .byte $06
current_bank_offset: .res 1
; undo/redo stack sizes, this can be > 8 bits if we end up being super generous
undo_size: .res 2
redo_size: .res 2

; see below for "undo group" markers
checkpoint: .byte $01

NUM_BANKS = 4

; temp space
tmp_undo_buffer: .res 16
.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2
.popseg

.include "undo/set_ram_bank.s"
.include "undo/mark_checkpoint.s"
.include "undo/mark_redo_stop.s"
.include "undo/invalidate_redo_stack.s"
.include "undo/advance_undo_pointer.s"
.include "undo/reverse_undo_pointer.s"
.include "undo/unmark_checkpoint.s"
.include "undo/grid.s"
.include "undo/sequencer.s"
.include "undo/sequencer_max_row.s"
.include "undo/instruments.s"
.include "undo/undo.s"
.include "undo/redo.s"



; undo data format
; 16 bytes per event

;00 - format
;       01 - pattern cell
;       02 - sequencer cell
;       03 - sequencer max row
;       04 - instrument (first half)
;       05 - instrument (second half)
;01 - undo group
;       00 - stop point, or uninitialized
;       01 - start point, first event in a group
;       02 - continuation, subsequent events in a group


; for format 01 (tracker grid cell)
;02 - pattern number <-- code doesn't use this directly at least for now
;03 - channel number (x column)
;04 - row number (y column)
;05 - mix number  <-- for restoring the UI
;06 - sequencer row <-- for restoring the UI
;07 - Grid::cursor_position <-- for restoring in the UI
;08-0F - cell data state

; for format 02 (sequencer cell)
;02 - mix number
;03 - column
;04 - row
;05-07 - for possible future use
;08 - value
;09-0F - for possible future use

; for format 03 (sequencer max row)
;02 - mix number
;03 - column
;04 - row
;05-07 - for possible future use
;08 - value
;09-0F - for possible future use

; for format 04 (instrument first half)
;02 - row
;03-07 - for possible future use
;08-0F - value

; for format 05 (instrument second half)
;02 - row
;03-07 - for possible future use
;08-0F - value



.endscope
