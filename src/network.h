#ifndef NETWORK_H
#define NETWORK_H

#include <QObject>
#include <QDebug>
#include <QString>
#include <QThread>

#include "tcpsocket.h"

class Network : public QObject
{
    Q_OBJECT
public:
    explicit Network(QObject *parent = nullptr);

signals:
    void vpnStatusChanged(int _id, int new_state, QString msg = "");
    void sslWarning(QString msg = "");

public slots:
    void connectVPN(int id, QString src, int port, QString username, QString password, QString ca);
    void setIgnoreWarn();
    void disconnectVPN(bool force = false);

private:
    QThread *connection = NULL;
    TcpSocket *socket = NULL;
    int conn_id;
};

#endif // NETWORK_H
