* **3 Sept 2019**

* **appoggiatura.qml** version 3.1 introduces the ability to specify nonzero separation (or overlap) between the end of the appoggiatura (or appoggiature) and the start of the main note. This had previously been constrained to be zero, which is how it is created by MuseScore.  The first text field has been renamed from *perMille* to *Main note start ‰*.  The second text field, *Separation*, is the positive separation between the end of the appoggiatura(e) and the start of the main note.  In almost all cases, leave it as zero. \
\
But with experience and skill, and varying criteria for different instruments and sound fonts, you can use negative values (try -40, -50, whatever else suits you) to simulate enhanced legato between the appoggiature and the main note, when desirable.  The effect is subtle, audible, and very pleasing for voices and string instruments.

![Appoggiatura plugin with separation](AppoggWSep.png)


* **4 Aug 2019**

Added ![adjustTiedNotes.md](https://github.com/BernardSGreenberg/MuseScorePlugins/blob/master/adjustingTiedNotes.md) describing issues with MuseScore representation of tied notes, issues that users need understand.

* **1 Aug 2019**

* **articulate.qml 3.2** fixes a bug in 3.1 that would create an unreadable score if you stored the annotations into it, say, if you were perhaps writing a phrasing tutorial .... 

* **articulate.qml** version 3.1 introduces a new feature which inserts on-time/off-time annotations as staff text under all notes in a selection for which either differs from the normal 0 and 1000. Select a region, invoke the plugin, and the "Show in score" button will appear along with the others. Press it to insert the numbers into the score.  You can do a whole score at once, if you wish.  There is an undo button in the dialog, which appears when the numbers are up, which will undo them all, or, alternatively, you can just leave them there for illustration, or undo them the usual way (Ctrl-Z/Command-Z). Each annotation can be selected and deleted like any other staff text.  Once you press "Show in score", you can only cancel (relabelled "Leave them") without removing the numbers, or press "Undo show", which also exits, but undoes the numbers first.
![Note times in the score](inScoreShowTimes.png)
