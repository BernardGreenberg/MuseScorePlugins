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




MuseScore {
      version:  "3.0"
      description: "This plugin generates custom trills with baroque details."
      menuPath: "Plugins.Triller"

      pluginType: "dialog"
      requiresScore: true

      property int margin: 10
      property var the_note : null;

      width: 400
      height: 200

    onRun: {
	  if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
	      versionError.open()
              Qt.quit();
	      return;
           }

          console.log("hello triller: onRun");
	  var note = find_usable_note();
	  if (note) {
	      the_note = note;
	      noteName.text = get_note_name(note)
	  } else {
	      complain("No ornamentable note selected.")
              Qt.quit();
          }
      }



    function get_note_name(note) {
	if (note == undefined) {
	    return note;
	}
	var tpc = get_tpc_name(note.tpc1)
	return tpc + get_octave_name(tpc, note.pitch)

	function get_tpc_name(tpc){
            var based_0 = tpc + 1;
            var result = "FCGDAEB"[based_0 % 7];
            var divergence = Math.floor(based_0 / 7);
            var appenda = ["bb", "b", "", "#", "##"];
            return result + appenda[divergence]
	}

	function get_octave_name(tpc, pitch) {
            var answer = Math.floor(pitch / 12) - 1;
            if (tpc == "B#" || tpc == "B##") {
		answer -= 1;
            } else if (tpc == "Cb" || tpc == "Cbb") {
		answer += 1;
            }
            return answer + "";
	}
    }

    function find_usable_note() {
        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length == 1) {  // We have a selection list to work with...
            var element = elements[0]
            if (element.type == Element.NOTE) {
                return element;
            }
        }
        return false;
    }

    function generateTrill() {
        console.log("generateTrill");
        var note = the_note;
        if (!note) {
            console.log("No note at Apply time.")
            return false;
        }
        var oben_steps;
        var unten_steps;
        if (obenWhole.checked) {
            oben_steps = 2;
        } else {
            oben_steps = 1;
        }
        if (untenWhole.checked) {
            unten_steps = -2;
        } else {
            unten_steps = -1;
        }
        var vor_von_oben = vorOben.checked;
        var vor_von_unten = vorUnten.checked;
        var nachschlag_mordent = nachMordent.checked;

        var beats = parseInt(beatsField.text);
        if (isNaN(beats)){
            return false;
        }
        if (beats & 1) {
            beats += 1
        }

        var program = []
        var trill_beats = beats
        if (nachschlag_mordent) {
            trill_beats -= 2;
        }
        if (vor_von_oben) {
            trill_beats -= 4;
            program.push(oben_steps);
            program.push(0);
            program.push(unten_steps);
            program.push(0);
        } else if (vor_von_unten){
            trill_beats -= 2;
            program.push(unten_steps);
            program.push(0);
        }
        if (trill_beats < 0) {
            complain("Trill beats specified too few to cover request.");
            return false;
        }
        var reps = Math.floor(trill_beats / 2);
        for (var i = 0; i < reps; i++ ) {
            program.push(oben_steps);
            program.push(0);
        }
        if (nachschlag_mordent) {
            program.push(unten_steps);
            program.push(0);
        }
        return function() {install_trill(note, program);};
    }

    function install_trill(note, program) {
        var len = Math.floor(1000/program.length);
        var time = 0;
        console.log("Final program:", program)
        curScore.startCmd();
        note.playEvents = []
        var playEvents = note.playEvents;
        for (var i = 0; i < program.length; i++) {
            var pevt = note.createPlayEvent()
            pevt.pitch = program[i];
            pevt.ontime = time;
            pevt.len = len;
            playEvents.push(pevt)                 // Append to list
            time += len;
        }
        curScore.endCmd();
    }   

    function maybe_finish() {
        var continuation = generateTrill();
        if (continuation) {
	    continuation();
            Qt.quit();
        }
    }

    GridLayout {
        id: 'mainLayout'
        anchors.fill: parent
        anchors.margins: 10
        columns: 2

	//   Row 0

	Label {
	    text: "Note"
	}
	Label {
	    id: noteName
	    text: " "
	}

	// Row 1

        Label {
            text: "Oben ="
        }
        // These "radio buttons" don't exclude each other.
        // We have to teach them how to do their job.
        RowLayout {
            RadioButton {
                id: obenWhole
                checked: true
                text: qsTr("Ton")
                onClicked: {
                    obenSemi.checked = false
                }
            }

            RadioButton {
                id: obenSemi
                text: qsTr("Halbton")
                onClicked: {
                    obenWhole.checked = false
                }
            }
        }

	// Row 2

        Label {
            text: "Unten ="
        }
        RowLayout {
            RadioButton {
                id: untenWhole
                text: qsTr("Ton")
                onClicked: {
                    untenSemi.checked = false
                }
            }


            RadioButton {
                id: untenSemi
                checked: true
                text: qsTr("Halbton")
                onClicked : {
                    untenWhole.checked = false
                }
            }
        }

	// Row 3

        Label {
            text: "Vorschlag"
        }

        RowLayout {
            RadioButton {
                id: vorOben
                text: qsTr("von oben")
                onClicked: {
                    vorUnten.checked = false
                    keinVorschlag.checked = false
                }
            }
            RadioButton {
                id: vorUnten
                text: qsTr("von unten")
                onClicked: {
                    vorOben.checked = false
                    keinVorschlag.checked = false
                }
            }
            RadioButton {
                id: keinVorschlag
                checked: true
                text: qsTr("kein")
                onClicked: {
                    vorUnten.checked = false
                    vorOben.checked = false
                }

            }
        }

	// Row 4

        Label {
            text: " "
        }

        RowLayout {
            CheckBox {
                id: nachMordent
                checked: false
                text: qsTr("Nachschlag-Mordent")
            }
        }

	// Row 5

        Label {
            text:  "Schläge"
        }
        TextField {
            id: beatsField
            implicitHeight: 24
            placeholderText: "8"
            focus: true
            Keys.onReturnPressed : {
                maybe_finish()
            }
            Keys.onEscapePressed : {
                Qt.quit()
            }
        }

	// Row 6

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
    }

    function complain(text) {
        complaintDialog.text = text;
        complaintDialog.open();
    }

 MessageDialog {
      id: complaintDialog
      icon: StandardIcon.Warning
      standardButtons: StandardButton.Ok
      modality: Qt.ApplicationModal
      title: "Trill generator usage error"
      text: "Triller usage error."
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
