import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    property string field
    property string title
    property string placeholder
    property int inputWidth: 200
    property var setInputMethodHints
    property var setValidator
    property var setEchoMode: TextInput.Normal
    signal valueChanged(var value)

    width: parent.width
    height: field != "ca" ? 72 : 250

    Column {
        spacing: 5

        Text {
            text: title
            font.pixelSize: 16
            color: "#efffffff"
        }

        TextField {
            id: input
            visible: field != "ca"
            width: inputWidth
            echoMode: setEchoMode
            placeholderText: placeholder

            onTextChanged: valueChanged(text)

            Component.onCompleted: {
                if (typeof setValidator !== "undefined")
                    validator = setValidator
                if (typeof setInputMethodHints !== "undefined")
                    inputMethodHints = setInputMethodHints
            }
        }


        ScrollView {
            height: 200
            width: connModalView.width - 40
            visible: field == "ca"
            clip: true

            TextArea {
                id: inputArea
                placeholderText: qsTr("Recommended for the\nprivacy of self-signed cert")

                onTextChanged: valueChanged(text)
            }
        }
    }

    Connections {
        target: connectionModal
        onReset: { input.text = ""; inputArea.text = "" }
        onSetValue: { input.text = data[field]; inputArea.text = data[field] }
    }
}
