.scope Func

tmp1: .res 1
tmp2: .res 1
tmp3: .res 1
tmp4: .res 1
tmp8b: .res 8

.include "func/get_first_unused_patterns.s"
.include "func/selection_start.s"
.include "func/selection_continue.s"
.include "func/set_cell.s"
.include "func/decrement_mix.s"
.include "func/decrement_cell.s"
.include "func/decrement_x.s"
.include "func/decrement_y.s"
.include "func/decrement_y_page.s"
.include "func/increment_mix.s"
.include "func/increment_cell.s"
.include "func/increment_max_row.s"
.include "func/increment_x.s"
.include "func/increment_y.s"
.include "func/increment_y_page.s"
.include "func/insert_row.s"
.include "func/delete_row.s"
.include "func/set_y.s"
.include "func/draw.s"
.include "func/select_all.s"
.include "func/select_none.s"
.include "func/entry_callback.s"


.endscope
