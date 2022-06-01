.scope PlayerEngine
; Player state

base_bank: .byte $0B

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2

.segment "PLAYERRAM"
; These are set by effects
speed: .res 1
speed_sub: .res 1

; Subtract one per tick.  If it drops to or below zero, we step the grid
; and speed(_sub) gets added to delay(_sub)
delay: .res 1
delay_sub: .res 1


psg_slot_to_channel: .res 16
psg_slot_to_instrument: .res 16
psg_slot_volume_envelope_addr: .res 32
psg_slot_volume_envelope_offset: .res 16
psg_slot_volume_envelope_delay: .res 16
psg_slot_volume_envelope_value: .res 16
psg_slot_pitch_envelope_addr: .res 32
psg_slot_pitch_envelope_offset: .res 16
psg_slot_pitch_envelope_delay: .res 16
psg_slot_pitch_envelope_value: .res 16
psg_slot_finepitch_envelope_addr: .res 32
psg_slot_finepitch_envelope_offset: .res 16
psg_slot_finepitch_envelope_delay: .res 16
psg_slot_finepitch_envelope_value: .res 16
psg_slot_duty_envelope_addr: .res 32
psg_slot_duty_envelope_offset: .res 16
psg_slot_duty_envelope_delay: .res 16
psg_slot_duty_envelope_value: .res 16
psg_slot_waveform_envelope_addr: .res 32
psg_slot_waveform_envelope_offset: .res 16
psg_slot_waveform_envelope_delay: .res 16
psg_slot_waveform_envelope_value: .res 16

ym_slot_to_channel: .res 8
ym_slot_to_instrument: .res 8
ym_slot_volume_envelope_addr: .res 16
ym_slot_volume_envelope_offset: .res 8
ym_slot_volume_envelope_delay: .res 8
ym_slot_volume_envelope_value: .res 8
ym_slot_pitch_envelope_addr: .res 16
ym_slot_pitch_envelope_offset: .res 8
ym_slot_pitch_envelope_delay: .res 8
ym_slot_pitch_envelope_value: .res 8
ym_slot_finepitch_envelope_addr: .res 16
ym_slot_finepitch_envelope_offset: .res 8
ym_slot_finepitch_envelope_delay: .res 8
ym_slot_finepitch_envelope_value: .res 8
ym_slot_fm_parameter_addr: .res 16

ymnoise_slot_to_channel: .res 1
ymnoise_slot_to_instrument: .res 1
ymnoise_slot_volume_envelope_addr: .res 2
ymnoise_slot_volume_envelope_offset: .res 1
ymnoise_slot_volume_envelope_delay: .res 1
ymnoise_slot_volume_envelope_value: .res 1
ymnoise_slot_pitch_envelope_addr: .res 2
ymnoise_slot_pitch_envelope_offset: .res 1
ymnoise_slot_pitch_envelope_delay: .res 1
ymnoise_slot_pitch_envelope_value: .res 1

pcm_slot_to_channel: .res 1
pcm_slot_to_instrument: .res 1
pcm_bank_position: .res 1
pcm_page_position: .res 1
pcm_byte_position: .res 2
pcm_play_direction: .res 1 ; 1 or -1
pcm_loop_direction: .res 1 ; 1 or -1, current looping direction

channel_to_instrument: .res GridState::NUM_CHANNELS

channel_volume_target: .res GridState::NUM_CHANNELS ; value
channel_volume_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_volume_rate: .res GridState::NUM_CHANNELS ; used for volume slide timing
channel_volume_sub: .res GridState::NUM_CHANNELS ; used for fractional part of volume during slides
channel_volume: .res GridState::NUM_CHANNELS ; set by channel volume column and A volume slides
channel_pitch_target: .res GridState::NUM_CHANNELS ; midi note
channel_pitch_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_pitch_rate: .res GridState::NUM_CHANNELS ; zero for bend (or off), nonzero for glissando
channel_pitch_sub: .res GridState::NUM_CHANNELS ; fractional part
channel_pitch: .res GridState::NUM_CHANNELS ; set by note playback and indirectly by overflowing master_finepitch
channel_finepitch_target: .res GridState::NUM_CHANNELS ; if channel_pitch_target is nonzero, ignore this until it is reached
channel_finepitch_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_finepitch_rate: .res GridState::NUM_CHANNELS ; zero for glissando (or off), nonzero for bend
channel_finepitch_sub: .res GridState::NUM_CHANNELS ; fractional part
channel_finepitch: .res GridState::NUM_CHANNELS ; set by pitch slides and direct offsets
channel_vibrato_target: .res GridState::NUM_CHANNELS ; acts as depth, flips sign when reached
channel_vibrato_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_vibrato_rate: .res GridState::NUM_CHANNELS
channel_vibrato_sub: .res GridState::NUM_CHANNELS ; fractional part
channel_vibrato: .res GridState::NUM_CHANNELS ; added to fine offset
channel_tremolo_target: .res GridState::NUM_CHANNELS ; acts as depth, flips sign when reached
channel_tremolo_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_tremolo_rate: .res GridState::NUM_CHANNELS
channel_tremolo_sub: .res GridState::NUM_CHANNELS ; fractional part
channel_tremolo: .res GridState::NUM_CHANNELS ; only goes negative, 0 = max volume


; YM2151 shadow vars
; globals
ym_ne: .res 1 ; noise enable + freq
ym_lfrq: .res 1 ; LFO frequency
ym_lfw: .res 1 ; LFO waveform
ym_pmd: .res 1 ; phase modulation depth
ym_amd: .res 1 ; amplitude modulation depth

; per YM channel
ym_rl: .res 8 ; right/left
ym_fl: .res 8 ; feedback level
ym_con: .res 8 ; algorithm / operator connect
ym_kc: .res 8 ; key code (octave + note)
ym_kf: .res 8 ; key fraction (pitch bend upwards)
ym_pms: .res 8 ; phase modulation sensitivity
ym_ams: .res 8 ; amplitude modulation sensitivity

; per operator (slot)
ym_dt1: .res 32 ; detune 1
ym_dt2: .res 32 ; detune 2
ym_mul: .res 32 ; phase multiply
ym_tl: .res 32 ; total level (attenuation)
ym_ks: .res 32 ; key scaling
ym_ar: .res 32 ; attack rate
ym_d1l: .res 32 ; first decay level
ym_d1r: .res 32 ; first decay rate
ym_d2r: .res 32 ; second decay rate
ym_rr: .res 32 ; release rate
ym_amsen: .res 32 ; amplitude modulation sensitivity enable


; PSG shadow vars
psg_freql: .res 16
psg_freqh: .res 16
psg_rl: .res 16
psg_vol: .res 16
psg_wf: .res 16
psg_pw: .res 16
.popseg

.include "playerengine/ym_wait.s"
.include "playerengine/panic.s"
.include "playerengine/tick.s"



.endscope
