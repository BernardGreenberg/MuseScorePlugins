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

/*  The need for this is explained in https://musescore.com/bsg/scores/5446640, let alone the issue
that customization of "how much is eaten out of the main note" by an appoggiatura ought to be
easier to adjust than it is. It is cumbersome even in the piano roll editor.

To use this, click on a note that has an oppoggiatura (make sure it has a different pitch than
the note it prefixes).  Invoke this plugin.  The dividing per-mille will be displayed in
the dialog.  Change it to something else (from 667 to 333 in the usual case on a dotted note),
or any credible number betweem 0 and 1000, not getting too close to either, and click Apply.
Play the measure to hear the effect.  Change is undoable. Return and ESC are recognized.

It can deal with parallel appoggiatura chords (Bach, "Buß und Reu" StMP). It adjust all "grace"
and main notes.

This capability really ought be in the MS inspector, but this is a good work-around if that is too
controversial.

TBD: Recognize and handle unrealized appoggiature
*/

MuseScore {
      version:  "3.0"
      description: "This plugin adjusts the duration of an appoggiatura."
      menuPath: "Plugins.Appoggiatura"

      pluginType: "dialog"
      requiresScore: true

      property int margin: 10

      property var the_note : null;

      width:  240
      height: 120

      onRun: {
          console.log("hello adjust appoggiatura: onRun");
	  curScore.createPlayEvents();  // Needed to get MS to realize the appogg 1st time
	  var note = find_usable_note();
	  if (note) {
	      the_note = note;
	      perMille.text = sum_graces(note) + ""
	  } else {
	      console.log("onRun didn't find a usable appogg")
              complaintDialog.open()
	      Qt.quit();
	  }
      }

    function find_usable_note() {
        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length > 0) {  // We have a selection list to work with...
            console.log(elements.length, "selected elements")
            for (var idx = 0; idx < elements.length; idx++) {
                var element = elements[idx]
                console.log("element.type=" + element.type)
                if (element.type == Element.NOTE) {
                    var note = element;
                    var summa_gratiarum = sum_graces(note);
                    if (summa_gratiarum) {
			var mnplayevs = note.playEvents;
			var mpe0 = mnplayevs[0];
			dump_play_ev(mpe0);
			var fuzz = Math.abs(mpe0.ontime - summa_gratiarum);
			if (fuzz < 4) {
                            return note;
			}
		    }
                }
            }
        }
        return false;  // trigger dismay
    }
    
    function sum_graces(note){
        var chord = note.parent;
        var grace_chords = chord.graceNotes;  //it lies.
        //console.log("grace chords", grace_chords);    
        if (!grace_chords || grace_chords.length == 0) {
	    return false;
	}

        console.log("N grace chords", grace_chords.length);
        var summa = 0
        for (var i = 0; i < grace_chords.length; i++) {
            var grace_chord = grace_chords[i];;
            //console.log("grace chord#", i,  grace_chord);
            var grace_note = grace_chord.notes[0];
            //console.log("grace note", i, "[0]" , grace_note);
            var gpe0 = grace_note.playEvents[0];
            dump_play_ev(gpe0);
            summa += gpe0.len;
        }
        console.log("summa", summa);
        return summa;
    }

   function dump_play_ev(event) {
       console.log("on time", event.ontime, "len", event.len, "off time", event.ontime+event.len);
   }

    function applyChanges() {
	var note = the_note;
	if (!note) {
	    //console.log("No note at apply time.")
	    return false;
	}
        var new_transit = parseInt(perMille.text);
        if (isNaN(new_transit)) {
            return false;
        }
	//console.log("Begin apply pass, new transit=", new_transit);

        var mpe0 = note.playEvents[0];
        var orig_transit = mpe0.ontime;  // must be so if we are here.
        var inc = new_transit - orig_transit;
        var grace_chords = note.parent.graceNotes; //really
        //console.log("Apply pass grace_chords", grace_chords);
	var ngrace = grace_chords.length;  //chords, really
	var new_grace_len = Math.floor(new_transit/ngrace);

        curScore.startCmd();
	var current = 0;
	for (var i = 0; i < ngrace; i++) {
	    var chord = grace_chords[i];
	    for (var j = 0; j < chord.notes.length; j++) {
		var gn0 = chord.notes[j];
		var pe00 = gn0.playEvents[0];
		pe00.len = new_grace_len;
		pe00.ontime = current;
	    }
	    current += new_grace_len;
	}
	var main_on_time = current;
	var main_off_time = mpe0.ontime + mpe0.len;
	var main_len = main_off_time - main_on_time;
	var notachord = note.parent;
	var chord_notes = notachord.notes;
	for (var k = 0; k < chord_notes.length; k++) {
	    var cnote = chord_notes[k];
	    var mpce0 = cnote.playEvents[0];
	    mpce0.ontime = main_on_time;
	    mpce0.len = main_len;
	}
        curScore.endCmd()
        console.log("Did it!", current);
        return true;    
    }   

    function getCurrent() {
	var note = find_usable_note(false);
	if (!note) {
	    //console.log("No note at getCurrent time.")
	    return false;
	}
	var summa = sum_graces(note);
	if (!summa) {
	    //console.log("No sum of graces at getCurrent time.")
	    return false;
	}
	perMille.text = summa + ""
	return true;
    }
   
    function maybe_finish() {
	if (applyChanges()) {
	    Qt.quit();
	}
    }

    GridLayout {
	id: 'mainLayout'
	anchors.fill: parent
	anchors.margins: 10
	columns: 2

	Label {
	    text:  "Per Mille"
        }
	TextField {
	    id: perMille
	    implicitHeight: 24
	    placeholderText: "/1000"
	    focus: true
	    Keys.onEscapePressed : {
		Qt.quit()
	    }
	    Keys.onReturnPressed : {
		maybe_finish();
	    }
	}
	Button {
	    id: applyButton
	    Layout.columnSpan:1
	    text: qsTranslate("PrefsDialogBase", "Apply")
	    onClicked: {
		maybe_finish();
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

    }

 MessageDialog {
      id: complaintDialog
      icon: StandardIcon.Warning
      standardButtons: StandardButton.Ok
      modality: Qt.ApplicationModal
      title: "Invalid or missing appoggiatura selection"
     text: "No note having appoggiature is selected."
      detailedText:  "Either you have not selected a note, or " +
         "the note, or none of the notes you have selected, have " +
	 "any appoggiature before them."
     onAccepted: {
	 console.log("Messagedlg onaccepted");
         Qt.quit()
      }
   }


}
