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
//
//  3.4 - 4 Oct 19 - clear_all if click on non-note.
//  3.5 - 5 Oct 19 - complex test for the latter for click-once on blank.
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

   Select and load from the Plugin manager. No shortcut, please.
   Invoke from the plugin manager -- it will dock at the bottom left.

   Expand space to show it all, or undock it with <> and put it where you want.
   If you click on a note, the on-time and off-time of the note will be
   displayed, and you can change it.

   If you click on a measure or select a region, you will be offered
   the change of all notes in the region to the same off-time, no on-time.

   You can show all non-1000 off-times with the "Show in score" button, and
   remove them with either UNDO or the button then offered.

    MUST PRESS APPLY or ENTER into field for changes to take effect.

*/


MuseScore {
      version:  "3.5"
      description: "This plugin adjusts the on/off times of a note."
      menuPath: "Plugins.DockArticulate"

      pluginType: "dock";
      dockArea: "left";
      implicitHeight: 160;
      implicitWidth: 240;

      property int margin: 10
      property var range_mode : false
      property var the_note : null
      property var stop_recurse : false;
      property var nnflag : "not-note"
      property var display_up : false

      width:  240
      height: 160

    onScoreStateChanged: {
        if (stop_recurse)
            return;
        if (state.selectionChanged) {
            get_notes()
        }
	else if (display_up) {
	    // This complex test fires the first time a user clicks blank space
	    // when something is selected. This hook is called, but state.selectionChanged
	    // is not on (it should be). The second time the blank space is clicked, it
	    // works properly (v. 3.5).  Unfortunately, this turns off the nice feature
	    // of triggering us on keyboard-entered notes (to be solved).
	    if (!curScore.selection || !curScore.selection.elements ||
		(curScore.selection.elements.len == undefined) || 
		(curScore.selection.elements.len == 0) ) {

		clear_all();
	    }
	}
     }

      onRun: {
          if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
	      versionError.open()
              Qt.quit();
	      return;
            }

          console.log("adjust articulation docking plugin: onRun");
          stop_recurse = false;
         // curScore.createPlayEvents();  // pointless for dock plugin.
	  clear_all();
	  pitchLabel.text = "";
	  pitchField.visible = true;
	  pitchField.text = "Select notes";
	  display_up = false;
      }

    function get_notes() {
	the_note = false;
        var note_count = 0;
	undoButton.visible = false;
        
	var val = find_usable_note();
	if (val == nnflag) {
	    clear_all();
	    return;
	}
	the_note = val;
	range_mode = false;
	if (! the_note) {
	    note_count = 0;
            applyToNotesInSelection(function(note, cursor) { note_count += 1;});
            if (note_count > 0)
		range_mode = true;
        }

        if (range_mode) {
            pitchField.text = note_count + " Notes"
            onTime.visible = false;
            onTimeLabel.visible = false;
            offTime.visible = true;
            offTimeLabel.visible = true;
            applyButton.visible = true;
            pitchLabel.text = "Selection"
            pitchLabel.visible = true;
	    pitchField.visible = true;
            offTime.text = "";
            showButton.visible = true;
	    display_up = true;
	    
        } else if (the_note) {
            var events = the_note.playEvents;
            var pe0 = events[0];
            onTime.visible = true;
	    onTimeLabel.visible = true;
            offTime.visible = true;
	    offTimeLabel.visible = true;
            pitchLabel.visible = true;
	    pitchField.visible = true;
            applyButton.visible = true;

            showButton.visible = false;

            onTime.text = pe0.ontime + "";
            offTime.text = (pe0.ontime + pe0.len) + "";
            var tpc = get_tpc_name(the_note.tpc1)
            var octave = get_octave(tpc, the_note.pitch)
	    pitchLabel.text = "Pitch";
            pitchField.text = tpc + octave
	    display_up = true;

        } else {
	    clear_all();
	}
    }

    function clear_all() {
	onTime.visible = false;
        offTime.visible = false;
        applyButton.visible = false;
        pitchLabel.visible = pitchField.visible = false;
        onTimeLabel.visible = offTimeLabel.visible = false;
        showButton.visible = false;
	the_note = false;
	display_up = false;
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
                if (element.type == Element.NOTE) {
                    var note = element;
                    var events = note.playEvents;
                    if (events.length == 1) {
                        var mpe0 = events[0];
                       // dump_play_ev(mpe0);
                        return note;
                    } else return nnflag;      
                } else {
		    return nnflag;
		}
            }
        }
        return false;
    }

   function dump_play_ev(event) {
       console.log("on time", event.ontime, "len", event.len, "off time", event.ontime+event.len);
   }

    function is_num(val) {
	return /^-?\d+$/.test(val); // Allow negative values for off-beat articulations
    }

    function applyChanges() {

        if (!is_num(offTime.text)) {
	    //Doesn't work -- input boxes can't receive input
	    //until score is focused first, unclear why, so comment out.
	    inputError.open();
            return false;
        }
        var off_time = parseInt(offTime.text)
        if (range_mode) {
	    stop_recurse = true;
            curScore.startCmd();
            applyToNotesInSelection(function(note, cursor) {
                var mpe0 = note.playEvents[0];
                mpe0.len = off_time - mpe0.ontime;
            });
            curScore.endCmd();
	    stop_recurse = false;
            return true;
        }
        var note = find_usable_note();
        if (!note) {
            console.log("No note at Apply time.")
            return false;
        }
        if (!is_num(onTime.text)) {
//	    inputError.open();
            return false;
        }
        var on_time = parseInt(onTime.text)
        stop_recurse = true;
        curScore.startCmd();
        var mpe0 = note.playEvents[0];
        mpe0.ontime = on_time;
        mpe0.len = off_time - on_time;
        curScore.endCmd();
        stop_recurse = false;
        dump_play_ev(mpe0);
        console.log("Did it!", on_time, off_time);
        return true;    
    }   


    function applyToNotesInSelection(func) {

        var cursor = curScore.newCursor();
        cursor.rewind(1);

        var endStaff;
        if (!cursor.segment) { // no selection
            return;
        }

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
        cursor.rewind(1);

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
			    if (note.type == Element.NOTE)
				func(note, cursor);
                        }
                    }
                    cursor.next();
                }
            }
        }
	cursor.rewind(1);  // Score gets in non-notable state if not ....
    }

    function showTimeInScore(note, cursor) {
	var npe0 = note.playEvents[0];
	var on_time = npe0.ontime;
	var off_time = on_time + npe0.len;
	if (on_time == 0 && off_time == 1000) {
	    return;
	}
        var timeText = off_time; //attempt to use nbsp crashed app at readback
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
	curScore.startCmd();
	applyToNotesInSelection(showTimeInScore);
	curScore.endCmd();
    }

    function undoTimes() {
	cmd("undo")
    }


    GridLayout {
        id: 'mainLayout'
        anchors.fill: parent
        anchors.margins: 10
        columns: 2

        Label {
            id: pitchLabel
	    visible : true
            text: "Pitch"
             anchors.fill: parent
        }
        Label{
            id: pitchField
	    visible:true
            text: ""
        }
        Label {
            id: onTimeLabel
	    visible: false;
            text:  "On Time ‰"
        }
        TextField {
            id: onTime
	    visible: false
            implicitHeight: 24
            placeholderText: "0"
            Keys.onReturnPressed : {
                applyChanges()
            }
        }

        Label {
	    visible: true
	    id: offTimeLabel
            text:  "Off Time ‰"
        }
        TextField {
            id: offTime
	    visible : true
            implicitHeight: 24
            placeholderText: "1000"
            Keys.onReturnPressed : {
                applyChanges()
            }
        }
        Button {
            id: applyButton
	    visible: true
            Layout.columnSpan:1
            text: qsTranslate("PrefsDialogBase", "Apply")
            onClicked: {
                applyChanges()
            }
        }

     
 
        Button {
	    id: showButton
	    visible: false
           text: "Show in score"
           enabled: true
           onClicked: {
             showTimesInScore();
           }
         }
        Button {
             id: undoButton
	     visible: false
             text: "Undo"
	     onClicked: {
		 undoTimes();
                 undoButton.visible = false;
	     }
         }
 
    }



    MessageDialog {
	id: inputError
	visible: false
	title: "Numeric input error"
	text: "On or off time not a number or out of range."
	onAccepted: {
	    close();
	    get_notes()
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
