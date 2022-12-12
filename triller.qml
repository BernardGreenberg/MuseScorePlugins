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
//  Version 3.6 10 Apr 2020 baroque trill is now an option. If unchecked, normal trill is generated.
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0


MuseScore {
    version:  "3.5"
    description: "This plugin generates custom trills with baroque details."
    menuPath: "Plugins.Triller"
    id: dlg

    pluginType: "dialog"
    requiresScore: true

    property int margin: 10
    property var the_note : null;

    width: 640
    height: 480

    /* Facilitates consistent automatic manipulation of the checkboxes. */
    property int n_aux_vals: 3
    property var oben_fields: [{box: obenSemi, val: 1, tpc: -5},
        {box: obenWhole, val: 2, tpc: 2},
        {box: obenSesqui, val: 3, tpc: -3}]
    property var unten_fields: [{box: untenSemi, val: -1, tpc: 5},
        {box: untenWhole, val: -2, tpc: -2},
        {box: untenSesqui, val: -3, tpc: 3}]

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

    Settings {
        id: settings
        category: "Plugin-Triller"
        property alias midpointSlider: midpointSlider.value
        property alias curveType: curveType.currentIndex
    }

    function getFloatFromInput(input)
    {
        var value = input.text;
        if (value == "") {
            value = input.placeholderText;
        }
        return parseFloat(value);
    }

    function getExpFromInput(input)
    {
        return getFloatFromInput(input) / 100;
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
        // If it doesn't end on the main note: either it has a Nachschlag or it is not baroque
        if  (pitches[N-1] != 0) {
            if (start_main_trill) {
                // MS non-Baroque trills start from lower note (main pitch). This is the case detected here...
                console.log("Start-main end-upper MS trill detected.");
            } else if (pitches[N-1] == minpitch) { // probably has a Nachschlag
                console.log("Start-main end-upper MS trill with Nachschlag detected.");
            } else{  // ... but nothing else.
                console.log("No valid trill detected.");
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

        // ToDo: there is no Vorschlaege or Nachschlaege if it's not baroque (baroque means start from upper). Vorschlaege and Nachschlaege only make sense when it starts from lower. Check this and treat it, maybe leaving a message.

        // look for Vorschlaege
        if (compare_pattern(pitches, 0, [maxpitch, 0, minpitch, 0])) {
            vorOben.checked = true;
            keinVorschlag.checked = false;
            cb_baroque.checked = true;
        } else if (compare_pattern(pitches, 0, [minpitch, 0, maxpitch, 0])) {
            vorUnten.checked = true;
            keinVorschlag.checked = false;
            cb_baroque.checked = true;
        }

        // Look for final mordent

        if (   compare_pattern(lens, N-4,    [minlen, minlen, minlen, minlen])
                && compare_pattern(pitches, N-4, [maxpitch, 0, minpitch, 0])) {

            nachMordent.checked = true;
            cb_baroque.checked = true;
        } else if (   compare_pattern(lens, N-4,    [minlen, minlen, minlen, minlen])
                   && compare_pattern(pitches, N-4, [0, maxpitch, 0, minpitch])) {
            nachMordent.checked = true;
            cb_baroque.checked = false;
        } else if (pitches[N-1] == 0) { // Look for baroque if there is no final mordent
            cb_baroque.checked = true;
        } else {
            cb_baroque.checked = false;
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
        
        var baroque_trill = cb_baroque.checked;

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
            if (baroque_trill) {
                ppush([oben_steps, 0]);
            } else {
                ppush([0, oben_steps]);
            }
        }
        if (nachschlag_mordent) {
            if (baroque_trill) {
                ppush([unten_steps, 0]);
            } else {
                ppush([0, unten_steps]);
            }
        }
        return function() {install_trill(note, program, final_milles);};
    }

    function install_trill(note, program, final_milles) {
        var trillable_len = 1000 - final_milles;
        var len = Math.floor(trillable_len/program.length);
        var time = 0;
        var time_lin = 0;
        console.log("Final program:", program)
        curScore.startCmd();
        note.playEvents = []
        var playEvents = note.playEvents;

        // for expressive expansion:
        var midPoint = ((curveType.isLinear) ? 50.0 : midpointSlider.value) / 100; //linear == hit midpoint at 50% tickRange
        var p = Math.log(0.5) / Math.log(midPoint);
        console.log("Expansion p:", p)

        for (var i = 0; i < program.length; i++) {
            var pevt = note.createPlayEvent()
            pevt.pitch = program[i];
            pevt.ontime = time;
            if (final_milles && i == program.length - 1) {
                len += final_milles;
            }
            pevt.len = len;
            playEvents.push(pevt)                 // Append to list
            time_lin += len;

            // expression
            time = trillable_len*Math.pow((i + 1)/program.length, p);
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
        columns: 3

        focus: true

        //   Row 0

        Label {
            text: "Note"
            Layout.columnSpan:2
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
            Layout.columnSpan:2
            RadioButton {
                id: obenSesqui
                //checked: true
                text: qsTr("3/2 Ton")
                onClicked: {
                    obenSemi.checked = false
                    obenWhole.checked = false
                }
            }
            
            RadioButton {
                id: obenWhole
                checked: true
                text: qsTr("Ton")
                onClicked: {
                    obenSemi.checked = false
                    obenSesqui.checked = false
                }
            }

            RadioButton {
                id: obenSemi
                text: qsTr("Halbton")
                Layout.columnSpan:2
                onClicked: {
                    obenWhole.checked = false
                    obenSesqui.checked = false
                }
            }
        }

        // Row 2

        Label {
            text: "Unten ="
        }
        RowLayout {
            Layout.columnSpan:2
            RadioButton {
                id: untenSesqui
                text: qsTr("3/2 Ton")
                onClicked: {
                    untenSemi.checked = false
                    untenWhole.checked = false
                }
            }
            
            RadioButton {
                id: untenWhole
                text: qsTr("Ton")
                onClicked: {
                    untenSemi.checked = false
                    untenSesqui.checked = false
                }
            }


            RadioButton {
                id: untenSemi
                checked: true
                text: qsTr("Halbton")
                Layout.columnSpan:2
                onClicked : {
                    untenWhole.checked = false
                    untenSesqui.checked = false
                }
            }
        }

        // Row 3

        Label {
            text: "Vorschlag"
        }

        RowLayout {
            Layout.columnSpan:2
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
            Layout.columnSpan:2
            CheckBox {
                id: nachMordent
                checked: false
                text: qsTr("Nachschlag-Mordent")
            }
            
            CheckBox {
                id: cb_baroque
                checked: true
                text: qsTr("Barock")
            }
        }
        
        // Row 5

        Label {
            text:  "Schläge"
        }
        TextField {
            id: beatsField
            implicitHeight: 24
            Layout.columnSpan:2
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
            Layout.columnSpan:2
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
        Label {
            text: qsTr("Expansion:")
            Layout.columnSpan:2
        }
        Canvas {
            id: canvas
            Layout.rowSpan: 4
            Layout.minimumWidth: 102
            Layout.minimumHeight: 102
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                var w = canvas.width;
                var h = canvas.height;
                var ctx = getContext("2d");

                //square plot area
                var length = (w > h) ? h : w;
                var top = (h - length) / 2;
                var left = (w - length) / 2;
                ctx.clearRect(0, 0, w, h);
                ctx.fillStyle = '#555555';
                ctx.fillRect(left, top, length, length);
                ctx.strokeStyle = '#000000';
                ctx.lineWidth = 1;
                ctx.strokeRect(left, top, length, length);

                //grid lines
                ctx.strokeStyle = '#888888';
                ctx.beginPath();
                var divisions = 4;
                for (var i = divisions - 1; i > 0; --i) {
                    //vertical
                    ctx.moveTo(left + ((i*length)/divisions), top);
                    ctx.lineTo(left + ((i*length)/divisions), top+length);
                    //horizontal
                    ctx.moveTo(left         , top + ((i*length)/divisions));
                    ctx.lineTo(left + length, top + ((i*length)/divisions));
                }
                ctx.stroke();

                //graph
                ctx.strokeStyle = '#abd3fb';
                ctx.lineWidth = 2;
                var start = 0; //= getFloatFromInput(startExpValue);
                var end = 100;
                var midPoint = ((curveType.isLinear) ? 50.0 : midpointSlider.value) / 100;
                ctx.beginPath();
                ctx.moveTo(left + length, (start > end) ? top + length : top);
                for (var x = length; x >= 0; --x) {
                    var outputPct = Math.pow((x / length), (Math.log(0.5) / Math.log(midPoint)));
                    var newY = (start > end) ? (top + (outputPct * length)) : (top + length - (outputPct * length));
                    ctx.lineTo(left + x, newY);
                }
                ctx.stroke();

                //write BPMs
                //                      canvasStartExp.text = start;
                //                      canvasStartExp.topPadding = (start > end) ? (top + 2) : (top + length - canvasStartExp.contentHeight - 2);
//                canvasEndExp.text = end;
//                canvasEndExp.topPadding = (start > end) ? (top + length - canvasEndExp.contentHeight - 2): (top + 2);
                //keep them inside the grid or is there enough room next to it?
                //var longestBPMText = Math.max(canvasStartExp.contentWidth, canvasEndExp.contentWidth);
                //                      if ((longestBPMText + 2 + 2) < left) {
                //                            //outside
                //                            //canvasStartExp.leftPadding = left - 2 - canvasStartExp.contentWidth;
                //                            canvasEndExp.leftPadding = left - 2 - canvasEndExp.contentWidth;
                //                      }
                //                      else {
                //                            //inside
                //                            //canvasStartExp.leftPadding = left + 2;
                //                            canvasEndExp.leftPadding = left + 2;
                //                      }
            }
            //                Label {
            //                      id: canvasStartExp
            //                      color: '#d8d8d8'
            //                }
//            Label {
//                id: canvasEndExp
//                color: '#d8d8d8'
//            }
        } //end of Canvas

        //          Label {
        //                text: qsTr("Start expansion:")
        //          }
        //          TextField {
        //                id: startExpValue
        //                placeholderText: '50'
        //                validator: DoubleValidator { bottom: 1;/* top: 512;*/ decimals: 1; notation: DoubleValidator.StandardNotation; }
        //                implicitHeight: 24
        //                onTextChanged: { canvas.requestPaint(); }
        //          }

//        Label {
//            text: qsTr("End expansion:")
//            Layout.rowSpan: 3
//        }
//        TextField {
//            id: endExpValue
//            placeholderText: '50'
//            validator: DoubleValidator { bottom: 1;/* top: 512;*/ decimals: 1; notation: DoubleValidator.StandardNotation; }
//            implicitHeight: 24
//            Layout.rowSpan: 3
//            onTextChanged: { canvas.requestPaint(); }
//        }
        ComboBox {
            id: curveType
            model: ListModel {
                ListElement { text: qsTr("Linear") }
                ListElement { text: qsTr("Curved") }
            }
            Layout.preferredWidth: 100
            Layout.columnSpan:2

            property bool isLinear: {
                return (curveType.currentText === qsTr("Linear"));
            }

            onCurrentIndexChanged: {
                canvas.requestPaint();
            }
        }
        Label {
            text: qsTr("midpoint:")
            Layout.alignment: Qt.AlignRight
        }
        Slider {
            id: midpointSlider
            Layout.fillWidth: true

            minimumValue: 1
            maximumValue: 99
            value: 75.0
            stepSize: 0.1

            enabled: !curveType.isLinear

            style: SliderStyle {
                groove: Rectangle { //background
                    id: grooveRect
                    implicitHeight: 6
                    color: (enabled) ? '#555555' : '#565656'
                    radius: implicitHeight
                    border {
                        color: '#888888'
                        width: 1
                    }

                    Rectangle {
                        //value fill
                        implicitHeight: grooveRect.implicitHeight
                        implicitWidth: styleData.handlePosition
                        color: (enabled) ? '#abd3fb' : '#567186'
                        radius: grooveRect.radius
                        border {
                            color: '#888888'
                            width: 1
                        }
                    }
                }
                handle: Rectangle {
                    anchors.centerIn: parent
                    color: (enabled) ? (control.pressed ? '#ffffff': '#d8d8d8') : '#565656'
                    border.color: '#666666'
                    border.width: 1
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            SpinBox {
                id: sliderValue
                Layout.preferredWidth: 60

                minimumValue: midpointSlider.minimumValue
                maximumValue: midpointSlider.maximumValue
                value: midpointSlider.value
                decimals: 1
                stepSize: midpointSlider.stepSize

                onValueChanged: {
                    midpointSlider.value = value;
                    canvas.requestPaint();
                }

                enabled: !curveType.isLinear
            }
            Label { text: '%' }
        }

        // Row 8

        Button {
            id: applyButton
            Layout.columnSpan:2
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


    } // End of GridLayout

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

    Keys.onEscapePressed: {
          dlg.parent.Window.window.close();
    }
    Keys.onReturnPressed: {
          maybe_finish();
          dlg.parent.Window.window.close();
    }
    Keys.onEnterPressed: {
          maybe_finish();
          dlg.parent.Window.window.close();
    }
}
