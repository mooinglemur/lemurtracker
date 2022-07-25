.scope PlayerEngine


tmp8b: .res 8
tmp1: .res 1
tmp2: .res 1



.include "playerengine/psgfreq.inc"
.include "playerengine/ym_wait.s"
.include "playerengine/panic.s"
.include "playerengine/release_voices.s"
.include "playerengine/assign_voice_psg.s"
.include "playerengine/assign_voice_ym.s"
.include "playerengine/assign_voice_ymnoise.s"
.include "playerengine/assign_voices.s"
.include "playerengine/advance_envelopes.s"
.include "playerengine/trigger_note.s"
.include "playerengine/tick_play.s"
.include "playerengine/load_row.s"
.include "playerengine/tick.s"



.endscope
