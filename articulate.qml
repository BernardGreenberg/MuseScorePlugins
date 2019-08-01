//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2017 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2019 Bernard Greenberg
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

/* This plugin replaces the Piano Roll Editor as the most convenient means of 
   adjusting the on-times and off-times (not "len"s) of notes on a one-by-one
   basis.  This allows you to phrase without the yellow bar jungle (which is
   always there for hard cases).  This even works on appoggiature, but does
   not work on notes with real "ornaments" (not well-defined how to edit).

   Extensions to impose duple- and triple- phrasing patterns are under
   consideration.

   If a nonempty region-selection exists when this invoked, all the notes in it
   will get the off-time you set; grace notes/appogg not affected.

   If there is no region selection but a single note has been clicked on,
   the pitch and on an off times are displayed and you can change the last two.

   Return and ESC are accepted as Apply and Cancel.
*/


MuseScore {
      version:  "3.1"
      description: "This plugin adjusts the on/off times of a note."
      menuPath: "Plugins.Articulation"

      pluginType: "dialog"
      requiresScore: true

      property int margin: 10
      property var range_mode : false
      property var the_note : null

      width:  240
      height: 160

      onRun: {
          if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
	      versionError.open()
              Qt.quit();
	      return;
            }

          console.log("hello adjust articulation: onRun");
          curScore.createPlayEvents();
          var note_count = 0;
          applyToNotesInSelection(function(note, cursor) { note_count += 1;});
          console.log("sel note count", note_count);
          if (note_count > 0) {
              range_mode = true;
          } else {
              the_note = find_usable_note();
              if (!the_note) {
                  console.log("onRun didn't find usable notes")
                  complaintDialog.open()
                  Qt.quit();
              }
              range_mode = false;
          }

        if (range_mode) {
            noteField.text = note_count + " Notes"
            onTime.visible = false;
            onTimeLabel.visible = false;
            pitchLabel.text = "Selection"
            offTime.text = "";
	    showButton.visible = true;
        } else {
          if (the_note) {
              var events = the_note.playEvents;
              var pe0 = events[0];
              onTime.text = pe0.ontime + "";
              offTime.text = (pe0.ontime + pe0.len) + "";
              var tpc = get_tpc_name(the_note.tpc1)
              var octave = get_octave(tpc, the_note.pitch)
              noteField.text = tpc + octave
	      showButton.visible = false;
          }
        }
      }

    function get_tpc_name(tpc){
        var based_0 = tpc + 1;
        var result = "FCGDAEB"[based_0 % 7];
        var divergence = Math.floor(based_0 / 7);
        var appenda = ["bb", "b", "", "#", "##"];
        result = result + appenda[divergence]
        return result

    }

    function get_octave(tpc, pitch) {
        var answer = Math.floor(pitch / 12) - 1;
        if (tpc == "B#" || tpc == "B##") {
            answer -= 1;
        } else if (tpc == "Cb" || tpc == "Cbb") {
            answer += 1;
        }
        return answer + "";
    }


    function find_usable_note() {
        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length == 1) {  // We have a selection list to work with...
            console.log(elements.length, "selections")
            // Loop a bit silly at this point.
            for (var idx = 0; idx < elements.length; idx++) {
                var element = elements[idx]
                console.log("element.type=" + element.type)
                if (element.type == Element.NOTE) {
                    var note = element;
                    var events = note.playEvents;
                    if (events.length == 1) {
                        var mpe0 = events[0];
                        dump_play_ev(mpe0);
                        return note;
                    }                  
                }
            }
        }
        return false;
    }

   function dump_play_ev(event) {
       console.log("on time", event.ontime, "len", event.len, "off time", event.ontime+event.len);
   }

    function applyChanges() {
        var off_time = parseInt(offTime.text)
        if (isNaN(off_time)) {
            return false;
        }
        if (range_mode) {
            curScore.startCmd();
            applyToNotesInSelection(function(note, cursor) {
                var mpe0 = note.playEvents[0];
                mpe0.len = off_time - mpe0.ontime;
            });
            curScore.endCmd();
            return true;
        }
        var note = find_usable_note();
        if (!note) {
            console.log("No note at Apply time.")
            return false;
        }
        var on_time = parseInt(onTime.text)
        if (isNaN(on_time)) {
            return false;
        }
        curScore.startCmd();
        var mpe0 = note.playEvents[0];
        mpe0.ontime = on_time;
        mpe0.len = off_time - on_time;
        curScore.endCmd();
        dump_play_ev(mpe0);
        console.log("Did it!", on_time, off_time);
        return true;    
    }   


    function applyToNotesInSelection(func) {
        var cursor = curScore.newCursor();
        cursor.rewind(1);
                var endStaff;
        if (!cursor.segment) { // no selection
            console.log("No region selection.")
            return false;
        }
        cursor.rewind(1);
        var startStaff = cursor.staffIdx;
        cursor.rewind(2)
        var endStaff = cursor.staffIdx;
        var endTick;
        if (cursor.tick === 0) {
            // this happens when the selection includes
            // the last measure of the score.
            // rewind(2) goes behind the last segment (where
            // there's none) and sets tick=0
            endTick = curScore.lastSegment.tick + 1;
        } else {
            endTick = cursor.tick;
        }
        
        console.log("sel area startStaff " + startStaff + "  endStaff  " + endStaff + " endTick " + endTick);
        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1); // sets voice to 0
                cursor.voice = voice; //voice has to be set after goTo
                cursor.staffIdx = staff;

                while (cursor.segment && (cursor.tick < endTick)) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        // gratia vacua....
                        var notes = cursor.element.notes;
                        for (var k = 0; k < notes.length; k++) {
                            var note = notes[k];
                            func(note, cursor);
                        }
                    }
                    cursor.next();
                }
            }
        }
         return true;
    }

    function showTimeInScore(note, cursor) {
	var npe0 = note.playEvents[0];
	var on_time = npe0.ontime;
	var off_time = on_time + npe0.len;
	if (on_time == 0 && off_time == 1000) {
	    return;
	}
        var timeText = off_time + "&nbsp;";
	if (on_time != 0) {
	    timeText += "\n@" + on_time;
	}
        var staffText = newElement(Element.STAFF_TEXT);
        staffText.text = timeText;
	staffText.placement = Placement.BELOW
	staffText.fontSize = 7;
        cursor.add(staffText);
    }

    function showTimesInScore (){
	applyButton.visible = false;
	showButton.visible = false;
	undoButton.visible = true;
	offTimeLabel.visible = false;
	offTime.visible = false;
	cancelButton.text = "Leave them";
	curScore.startCmd();
	applyToNotesInSelection(showTimeInScore);
	curScore.endCmd();
    }

    function undoTimes() {
	cmd("undo")
	Qt.quit()
    }

    function maybe_finish() {
        if (applyChanges()) {
            Qt.quit()
        }
    }

    GridLayout {
        id: 'mainLayout'
        anchors.fill: parent
        anchors.margins: 10
        columns: 2

        Label {
            id: pitchLabel
            text: "Pitch"
        }
        Label{
            id: noteField
            text: ""
        }
        Label {
            id: onTimeLabel
            text:  "On Time ‰"
        }
        TextField {
            id: onTime
            implicitHeight: 24
            placeholderText: "0"
            Keys.onReturnPressed : {
                maybe_finish()
            }
            Keys.onEscapePressed : {
                Qt.quit()
            }
        }

        Label {
	    id: offTimeLabel
            text:  "Off Time ‰"
        }
        TextField {
            id: offTime
            implicitHeight: 24
            placeholderText: "1000"
            focus: true
            Keys.onReturnPressed : {
                maybe_finish()
            }
            Keys.onEscapePressed : {
                Qt.quit()
            }
        }
        Button {
            id: applyButton
            Layout.columnSpan:1
            text: qsTranslate("PrefsDialogBase", "Apply")
            onClicked: {
                maybe_finish()
            }
        }

        Button {
            id: cancelButton
            Layout.columnSpan: 1
            text: qsTranslate("InsertMeasuresDialogBase", "Cancel")
            onClicked: {
                Qt.quit();
            }
        }
 
        Button {
	   id: showButton
           text: "Show in score"
           enabled: true
           onClicked: {
             showTimesInScore();
           }
         }
        Button {
             id: undoButton
	     visible: false
             text: "Undo show"
	     onClicked: {
		 undoTimes();
	     }
         }
 
    }

 MessageDialog {
      id: complaintDialog
      icon: StandardIcon.Warning
      standardButtons: StandardButton.Ok
      modality: Qt.ApplicationModal
      title: "Invalid or missing note selection"
     text: "No unornamented note is selected."
      detailedText:  "Either you have not selected a note, or " +
         "the note, or one of the notes you have selected, have " +
         "multi-sub-note ornamentation."
     onAccepted: {
         Qt.quit()
      }
   }

 MessageDialog {
      id: versionError
      visible: false
      title: qsTr("Unsupported MuseScore Version")
      text: qsTr("This plugin needs MuseScore 3.3 or later")
      onAccepted: {
         Qt.quit()
         }
      }
}
