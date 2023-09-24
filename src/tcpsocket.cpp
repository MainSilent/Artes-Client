#include "tcpsocket.h"

TcpSocket::TcpSocket(QObject *parent) : Tun(parent){}

TcpSocket::~TcpSocket() {
    reader->terminate();
}

void TcpSocket::init(QString src, int port, QString ca)
{
    socket = new QSslSocket(this);

    if (ca != "") {
        const QSslCertificate _ca(ca.toUtf8());
        socket->addCaCertificate(_ca);
    }

    connect(socket, SIGNAL(encrypted()), this, SLOT(ready()));
    connect(socket, SIGNAL(sslErrors(QList<QSslError>)), this, SLOT(sslErrors(QList<QSslError>)));
    connect(socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(error(QAbstractSocket::SocketError)));
//    connect(socket, SIGNAL(bytesWritten(qint64)), this, SLOT(bytesWritten(qint64)));
    connect(socket, SIGNAL(readyRead()), this, SLOT(readyRead()));
    connect(socket, SIGNAL(disconnected()), this, SLOT(disconnected()));

    qDebug() << "connecting...";

    socket->connectToHostEncrypted(src, port);
}

void TcpSocket::ready()
{
    qDebug() << "Connected";
}

void TcpSocket::sslErrors(QList<QSslError> errors)
{
    ignoreWarn = false;

    qDebug() << errors.first();

    sslWarning(errors.first().errorString());

    while (!ignoreWarn) {}

    socket->ignoreSslErrors();
}

void TcpSocket::error(QAbstractSocket::SocketError error) {
    qDebug() << socket->errorString();

    stateChanged(-1, socket->errorString());
}

void TcpSocket::disconnected()
{
    qDebug() << "disconnected...";

    stateChanged(0);
}

void TcpSocket::bytesWritten(qint64 bytes)
{
    qDebug() << bytes << " bytes written...";
}

void TcpSocket::readyRead()
{
//    qDebug() << "reading...";

// take care of `needAuth = packet[0];` condition if not started

    QByteArray packet = socket->readAll();

    if (needAuth == -1) {
        needAuth = packet[0];

        if (needAuth == 1) {
            socket->write(username + '\0' + password);
            qDebug() << "Auth Needed";
        }
        else {
            stateChanged(2);
            startTunListener(getIP(packet));

            started = true;
        }
    }
    else if (needAuth == 1) {
        needAuth = packet[0];

        switch (needAuth) {
            case 100:
                qDebug() << "Access Granted";
                stateChanged(2);
                startTunListener(getIP(packet));
                break;
            case 99:
                socket->close();
                stateChanged(-1, "Authentication Failed");
                qDebug() << "Auth Failed";
                break;
            case 98:
                socket->close();
                stateChanged(-1, "User is disable");
                qDebug() << "User is disable";
                break;
            case 97:
                socket->close();
                stateChanged(-1, "Max Connection Reached");
                qDebug() << "Max Connection Reached";
                break;
        }

        started = true;
    }
    // Write the packets to tun interface
    else {
        tun_write((char*)packet.data(), packet.length());
    }
}

void TcpSocket::startTunListener(QVector<int> ip) {
    if (tun_open() != 0 or tun_up(ip) != 0) {
        qDebug() << "Failed to open tun interface";
        stateChanged(-2, "Unable to create artes tun interface");
        return;
    }

// You need to delete the macro
#if !IS_MOBILE
    reader = QThread::create([&]{
        unsigned long size;

        while (true) {
            tun_read(&size);

            if (size > 0)
                socket->write(tun_packet, size);
        }
    });
    reader->start();
#endif
}

QVector<int> TcpSocket::getIP(QByteArray packet) {
    QVector<int> ip;
    ip.resize(4);
    ip[0] = mod(packet[1], 256);
    ip[1] = mod(packet[2], 256);
    ip[2] = mod(packet[3], 256);
    ip[3] = mod(packet[4], 256);

    return ip;
}
