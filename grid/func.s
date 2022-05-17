; Grid::Func
.scope Func

iterator: .res 1
tmp1: .res 1
tmp2: .res 1
tmp3: .res 1

.include "func/selection_start.s"
.include "func/selection_continue.s"
.include "func/select_all.s"
.include "func/select_none.s"
.include "func/backspace.s"
.include "func/delete_cell_above.s"
.include "func/delete_selection.s"
.include "func/draw.s"
.include "func/decrement_octave.s"
.include "func/decrement_step.s"
.include "func/decrement_x.s"
.include "func/decrement_y.s"
.include "func/decrement_y_page.s"
.include "func/decrement_cursor.s"
.include "func/increment_cursor.s"
.include "func/increment_octave.s"
.include "func/increment_step.s"
.include "func/increment_x.s"
.include "func/increment_y.s"
.include "func/increment_y_page.s"
.include "func/increment_y_steps.s"
.include "func/increment_y_steps_noselect.s"
.include "func/insert_cell.s"
.include "func/note_entry.s"
.include "func/entry.s"
.include "func/set_y.s"


.endscope
