.proc advance_envelopes ; .X is channel number
    ; we're going to have to find the voice(s) that belong to this channel and advance them all.  If we're in a release state and at the end of the envelope, transition to a cut state and cut PSG note.
    ; also reset the *_slot_playing if we're in cut/release

    
    

    rts
.endproc