#ifndef TCPSOCKET_H
#define TCPSOCKET_H

#include <QObject>
#include <QSslSocket>
#include <QAbstractSocket>
#include <QThread>
#include <QDebug>
#include "tun.h"

class TcpSocket : public Tun
{
    Q_OBJECT
public:
    explicit TcpSocket(QObject *parent = 0);
    ~TcpSocket();

    void init(QString src, int port, QString ca);

    QByteArray username;
    QByteArray password;
    bool started = false;
    bool ignoreWarn = true;

signals:
    void stateChanged(int state, QString mag = "");
    void sslWarning(QString mag = "");

public slots:
    void ready();
    void sslErrors(QList<QSslError> errors);
    void error(QAbstractSocket::SocketError socketError);
    void disconnected();
    void bytesWritten(qint64 bytes);
    void readyRead();

private:
    QSslSocket *socket;
    QThread *reader;
    int needAuth = -1; // -1 Uninitialized, 0 NoAuth, 1 AuthRequired, 100 Authorized

    void startTunListener(QVector<int> ip);
    QVector<int> getIP(QByteArray packet);
};

#endif // TCPSOCKET_H
