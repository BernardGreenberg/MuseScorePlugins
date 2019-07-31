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
import QtQuick.Dialogs 1.1

MuseScore {
      version:  "3.0"
      description: qsTr("This plugin colors the selected note(s) red.")
      menuPath: "Plugins.Notes.Red Note"

      property string red   : "#ff0000"

      function colorNote(note) {
	  note.color = red;

          if (note.accidental) {
              note.accidental.color = red;
	  }
          for (var i = 0; i < note.dots.length; i++) {
              if (note.dots[i]) {
		  note.dots[i].color = red;
              }
          }
      }

      onRun: {
        console.log("hello red notes");
        if ((mscoreMajorVersion < 3) || (mscoreMinorVersion < 3)) {
           versionError.open()
           Qt.quit();
	   return;
        }

        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length > 0) {  // We have a selection list to work with...
            console.log(elements.length, "selections")
            for (var idx = 0; idx < elements.length; idx++) {
                var element = elements[idx]
                //console.log("element.type=" + element.type)
                if (element.type == Element.NOTE) {
                    console.log("We found a note! Paint it red!.")
                    colorNote(element);
                }
            }
        }
        Qt.quit();
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
