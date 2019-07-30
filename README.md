# MuseScorePlugins
My QML Plugins for the MuseScore application

Working with Dale Larson, Matt McClintock, and Dmitrios95, we have effected changes to MuseScore that I have wanted for a long time, to wit, the ability to customize note and appoggiatura attack and release parameters from plugins.

The (long-intended) result of this is a trio of plugins hosted here, which allow customization of note attack and release, fraction of a note consumed by one or more appoggiature, and customized Baroque trills, on an individual note (or selection) basis, via straightforward, convenient GUI interface, removing the need to ever deal with the arcane and clumsy Piano Roll Editor or “hacked portati” or other articulations. Hopefully, with some exposure and design iteration, these will become “standard plugins”, although I would like to see this functionality in the core.

They are provided here directly downloadable.  You must install them into the Plugins directory, and follow the normal directions to install plugins. Right now, these will not work with the Released MuseScore; you need a so-called MuseScore 3.3 “development build” for your OS at least as new as 14:00 UTC (10:00 EST) 30 July 2019.

The plugins and their musical effects are:

* articulation.qml — (most useful if plugin shortcut key defined; I use ctrl-alt T). Allows the setting of on-time and off-time (which start as 0 and 1000) to any value, allowing literally a thousand degrees of detachment or smoothness, providing complete and easy effectuation of phrasing. Some of my favorite non-1000 off-times are 500 (staccato), 850, 900, 920, 960. On-time adjustment is mainly useful for simulating polyphonic violin bowing. Click on a note, type the shortcut, change the value(s), and click Apply or Cancel (or type ESC or Enter). If a region (blue box) is selected, you can impose on off-time on the whole passage (or staff or score as you select). All effects are undoable. It can also be invoked simply to learn the on/off times of a note in a score (just dismiss with ESC).

* appoggiatura.qml — (again, shortcut if you use it often enough, as in the piece below; I use Ctrl-Alt A). How much (what percent) of a note an appoggiatura should consume is a contentious subject, even between historical and current performers and other experts, and is highly context-dependent. While MuseScore currently imposes rigid global answers, this plugin allows you to set the percentage (again, as a 0-1000 “permillage”) for individual occurrences to taste, including multiple and chordal appoggiature. Again, the plugin can be used to simply inspect the current fraction of appoggiatura-decorated notes.

* triller.qml - This facilitates imposition of a Baroque trill, always an even number of notes, any number of notes, on any note, discarding possible previous ornamentation. It does not “chase accidentals”, which is both a deficit and an advantage compared to built-in trills — you have to tell it whether upper and (if needed) lower neighbors are a half- or whole-tone away. You can add pre-strokes (Vorschlag) from above or below, as is common in Baroque music, and a Mordent at the end. “Vorschlag” creates four notes, mordent 2, and anything left in the number of notes you tell it go into trilling. You can play with 6, 8, 10, 12, whatever you want, effects not possible without plugin help. The German terms are used (oben = above, unten = below) because most appropriate trill tables originated in Baroque now-Germany, and do so. It does not now insert ornament graphics (TBD).

Demo of a Bach chorus with almost every note phrased, with text awareness:
https://musescore.com/bsg/gute_nacht_o_wesen

Demo of a very great Bach aria with solo parts fully phrased and customized appoggiature:
https://musescore.com/bsg/erbarme_dich

Demo of trill generator results:
https://musescore.com/bsg/scores/5658151

(Scores customized with these plugins will play correctly in standard MuseScore 3, including the site).

