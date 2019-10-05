**2 October 2019 — DockArticulate.qml**

**DockArticulate.qml** is a new version of the **articulate.qml** plugin which stays visible, like the Inspector or palettes, and responds every single time a note is entered or otherwise selected (clicked on), or a range is selected or modified, constantly displaying on-time and off-time.  That means that all you have to do to see the on-time and off-time of a note is click on it.  The plugin "docks" in the lower-left-hand corner of the screen, under the palettes, and (like all docked UI elements) can be "undocked" and moved wherever you wish with the little arrows in its title-bar.

The plugin requires 3.3 Beta (or release) of vintage 3.3.0.23833 (Oct 2) or better.  On earlier 3.3 it won't load.

The set and meaning of the input-boxes and buttons are almost identical to those of the **articulate.qml** plugin, and change as selections come and go.  In order to change a numeric value, you must select it with the mouse, as in the Inspector -- it can't auto-select as does **articulate.qml** (for all you did was select a note).  But in one respect, it is more like **articulate.qml** than like the Inspector, *viz.,* your input is not accepted until you press **Apply** or **ENTER** (the Inspector installs intermediate, partially-typed values).  As with **articulate.qml**, if you enter a bad value in either input box, these values will not be used; since the plugin doesn't "dismiss" as does **articulate.qml**, you will know that the values were good when the selection box around the input boxes goes away (**articulate.qml** will close its dialog when values are accepted, which is not an option here). If either value is bad, the selection box will stay.

It is of little value to assign a shortcut to the plugin (**DockArticulate**), as its whole purpose is to obviate repeated invocation. Simply invoke it by that name from the Plugins menu.  The plugin may be "closed", i.e., removed from the UI, by clicking its **x**, as with other docked elements: there is no longer a **Cancel** button.

The "Show in score" functionality is slightly different.  The **Show in score** button, activated when a range is selected, works the same way.  But in **articulate.qml**, the action of **Leave in place** was associated with exiting the plugin, which has no meaning here.  If you want to leave them in place, just go on editing  your score.  The **Undo them** button is now just **Undo**, and is exactly equivalent to ctrl-Z (Command-Z) Undo (i.e., it applies to any action), and has no particular advantage (other than nostalgia) over simply typing the usual keystroke.

(5 Oct 2019) With this plugin, an "articulation browse mode" is possible; it's not something the plugin does, but something you can do.  If **DockArticulate** is active, you can click on a note and press "Arrow Right" repeatedly to step through a melody, displaying the articulation times of each note as you do, without any additional gesture.

This plugin does not (yet) replace the older one, whose usage model you might still prefer.  I'll try to maintain them in parallel; there is no convenient way to share code in this paradigm.

Note that the use of any other plugin, in particular "dialog"-type plugins such as **appoggiatura.qml** or **TempoChange**, will cause **DockArticulate** to close its panel when the other plugin closes.  This is currently (3 Oct 2019) a design problem in Qt/MuseScore, and is true of any dock-type plugin. **rednote.qml** has been upgraded to ***not*** dismiss open dock plugins in this fashion (although it is not a "dialog"-type plugin).

Please report problems, especially reproducible cases of failures of other MuseScore functions when the plugin is active (displayed).
