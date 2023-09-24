#ifndef LOG_H
#define LOG_H

#include <QByteArray>
#include <QString>

const QString QT_ENV = qgetenv("QT_ENV");

void log(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if (QT_ENV != "debug")
        return;

    QByteArray localMsg = msg.toLocal8Bit();
    switch (type) {
    case QtDebugMsg:
        fprintf(stderr, "Debug: %s\n", localMsg.constData());
        break;
    case QtInfoMsg:
        fprintf(stderr, "Info: %s\n", localMsg.constData());
        break;
    case QtWarningMsg:
        fprintf(stderr, "Warning: %s\n", localMsg.constData());
        break;
    case QtCriticalMsg:
        fprintf(stderr, "Critical: %s\n", localMsg.constData());
        break;
    case QtFatalMsg:
        fprintf(stderr, "Fatal: %s\n", localMsg.constData());
        abort();
    }
}

#endif