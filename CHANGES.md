* **4 Aug 2019**

Added ![adjust tied notes](adjustTiedNotes.md) describing issues with MuseScore representation of tied notes, issues that users need understand.

* **1 Aug 2019**

* **articulate.qml 3.2** fixes a bug in 3.1 that would create an unreadable score if you stored the annotations into it, say, if you were perhaps writing a phrasing tutorial .... 

* **articulate.qml** version 3.1 introduces a new feature which inserts on-time/off-time annotations as staff text under all notes in a selection for which either differs from the normal 0 and 1000. Select a region, invoke the plugin, and the "Show in score" button will appear along with the others. Press it to insert the numbers into the score.  You can do a whole score at once, if you wish.  There is an undo button in the dialog, which appears when the numbers are up, which will undo them all, or, alternatively, you can just leave them there for illustration, or undo them the usual way (Ctrl-Z/Command-Z). Each annotation can be selected and deleted like any other staff text.  Once you press "Show in score", you can only cancel (relabelled "Leave them") without removing the numbers, or press "Undo show", which also exits, but undoes the numbers first.
![Note times in the score](inScoreShowTimes.png)
