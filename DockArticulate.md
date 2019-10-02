**2 October 2019  DockArticulate.qml**

**DockArticulate.qml** is a new version of the **articulate.qml** plugin which stays visible, like the Inspector or palettes, and responds every single time a note is entered or otherwise selected (clicked on), or a range is selected or modified, constantly displaying on-time and off-time.  That means that all you have to do to see the on-time and off-time of a note is click on it.  The plugin "docks" in the lower-left-hand corner of the screen, under the palettes, and (like all docked UI elements) can be "undocked" and moved wherever you wish with the little arrows in its title-bar.

The plugin requires 3.3 Beta (or release) of vintage 3.3.0.23833 (Oct 2) or better.  On earlier 3.3 it won't load.

The set and meaning of the input-boxes and buttons are almost identical to those of the **articulate.qml** plugin, and change as selections come and go.  In order to change a numeric value, you must select it with the mouse, as in the Inspector -- it can't auto-select as does **articulate.qml** (for all you did was select a note).  But in one respect, it is more like **articulate.qml** than like the Inspector, *viz.,* your input is not accepted until you press **Apply** or **ENTER** (the Inspector installs intermediate, partially-typed values).  Unlike **articulate.qml**, bad values are not diagnosed (currently), just left there in place.  The tradeoff between using partially-typed values and creating the danger of not **Apply**ing is unclear, but this is what it is currently.

It is not a good idea to assign a shortcut to the plugin (**DockArticulate**), as its whole purpose is to obviate repeated invocation. Simply invoke it by that name from the Plugins menu.  The plugin may be "closed", i.e., removed from the UI, by clicking its **x**, as with other docked elements: there is no longer a **Cancel** button.

The "Show in score" functionality is slightly different.  The **Show in score** button, activated when a range is selected, works the same way.  But in **articulate.qml**, the action of **Leave in place** was associated with exiting the plugin, which has no meaning here.  If you want to leave them in place, just go on editing  your score.  The **Undo them** button is now just **Undo**, and is exactly equivalent to ctrl-Z (Command-Z) Undo (i.e., it applies to any action), and has no particular advantage (other than nostalgia) over simply typing the usual keystroke.

This plugin does not (yet) replace the older one, whose usage model you might still prefer.  I'll try to maintain them in parallel; there is no convenient way to share code in this paradigm.

Please report problems, especially reproducible cases of failures of other MuseScore functions when the plugin is active (displayed).
