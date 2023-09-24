#include "network.h"

Network::Network(QObject *parent) : QObject(parent)
{

}

void Network::connectVPN(int id, QString src, int port, QString username, QString password, QString ca) {
    disconnectVPN();

    conn_id = id;

    vpnStatusChanged(id, 1); // Set to wait

    connection = new QThread();
    socket = new TcpSocket();

    connect(socket, &TcpSocket::stateChanged, [&](int state, QString msg) {
        if (state == -1 || state == -2) {
            disconnectVPN();

            vpnStatusChanged(conn_id, -1, msg);
        }
        else
            vpnStatusChanged(conn_id, state);
    });

    connect(socket, &TcpSocket::sslWarning, [&](QString msg) {
        sslWarning(msg);
    });

    socket->username = username.toUtf8();
    socket->password = password.toUtf8();
    socket->init(src, port, ca);
    socket->moveToThread(connection);
    connection->start();
}

void Network::setIgnoreWarn() {
    socket->ignoreWarn = true;
}

void Network::disconnectVPN(bool force) {
    if (!force)
        if (socket == NULL || connection == NULL || !(connection->isRunning() && socket->started))
            return;

    socket->deleteLater();
    connection->quit();

    socket = NULL;
    connection = NULL;

    vpnStatusChanged(conn_id, 0);

    qDebug() << "disconnected...";
}
