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
//  Version 3.4 14 Jan 2020 improvements/fixes to 3.3, see CHANGES.md
//  Version 3.5 15 Jan 2020 integrate read/write auxiliary handling, report note names.
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2


MuseScore {
      version:  "3.5"
      description: "This plugin generates custom trills with baroque details."
      menuPath: "Plugins.Triller"
      id: dlg

      requiresScore: true

      property int margin: 10
      property var the_note : null;

      width: 400
      height: 224

    /* Facilitates consistent automatic manipulation of the checkboxes. */
    property int n_aux_vals: 2
    property var oben_fields: [{box: obenSemi, val: 1, tpc: -5},
                               {box: obenWhole, val: 2, tpc: 2}]
    property var unten_fields: [{box: untenSemi, val: -1, tpc: 5},
                                {box: untenWhole, val: -2, tpc: -2}]

    onRun: {
          if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
              versionError.open()
              Qt.quit();
              return;
           }

          var note = find_usable_note();
          if (note) {
              the_note = note;
              if (!analyze_current_ornaments(note))
                  beatsField.text = ""; // "Hoc malum fecit signum..."
              noteName.text = get_note_name(note)
              augment_auxiliary_names(oben_fields, note.tpc1);
              augment_auxiliary_names(unten_fields, note.tpc1);
          } else {
              complain("No ornamentable note selected.")
              Qt.quit();
          }
    }

    function set_auxiliary_check(aux, val, default_val) {
        val = val || default_val;   //If 0, use default.
        for (var i = 0; i < n_aux_vals; i++) {
            var field = aux[i];
            field.box.checked = (val == field.val);
        }
    }

    function augment_auxiliary_names(aux, tpc) {
        for (var i = 0; i < n_aux_vals; i++) {
            var field = aux[i];
            field.box.text += " (" + get_tpc_name(tpc + field.tpc) + ")"
        }
    }

    function unique_count(arry) {
        var ctr = {}
        for (var i = 0; i < arry.length; i++) {
            var elt = arry[i];
            ctr[elt] = (ctr[elt] || 0) + 1;
        }
        return Object.keys(ctr).length;
    }

    function compare_pattern(data, start, pattern) {
        for (var i = 0; i < pattern.length; i++) {
            if (data[start] !== pattern[i])  // overrun end ok
                return false;
            start += 1;
        }
        return true;
    }

    function analyze_current_ornaments(note) {
        var events = note.playEvents;
        var N = events.length;
        console.log("N events", N);

        //Assay the "current events", as it were.
        //MS non-Baroque trills will be accepted, but confirmation baroquizes.

        var lens = new Array(N);
        var pitches = new Array(N);
        for (var i = 0; i < N; i++) {
            lens[i] = events[i].len;
            pitches[i] = events[i].pitch;
        }
        console.log("Lens", lens);
        console.log("Pitches", pitches);
        var maxlen = Math.max.apply(Math, lens)
        var minlen = Math.min.apply(Math, lens)
        var nlens = unique_count(lens);
        var maxpitch = Math.max.apply(Math, pitches)
        var minpitch = Math.min.apply(Math, pitches)
        var npitches = unique_count(pitches);
        console.log("maxlen", maxlen, "minlen", minlen,
                    "maxpitch", maxpitch, "minpitch", minpitch,
                    "npitches", npitches, "nlens", nlens);

        // See if we think we understand this ornament. Not too short or too florid,
        // and longest note cannot be other than last.
        if (N < 3 || npitches > 3 || nlens > 2 || maxlen != lens[N-1]) {
            console.log("No extant recognizable ornament.");
            return false;
        }
        var start_main_trill = (npitches == 2 && nlens == 1 && minpitch == 0
                                && compare_pattern(pitches, 0, [0 , maxpitch, 0]));
        // If it doesn't end on the main note
        if  (pitches[N-1] != 0) {
            if (start_main_trill) {
                // We'll accept and lie about MS non-Baroque trills...
                console.log("Start-main end-upper MS trill detected.");
            } else {  // ... but nothing else.
                return false;
            }
        }

        // we're good to go -- set the beats field "good" ...
        beatsField.text = N;

        // Set the oben/unten pitch checkboxes correctly

        set_auxiliary_check(oben_fields, maxpitch, 2);
        set_auxiliary_check(unten_fields, minpitch, -1);

        // Check for long final beat.
        // pitch==0 already checked, as well as len being greatest or same as all
        if (lens[N-1] > minlen+2) { // rounding
            finalField.text = lens[N-1] - minlen;
            // beats still means the same !!
        }

        // look for Vorschlaege
        if (compare_pattern(pitches, 0, [maxpitch, 0, minpitch, 0])) {
            vorOben.checked = true;
            keinVorschlag.checked = false;
        } else if (compare_pattern(pitches, 0, [minpitch, 0, maxpitch, 0])) {
            vorUnten.checked = true;
            keinVorschlag.checked = false;
        }

        // Look for final mordent

        if (   compare_pattern(lens, N-4,    [minlen, minlen, minlen, minlen])
            && compare_pattern(pitches, N-4, [maxpitch, 0, minpitch, 0])) {

            nachMordent.checked = true;
        }

        return true;
    }


    function get_tpc_name(tpc){
        var based_0 = tpc + 1;
        var result = "FCGDAEB"[based_0 % 7];
        var divergence = Math.floor(based_0 / 7);
        var appenda = ["bb", "b", "", "#", "##"];
        return result + appenda[divergence]
    }


    function get_note_name(note) {
        if (note == undefined) {
            return note;
        }
        var tpc = get_tpc_name(note.tpc1)
        return tpc + get_octave_name(tpc, note.pitch)

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

    function get_checked_aux_step(aux) {
        for (var i = 0; i < n_aux_vals; i++)
            if (aux[i].box.checked)
                return aux[i].val;
    } //undefined errs out, but "can't happen".

    function generateTrill() {
        console.log("generateTrill");
        var note = the_note;
        if (!note) {
            console.log("No note at Apply time.")
            return false;
        }

        var oben_steps = get_checked_aux_step(oben_fields);
        var unten_steps = get_checked_aux_step(unten_fields);

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

        function ppush(prog) {
            var len = prog.length;
            trill_beats -= len;
            for (var i = 0; i < len; i++)
                program.push(prog[i]);
        }
                
        if (nachschlag_mordent) {
            trill_beats -= 2;
        }
        if (vor_von_oben) {
            ppush([oben_steps, 0, unten_steps, 0]);
        } else if (vor_von_unten){
            ppush([unten_steps, 0]);
        }
        if (trill_beats < 0) {
            complain("Trill beats specified too few to cover request.");
            return false;
        }
        var reps = Math.floor(trill_beats / 2);
        for (var i = 0; i < reps; i++ ) {
            ppush([oben_steps, 0]);
        }
        if (nachschlag_mordent) {
            ppush([unten_steps, 0]);
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

    Dialog {
    visible: true
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
