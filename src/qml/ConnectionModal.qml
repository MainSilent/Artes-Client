import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

Item {
    property bool show: false
    property int editID: -1
    property int port: 443
    property string src: ""
    property string username: ""
    property string password: ""
    property string ca: ""
    signal connectionFormSignal(int editID, string src, int port, string username, string password, string ca)
    signal setValue(var data)
    signal reset

    anchors.fill: parent
    visible: show

    Rectangle {
        id: connModalView
        width: parent.width < 500 ? parent.width - 25 : 450
        height: parent.height < 490 ? parent.height - 100 : 390
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#2C3333"
        radius: 10
        z: 1

        ScrollView {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: parent.width

                ConnectionInput {
                    field: "src"
                    title: "Domain or IP"
                    Layout.topMargin: 20
                    Layout.leftMargin: 20
                    onValueChanged: src = value
                }

                ConnectionInput {
                    field: "port"
                    title: "Port"
                    inputWidth: 90
                    placeholder: "443"
                    setInputMethodHints: Qt.ImhDigitsOnly
                    setValidator: IntValidator { bottom: 1; top: 99999 }
                    Layout.leftMargin: 20
                    onValueChanged: port = !value ? 443 : value
                }

                ConnectionInput {
                    field: "username"
                    title: "Username (Optional)"
                    Layout.leftMargin: 20
                    onValueChanged: username = value
                }

                ConnectionInput {
                    field: "password"
                    title: "Password (Optional)"
                    setEchoMode: TextInput.Password
                    Layout.leftMargin: 20
                    onValueChanged: password = value
                }

                ConnectionInput {
                    field: "ca"
                    title: "CA (Optional)"
                    Layout.leftMargin: 20
                    onValueChanged: ca = value
                }

                Button {
                    text: editID !== -1 ? "Update" : "Save"
                    onClicked: {
                        connectionFormSignal(editID, src, port, username, password, ca)
                        editID = -1
                        src = ""
                        port = 443
                        username = ""
                        password = ""
                        ca = ""
                    }
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    Layout.leftMargin: 20
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#80000000"
    }
}
