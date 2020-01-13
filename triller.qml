//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2017 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2019-2020 Bernard Greenberg
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//  Documentation:  https://musescore.org/en/project/articulation-and-ornamentation-control
//  Version 3.3 13 Jan 2020 decodes ornamentation currently on notes
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2


MuseScore {
      version:  "3.3"
      description: "This plugin generates custom trills with baroque details."
      menuPath: "Plugins.Triller"
      id: dlg

      pluginType: "dialog"
      requiresScore: true

      property int margin: 10
      property var the_note : null;

      width: 400
      height: 224

    onRun: {
          if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
              versionError.open()
              Qt.quit();
              return;
           }

          var note = find_usable_note();
          if (note) {
              the_note = note;
              analyze_current_ornaments(note);
              noteName.text = get_note_name(note)
              
          } else {
              complain("No ornamentable note selected.")
              Qt.quit();
          }
    }

    function dump_dict(word, d) {
        var keys = Object.keys(d);
        var lkeys = keys.length;
        console.log ("#", word, lkeys);
        for (var j = 0; j < lkeys; j++) {
            var key =  keys[j];
            console.log(word, key, d[key]);
        }
    }

    function defaultdict_count(d, elt) {
        d[elt] = (d[elt] || 0) + 1;
    }

    function find_iter(d, fcn) {
        var keys = Object.keys(d);
        var accum = keys[0];
        var len = keys.length;
        for (var i = 1; i < len; i++) {
            accum = fcn(accum, keys[i]);
        }
        return accum;
    }

    function analyze_current_ornaments(note) {
        var lens = {}
        var pitches = {}
        var events = note.playEvents;
        var nevents = events.length;
        console.log("nevents", nevents);
        if (nevents < 3) {
            return false;
        }

        //Assay the "current events", as it were.
        //MS non-Baroque trills will be accepted, but confirmation baroquizes.

        for (var i = 0; i < nevents; i++) {
            var evi = events[i];
            defaultdict_count(lens, evi.len);
            defaultdict_count(pitches, evi.pitch);
        }
        //dump_dict("len", lens);
        //dump_dict("pitch", pitches);
        var maxlen = find_iter(lens, Math.max);
        var minlen = find_iter(lens, Math.min);
        var maxpitch = find_iter(pitches, Math.max);
        var minpitch = find_iter(pitches, Math.min);
        console.log("maxlen", maxlen, "minlen", minlen, "maxpitch", maxpitch, "minpitch", minpitch);

        // Set the oben/unten pitches correctly

        if (maxpitch == 1) {
            obenSemi.checked = true;
            obenWhole.checked = false;
        } else if (maxpitch == 2) {
            obenWhole.checked = true;
            obenSemi.checked = false;
        }
        if (minpitch == -1) {
            untenSemi.checked = true;
            untenWhole.checked = false;
        } else if (minpitch == -2) {
            untenWhole.checked = true;
            untenSemi.checked = false;
        }

        // Check for long finale.

        var finale = events[nevents-1];
        var beats = nevents;
        var finale_len = finale.len;
        var finale_pitch = finale.pitch;
        if (finale_len == maxlen && finale_len >= 3 * minlen && finale_pitch == 0) {
            finalField.text = finale_len-minlen;
            // beats still means the same !!
        } else {
            finale = false;
        }
        beatsField.text = beats;

        // look for Vorschlaege
        if (nevents >= 4 && events[1].pitch == 0 && events[3].pitch == 0) {
            if (events[0].pitch == maxpitch
                && events[2].pitch == minpitch) {

                vorOben.checked = true;

            } else if (events[0].pitch == minpitch
                       && events[2].pitch == maxpitch) {

                vorUnten.checked = true;

            }
        }

        // Look for final mordent

        if (nevents >= 4
            && finale_len == minlen
            && events[nevents-2].len == minlen
            && events[nevents-3].len == minlen

            && finale_pitch == 0
            && events[nevents-2].pitch == minpitch
            && events[nevents-3].pitch == 0
            && events[nevents-4].pitch == maxpitch) {

            nachMordent.checked = true;
        }

        return true;
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
            var answer = Math.floor(pitch / 12) - 1
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

        var final_milles = parseInt(finalField.text);
        if (isNaN(final_milles) || final_milles < 0 || final_milles >=1000) {
            return false;
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
        return function() {install_trill(note, program, final_milles);};
    }

    function install_trill(note, program, final_milles) {
        var trillable_len = 1000 - final_milles;
        var len = Math.floor(trillable_len/program.length);
        var time = 0;
        console.log("Final program:", program)
        curScore.startCmd();
        note.playEvents = []
        var playEvents = note.playEvents;
        for (var i = 0; i < program.length; i++) {
            var pevt = note.createPlayEvent()
            pevt.pitch = program[i];
            pevt.ontime = time;
            if (final_milles && i == program.length - 1) {
                 len += final_milles;
            }
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
            text: "8"
            focus: true
            Keys.onReturnPressed : {
                maybe_finish()
            }
            Keys.onEscapePressed : {
                Qt.quit()
            }
        }
        
        // Row 6

       Label {
          text: "Final ‰"
       }
       TextField {
          id: finalField
          implicitHeight: 24
          text: "0"
          focus: false
          Keys.onReturnPressed: {
              maybe_finish()
          }
          Keys.onEscapePressed: {
             Qt.quit()
          }
        }


        // Row 7

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
                Qt.quit()
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
