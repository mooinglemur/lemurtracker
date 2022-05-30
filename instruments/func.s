.scope Func

tmp1: .res 1
tmp2: .res 1
tmp3: .res 1
tmp4: .res 1

.include "func/draw.s"
.include "func/decrement_y.s"
.include "func/increment_y.s"
.include "func/decrement_y_page.s"
.include "func/increment_y_page.s"
.include "func/set_y.s"
.include "func/draw_edit.s"
.include "func/set_instrument_type.s"
.include "func/delete.s"
.include "func/name_entry.s"

.endscope
