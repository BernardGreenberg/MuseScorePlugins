# Adjusting tied notes

BSG 3 Aug 2019

MuseScore's representation of the articulation parameters (on-time, off-time) for tied notes is currently obscure in a way you must understand if you wish to adjust the same.  The situation may improve in the future in such a way that will allow these plugins to act in a more consistent fashion.

For this explanation, we will use the MuseScore *staccato* dot, which can be applied to a note by typing Shift-S, as a means of applying "off-time 500" accurately, which is exactly what it does (as can be verified in the Piano Roll Editor (PRE)).

The nature of electromagnetism is such that if you were to break a bar magnet in half, you do **not** get two "magnetic monopoles", a North one and a South one, but two baby regular bar magnets, a most unexpected result absent study.  The same is true here.  Let us produce a little bar magnet: In a new score, set quarter-note = 40 and turn on the metronome. Enter two quarter-notes, tie them, click on the first, and type capital S to it to apply *staccato*.  Now play it.

What? *Three-quarters of the note*, not half of it? What's going on?  Use the **articulate** plugin, not the PRE, to look at the off-times of both notes.  You will see that the **first** one shows 500 and the second, 1000, the opposite of what you hear, and not what you expected anyway! Had you used the PRE to adjust the off-time of the *entire note*, you will see that it won't really do what you asked, but will adjust, visually, and set up to play the *second* note shortened, while (falsely) claiming that it applied the adjustment to the *entire note*.

![adjustment displacement example](staccatoAnomaly.png)

If you now *untie* the two notes, forthwith the *first note* will obey the *staccato* you gave it, and the second will spring back to full value!  A split bar magnet!

Now try another experiment.  Make two more adjacent quarter notes, not tied, of the same pitch, and add *staccato* to the *second* one. Play it, and it will, of course, play as expected. If you view it in the PRE, however, you will not even see the change -- this is a bug. But it plays as expected again, with the second cut back. But if you use the **articulate** plugin, you will see the adjusted parameters still there on the second note. The magnetic monopole!

So where do the articulation parameters belong for a tied note? MuseScore isn't really sure, because it seems to be prepared for your doing either, putting them on the last note or the first note produces the "right" answer.  MuseScore seems to handle either model, and can't ever stop doing so, lest scores with articulations on final notes of tied groups (of which I have authored many over the years) fail to play properly.

MuseScore does not handle this consistently, and supports enough variability in extant scores that it may never.  Perhaps MuseScore is anticipating your untieing the notes in the future, in which eventuality, *in either case*, what is visually apparent in the score will become the fact in sound.  Although the MS synthesizer does, the PRE does not recognize or understand articulation control of tied-note chains on other than the first note, which is a bug, as far as I can tell.

So, when using the **articulate** plugin, to which part of a tied note should it be applied?  My practice has been "it depends upon how it ends", i.e., if the ending of the tied note is a suspension that has to end simultaneously with another voice, I set the articulation parameters on the last note, as here.  This has the advantage of letting you select both notes at once and set the off-time in a "multiple" operation.

![BWV 227.9 excerpt](bwv227suspx1.png)

If the tie is just a rhythmic notation within a measure, as here, I click on and change the first note.  The effect, in either case, is **identical**, i.e., to apply the changes to the *last* note, no matter in which they are "stored."

![Rhythmic tieing](tieartic2.png)

## On-time and off-time both, for tied notes

You may well wonder what is required to adjust *both* the on-time and the off-time of a chain of two or more tied notes.  Adjusting the on-time is not very common -- I know of only two cases, keyboard "rolled" arpeggi and cross-bowed string-instruments (the native MuseScore arpeggio feature sets on-times).  If you have a note (or chord) tied to one or more notes, and wish to delay the start of the first and cut back the end of the last, do exactly that: edit both (first and last in chain) notes with the plugin, changing the on-time of the first and the off-time of the last.

