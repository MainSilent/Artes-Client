import QtQuick 2.0
import QtQuick.Controls 2.12

Item {
    property bool isMenu: true
    property var connState: []
    property var _connModel
    signal edit(int id, string src, int port, string username, string password, string ca)
    signal remove(int id)

    anchors.fill: parent

    Component {
        id: connDelegate

        Rectangle {
            property int _state: !connState[id] ? 0 : connState[id] // -1 FAILED, 0 IDLE, 1 CONNECTING, 2 CONNECTED

            width: parent.width < 600 ? parent.width - 30 : 580
            height: 65
            color: "#8fffffff"
            radius: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                anchors.fill: parent
                anchors.margins: 20

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left

                    Text {
                        text: `${src}:${port}`
                        color: "#e0000000"
                        font.pixelSize: 18
                    }

                    Text {
                        text: !username ? "No Auth" : username
                        color: "#80000000"
                        font.pixelSize: 15
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right

                    Rectangle {
                        width: 70
                        height: 30
                        color: _state === 2 ? "#009933" : _state === 1 ? "#b3b300" : _state === -1 ? "#cc0000" : "gray"
                        radius: 5

                        Text {
                            text: _state === 2 ? "Active" : _state === 1 ? "Wait" : _state === -1 ? "Failed" : "Connect"
                            color: "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onHoveredChanged: isMenu = !isMenu
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (vpnActive)
                                    disconnectDialog.visible = true
                                else
                                    switch (_state) {
                                        case -1:
                                        case 0:
                                           network.connectVPN(id, src, port, username, password, ca)
                                           break;
                                        case 1:
                                        case 2:
                                            disconnectDialog.visible = true
                                    }
                            }
                        }
                    }
                }
            }


            // Menu
            MouseArea {
                visible: isMenu
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    if (mouse.button === Qt.RightButton && (_state === 0 || _state === -1))
                        contextMenu.popup()
                }
                onPressAndHold: {
                    if (mouse.source === Qt.MouseEventNotSynthesized && (_state === 0 || _state === -1))
                        contextMenu.popup()
                }

                Menu {
                    id: contextMenu

                    MenuItem {
                        text: "Edit"
                        onTriggered: edit(id, src, port, username, password, ca)
                    }
                    MenuItem {
                        text: "Remove"
                        onTriggered: remove(id)
                    }
                }
            }


            Connections {
                target: network
                onVpnStatusChanged: {
                    if (_id === id) {
                        _state = new_state
                        connState[id] = new_state

                        if (new_state == -1) {
                            errorDialog.text = msg
                            errorDialog.visible = true
                            vpnActive = false
                        }
                        else if (new_state == 2)
                            vpnActive = true
                        else
                            vpnActive = false
                    }
                }
                onSslWarning: {
                    sslDialog.text = msg
                    sslDialog.visible = true
                }
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: _connModel
        delegate: connDelegate
        spacing: 20

        ScrollBar.vertical: ScrollBar {}
    }
}
