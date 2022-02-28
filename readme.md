# Welcome to Xfabriek

xfabriek is a tracker music editor for the Commander X16. It currently uses 
the CONCERTO synthesizer engine by Carl Georg Biermann.

It is designed for composing music, either for standalone playback, or to
be included in assembly language demos and games.

## Design goals

xfabriek is designed with a balance between memory footprint, ease of
programming, and functionality. 

While xfabriek is intended to give chiptune musicians a simple and familiar
tracker interface in which to edit music, the main motivation for this
project is to give game developers the ability for smooth and seamless
transitions within the music. This is done in two different ways:

### Smooth music transitions

* xfabriek can manage multiple *songs* in the same output file. Uniquely,
  xfabriek can hold multiple *mixes* within each song. Each mix is a
  separate list of patterns (largely similar to each other) that the
  programmer can switch between during gameplay without stopping
  playback of the music and without abrupt transitions. Think of
  Nintendo's Super Mario Galaxy how the music changes when the character
  switches between being underwater and above ground, or in Super Mario
  World where the music adds bongo beats while riding Yoshi. The mix
  can be selected by the developer and xfabriek's player will handle the
  transition. Planned transition styles include switching tracks immediately,
  and fadeout+fadein.

* Songs can have conditional jump or loop points. At specific points in the
  song, an effect can call a user callback subroutine. The return value given
  by that subroutine (in the 3 registers) will inform the player where and 
  whether to jump. A possible scenario could be a game where the music
  begins 

### Sound effects

* Sound effects are simply stored as frames of a song. They are meant to be
  short, as the sound effect playback will only play through one frame. Other
  frames are treated as other sound effects.
  xfabriek will track two simultaneous sound effects (high and low priority).
  The *mix* is taken into effect so the same sound effect can be set to
  change characteristics depending on the mix being played.

