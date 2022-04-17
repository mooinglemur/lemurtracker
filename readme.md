# Welcome to xfabriek

xfabriek is a tracker music editor and playback engine for the Commander X16.

It is designed for composing music, either for standalone playback, or to
be included in assembly language demos and games.

## Design goals

xfabriek is designed with a balance between memory footprint, ease of
programming, and functionality.

While xfabriek is intended to give chiptune musicians a simple and familiar
tracker interface in which to edit music, the main motivation for this
project is to give game developers the ability for smooth and seamless
transitions within the music during playback. This is done in two different
ways:

### Smooth music transitions

* Uniquely, xfabriek can hold multiple *mixes* within each song. Each mix is a
  separate list of patterns (usually largely similar to each other) that the
  programmer can switch between during gameplay without stopping
  playback of the music and without abrupt transitions. Think of
  Nintendo's Super Mario Galaxy how the music changes when the character
  switches between being underwater and above ground, or in Super Mario
  World where the music adds bongo beats while riding Yoshi. The mix
  can be selected by the developer and xfabriek's player will handle the
  transition.

* Mixes can have conditional jump or loop points. At specific points in the
  mix, an effect can call a user callback subroutine. The return value given
  by that subroutine (in the 3 registers) will inform the player where and
  whether to jump. A possible scenario could be a game where the music
  builds up and transitions as the player progresses into a new area, or loops
  a short section until the player proceeds.

### Sound effects

* Sound effects are simply created as a short song and exported to a binary
  format. They are meant to be short, as the sound effect is stored in a linear type+register+value+delta format. xfabriek will track two simultaneous sound
  effects (high and low priority).

### Terminology

* Song - An individual distinct tune, one per module
* Mix - A sequence of patterns within a song. If there are multiple mixes, the
  player can switch between them during song playback.
* Channel - Any one of the columns in the tracker grid, capable of containing
  notes and effects.
* Pattern - A channel-specific reference to a sequence of notes and effects.
* Instrument - Parameters that describe hardware, timbre, and envelopes, used
  for playing notes.
* Voice - A logical slot (in hardware) used for playing the sounds of an
  instrument. There are 16 PSG voices, 8 FM voices, and 1 PCM voice.
