.scope PlayerState

base_bank: .byte $0B

theft: .byte $00 ; pointer to arbitrary next voice to steal

.pushseg
.segment "ZEROPAGE"
lookup_addr: .res 2
.segment "PLAYERRAM"
; These are set by global state, and effects
speed: .res 1
speed_sub: .res 1

; Subtract one per tick.  If it drops below zero, we step the grid
; and speed(_sub) gets added to delay(_sub)
delay: .res 1
delay_sub: .res 1

psg_slot_playing: .res 16
psg_slot_to_channel: .res 16
psg_slot_to_instrument: .res 16
psg_slot_volume_envelope_index: .res 16
psg_slot_volume_envelope_offset: .res 16
psg_slot_volume_envelope_delay: .res 16
psg_slot_volume_envelope_value: .res 16
psg_slot_pitch_envelope_index: .res 16
psg_slot_pitch_envelope_offset: .res 16
psg_slot_pitch_envelope_delay: .res 16
psg_slot_pitch_envelope_value: .res 16
psg_slot_finepitch_envelope_index: .res 16
psg_slot_finepitch_envelope_offset: .res 16
psg_slot_finepitch_envelope_delay: .res 16
psg_slot_finepitch_envelope_value: .res 16
psg_slot_duty_envelope_index: .res 16
psg_slot_duty_envelope_offset: .res 16
psg_slot_duty_envelope_delay: .res 16
psg_slot_duty_envelope_value: .res 16
psg_slot_waveform_envelope_index: .res 16
psg_slot_waveform_envelope_offset: .res 16
psg_slot_waveform_envelope_delay: .res 16
psg_slot_waveform_envelope_value: .res 16

ym_slot_playing: .res 8
ym_slot_to_channel: .res 8
ym_slot_to_instrument: .res 8
ym_slot_volume_envelope_index: .res 8
ym_slot_volume_envelope_offset: .res 8
ym_slot_volume_envelope_delay: .res 8
ym_slot_volume_envelope_value: .res 8
ym_slot_pitch_envelope_index: .res 8
ym_slot_pitch_envelope_offset: .res 8
ym_slot_pitch_envelope_delay: .res 8
ym_slot_pitch_envelope_value: .res 8
ym_slot_finepitch_envelope_index: .res 8
ym_slot_finepitch_envelope_offset: .res 8
ym_slot_finepitch_envelope_delay: .res 8
ym_slot_finepitch_envelope_value: .res 8
ym_slot_fm_parameter_addr: .res 16
ymnoise_slot_noisefreq_envelope_index: .res 1

pcm_slot_playing: .res 1
pcm_slot_to_channel: .res 1
pcm_slot_to_instrument: .res 1
pcm_bank_position: .res 1
pcm_page_position: .res 1
pcm_byte_position: .res 2
pcm_play_direction: .res 1 ; 1 or -1
pcm_loop_direction: .res 1 ; 1 or -1, current looping direction


channel_trigger: .res GridState::NUM_CHANNELS ; when value is 1, note is played this tick
                                              ; if value is nonzero, decrement at the end of the tick
channel_repatch: .res GridState::NUM_CHANNELS ; when this value is 1, at next trigger, re-apply all shadow parameters, then zero
channel_note: .res GridState::NUM_CHANNELS ; 0 for cut, 1 for released, otherwise midi value

channel_to_instrument: .res GridState::NUM_CHANNELS

channel_volume_target: .res GridState::NUM_CHANNELS ; value
channel_volume_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_volume_rate: .res GridState::NUM_CHANNELS ; used for volume slide timing
channel_volume_sub: .res GridState::NUM_CHANNELS ; used for fractional part of volume during slides
channel_volume: .res GridState::NUM_CHANNELS ; set by channel volume column and Axx volume slides
channel_pitch_target: .res GridState::NUM_CHANNELS ; midi note
channel_pitch_rate_sub: .res GridState::NUM_CHANNELS ; fractional part of rate
channel_pitch_rate: .res GridState::NUM_CHANNELS ; zero for bend (or off), nonzero for glissando
channel_pitch_sub: .res GridState::NUM_CHANNELS ; fractional part (unsigned)
channel_pitch: .res GridState::NUM_CHANNELS ; set by note playback and indirectly by overflowing channel_finepitch
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

channel_portamento: .res GridState::NUM_CHANNELS ; track portamento effect (3xx) persistence

; YM2151 shadow vars
; globals
ym_ne: .res 1 ; noise enable + freq
ym_lfrq: .res 1 ; LFO frequency
ym_lfw: .res 1 ; LFO waveform
ym_pmd: .res 1 ; phase modulation depth
ym_amd: .res 1 ; amplitude modulation depth

; per YM channel (voice)
ym_rl_fb_con: .res 8 ; right/left
ym_kc: .res 8 ; key code (octave + note)
ym_kf: .res 8 ; key fraction (pitch bend upwards)
ym_pms: .res 8 ; phase modulation sensitivity
ym_ams: .res 8 ; amplitude modulation sensitivity

; per operator (slot)
ym_20:
ym_dt1_mul: .res 32 ; detune 1 [6:4]/ phase multiply [3:1]
ym_tl: .res 32 ; total level (attenuation) [6:0]
ym_ks_ar: .res 32 ; key scaling [7:6] / attack rate [4:0]
ym_amsen_d1r: .res 32 ; amplitude modulation sensitivity enable [7] / first decay rate [4:0]
ym_dt2_d2r: .res 32 ; detune 2 [7:6] / second decay rate (if zero, it's sustain) [4:0]
ym_d1l_rr: .res 32 ; first decay level (sustain point) [7:4] release rate [3:0]

; PSG shadow vars
psg_freql: .res 16
psg_freqh: .res 16
psg_rl: .res 16
psg_vol: .res 16
psg_wf: .res 16
psg_pw: .res 16
.popseg

.endscope
