import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import QtQuick.LocalStorage 2.12
import QtQuick.Dialogs 1.2

Window {
    property var db
    property bool vpnActive: false
    property bool showInit: false
    property bool showConnectionModal: false

    id: window
    width: 640
    height: 500
    maximumWidth: 1080
    maximumHeight: 720
    minimumWidth: 300
    minimumHeight: 350
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowCloseButtonHint
    visible: true
    title: "Artes"

    Rectangle {
        color: "#2C3333"
        anchors.fill: parent
    }

    // List Connection
    ListModel { id: connModel }

    ConnectionList {
        id: connList
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        _connModel: connModel
    }

    Connections {
        target: connList
        onEdit: {
            connectionModal.editID = id
            connectionModal.src = src
            connectionModal.port = port
            connectionModal.username = username
            connectionModal.password = password
            connectionModal.ca = ca

            connectionModal.setValue({
                'id': id,
                'src': src,
                'port': port,
                'username': username,
                'password': password,
                'ca': ca
            })

            showConnectionModal = !showConnectionModal
        }
        onRemove: {
            removeDB(id)
            refreshConnectionsList()
        }
     }

    // Add Connection
    Text {
        text: "Click on + to add a connection"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 17
        color: "#afffffff"
        visible: !showConnectionModal && showInit
    }

    ConnectionModal {
        id: connectionModal
        show: showConnectionModal
    }

    Rectangle {
        id: addButton
        width: 40
        height: 40
        radius: 360
        color: showConnectionModal ? "#cc0000" : "#00b33c"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 15

        Text {
            id: addButtonText
            text: showConnectionModal ? "-" : "+"
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 30
        }

        MouseArea
        {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                showConnectionModal = !showConnectionModal

                connectionModal.editID = -1
                connectionModal.reset()
            }
        }
    }

    DropShadow {
        anchors.fill: source
        cached: true
        horizontalOffset: 3
        verticalOffset: 3
        radius: 8.0
        samples: 16
        color: "#80000000"
        source: addButton
    }

    MessageDialog {
        id: errorDialog
        icon: StandardIcon.Critical
        title: "Error"
    }

    MessageDialog {
        id: disconnectDialog
        icon: StandardIcon.Warning
        title: "Disconnect?"
        text: "Are you sure?"
        standardButtons: StandardButton.No | StandardButton.Yes
        onYes: network.disconnectVPN(true)
    }

    MessageDialog {
        id: sslDialog
        icon: StandardIcon.Warning
        title: "SSL WARNING"
        text: ""
        standardButtons: StandardButton.Abort | StandardButton.Ignore
        onAccepted: network.setIgnoreWarn()
        onRejected: network.disconnectVPN(true)
    }


    // Database
    Connections {
        target: connectionModal
        onConnectionFormSignal: {
            if (src == "") {
                errorDialog.text = "Domain or IP can't be empty"
                errorDialog.visible = true
                return
            }
            if (!port) port = 443

            if (connectionModal.editID === -1)
                createDB(src, port, username, password, ca)
            else
                editDB(editID, src, port, username, password, ca)

            refreshConnectionsList()
            showConnectionModal = false

            connectionModal.editID = -1
            connectionModal.reset()
        }
     }


    function initDB() {
        db = LocalStorage.openDatabaseSync("connections", "1.0", "Store Database Data", 16000000);

        try {
            db.transaction(function (tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS conn (id INTEGER PRIMARY KEY, src text, port numeric, username text, password text, ca text)')
            });

            return true
        } catch (err) {
            errorDialog.text = "Error creating table in database: " + err
            errorDialog.visible = true

            return false
        }
    }

    function createDB(src, port, username, password, ca) {
        try {
            var result

            db.transaction(function (tx) {
                result = tx.executeSql(
                            "INSERT INTO conn VALUES(?, ?, ?, ?, ?, ?)",
                            [ null, src, port, username, password, ca ]
                        );
            });

             showInit = false

            return result
        } catch (err) {
            errorDialog.text = "Error creating record in table conn: " + err
            errorDialog.visible = true

            return false
        }
    }

    function editDB(id, src, port, username, password, ca) {
        try {
            var result

            db.transaction(function (tx) {
                result = tx.executeSql("
                    UPDATE conn
                    SET src = ?,
                        port = ?,
                        username = ?,
                        password = ?,
                        ca = ?
                    WHERE
                        id = ?
                    ",
                    [ src, port, username, password, ca, id ]
                );
            });

            return result
        } catch (err) {
            errorDialog.text = "Error updating record in table conn: " + err
            errorDialog.visible = true

            return false
        }
    }

    function removeDB(id) {
        try {
            db.transaction(function (tx) {
                tx.executeSql("DELETE FROM conn WHERE id = ?", [ id ]);
            });

            return true
        } catch (err) {
            errorDialog.text = "Error delete record from table conn: " + err
            errorDialog.visible = true

            return false
        }
    }

    function refreshConnectionsList() {
        db.transaction(function (tx) {
            var results = tx.executeSql('SELECT id, src, port, username, password, ca FROM conn order by id desc')

            connModel.clear()

            for (var i = 0; i < results.rows.length; i++) {
                connModel.append({
                    id: results.rows.item(i).id,
                    src: results.rows.item(i).src,
                    port: results.rows.item(i).port,
                    username: !results.rows.item(i).username ? "" : results.rows.item(i).username,
                    password: !results.rows.item(i).password ? "" : results.rows.item(i).password,
                    ca: !results.rows.item(i).ca ? "" : results.rows.item(i).ca
                })
            }

            if (results.rows.length === 0)
                showInit = true
        })
    }


    Component.onCompleted: {
        if (initDB())
            refreshConnectionsList()
    }
}
