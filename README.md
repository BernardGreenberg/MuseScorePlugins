# MuseScorePlugins
My QML Plugins for the MuseScore application

**5/24/2024 — These plugins are not usable with MuseScore ("Studio") Version 4, and I have no plans to make them so. MuseScore 3.6 is still available.**  Others are welcome to try, but my trials indicate that internal changes in the application require change to the latter of undetermined nature and extent.

**New 9/21/2021 — I have created a 12 minute instruction video on the articulation plugin:**  https://youtu.be/HXM7WoR2TPk. It shows _why_ you should use it, as well.

Working with Dale Larson, Matt McClinch, and Dmitri Ovodok (@dmitrio95), we have effected changes to MuseScore that I have wanted for a long time, to wit, the ability to customize note and appoggiatura attack and release parameters from plugins toward artistic performance realization.

The (long-intended) result of this is a trio of plugins hosted here, which allow customization of note attack and release, fraction of a note consumed by one or more _appoggiature_, and customized Baroque trills, on an individual note (or selection) basis, via straightforward, convenient GUI interface, removing the need ever to deal with the arcane and cumbersome Piano Roll Editor or “hacked *portati*” or other articulations. Hopefully, with some exposure and design iteration, these will become “standard plugins”, although I would like to see this functionality in the core.

The plugins provided here are directly downloadable.  You must install them into the Plugins directory, and follow the normal directions to install plugins (https://musescore.org/en/handbook/3/plugins). 

Note that **these plugins require MuseScore 3.3** (or later): they will not work with any earlier version. MuseScore 3.3 is now available as the standard release.

In MuseScore, a note's _on-time_ and _off-time_ are, respectively, the delay of its onset and the time of its release as actually performed as opposed to its notated position and time-value (i.e., quarter (crochet), eighth (quaver), etc.). The note's notated value is measured in _per mille_, ‰, like percent, but in thousandths instead of hundredths. If a note starts exactly when notated, its on-time is 0.  If a note ends exactly when notated, its off-time is 1000.  The MuseScore *staccato* accent, for example, changes off-time to 500 (i.e. reduces the note to half its indicated length).  All of these plugins, therefore, deal in time as *per mille* (1000ths).

It is important to note that a tied note (not slurred) in MuseScore is represented as different notes in each chord; that means that adjusting the off-time "final component" of a tied note works (in my opinion) properly.  This is extremely convenient when adjusting the end of suspensions in polyphonic music where notes starting at different times end at the same time. Please see the accompanying [adjustingTiedNotes.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/adjustingTiedNotes.md).

In the discussion below, I describe keystrokes in Windows terms; ctrl-alt X on Windows becomes Command-Option X on the Mac.

The plugins and their musical effects are:

* **articulation.qml** — (most useful if a plugin shortcut key is defined; I use ctrl-alt T). Allows the setting of on-time and off-time (initially 0 and 1000) to any value, allowing literally a thousand degrees of detachment or smoothness, providing complete and easy effectuation of phrasing. Some of my favorite non-1000 off-times are 500 (staccato), 850, 900, 920, 960. On-time adjustment is mainly useful for simulating violin "cross-bowing". Click on a note, type the shortcut, change the value(s), and click Apply or Cancel (or press Enter or ESC). If a region (blue box) is selected, you can impose an off-time on the whole passage (or staff or score as you select): this is also (non-obviously) useful to select simultaneous notes in _adjacent staves_ to phrase them identically, i.e., as a chord. All effects are undoable. The plugin can also be invoked simply to learn the on/off times of a note in a score (just dismiss it with ESC). \
\
Version 3.1 supports annotating scores with on-time/off-time numbers. See [CHANGES.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/CHANGES.md). \
\
(21 Sep 2021) See the instruction video on it, https://youtu.be/HXM7WoR2TPk, as well.\
\
(2 Oct 2019) There is a new version, [DockArticulate.qml](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/DockArticulate.qml), which provides the same functionality as an always-visible "dock plugin", which is considerably more convenient.  See [DockArticulate.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/DockArticulate.md).

* **appoggiatura.qml** — (again, assign a shortcut if you use it often enough, as in the aria below; I use Ctrl-Alt A). How much (what percent) of a note an appoggiatura should consume is contentious, even between historical and current performers and other experts, and is highly context-dependent. While MuseScore currently imposes fixed, procrustean answers, this plugin allows you to set the fraction for each individual occurrence to taste, including multiple and chordal *appoggiature*. Again, the plugin can be used to simply inspect the current appoggiatura fraction of so-decorated notes.  The plugin can now (v. 3.1) create overlap between *appoggiature* and the main note.  See [CHANGES.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/CHANGES.md).

* **triller.qml** - This facilitates construction of a Baroque trill, always an even number of notes, any number of notes, on any note, discarding possible previous ornamentation. It does not “chase accidentals”, which is both a deficit and an advantage compared to built-in trills — you have to tell it whether upper and (if needed) lower neighbors are a half- or whole-tone away. You can add a pre-stroke (*Vorschlag*) from above or below, as is common in Baroque music, and a mordent at the end. *Vorschlag* creates four notes, mordent 2, and anything remaining in the number of notes you tell it (0 remaining is OK) goes into trilling. You can experiment with 6, 8, 10, 12, or whatever you want, effects not possible without plugin help. The German terms are used (*oben* = above, *unten* = below) because most appropriate trill tables originated in Baroque now-Germany, and do so. The non-_Vorschlag_ portion (body) of a trill always starts from the upper note. You can now (v. 3.2) specify a trailing “step” of the main note (see [CHANGES.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/CHANGES.md)). To trill long (e.g., multi-measure) tied notes, apply the plugin to each component appropriately. The plugin can craft customized “turns” as well (see [TrillerTurns.md](https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/TrillerTurns.md)). The plugin does not now insert score graphics (TBD). Except for _Vorschlag von unten_ trills, trills (as per 'Baroque' in MuseScore) always start on the upper note. Trills starting on the lower are planned.

Here are four posted scores, two serious, completely-rendered Bach movements, and a two short demos.

* [Demo of a Bach chorus with almost every note phrased, with text awareness (_Gute Nacht, o Wesen_, BWV 227#9)](https://BernardGreenberg.com/Scores/gute_nacht_o_wesen)
* [Demo of a renowned Bach aria with all parts fully phrased and customized *appoggiature* (_Erbarme dich_, StMP)](https://BernardGreenberg.com/Scores/erbarme_dich)
* [Demo of simulated violin polyphonic cross-bowing (opening of Bach Chaconne)](https://BernardGreenberg.com/Scores/phrased_chaconne_intro)
* [Demo of trill generator results](https://BernardGreenberg.com/Scores/5658151)

And as lagniappe I offer:

* **rednote.qml** - For music teachers, or those like myself, who "play one on TV". This tiny plugin allows you to (undoably) turn notes red.  Install it the usual way and assign it a shortcut (I use ctrl-alt R).  Click a single note (or range-select and click "Notes") and strike the key.  You won't see the single-note effect immediately because note selection will hide it, but if you have the Inspector open, you'll see its color pane turn embarrassingly red, and when you click off it, its redness will be manifest.  Mark parallel fifths, unprepared dissonances, or notes you particularly enjoy, then screenshot, email, and just wait...


Link to official MuseScore Plugin Project page for this project: https://musescore.org/en/project/articulation-and-ornamentation-control

Running "to be done/ideas" list here at https://github.com/BernardGreenberg/MuseScorePlugins/blob/master/TBD.md .
