#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "network.h"
#include "log.h"

int main(int argc, char *argv[])
{
#if IS_UNIX
    QCoreApplication::setSetuidAllowed(true);
    setuid(0);
#endif

#if IS_WINDOWS
    initialize_wintun();
#endif

#if !IS_MOBILE
    qInstallMessageHandler(log);
#endif

    QQuickStyle::setStyle("Imagine");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    Network *network = new Network();
    engine.rootContext()->setContextProperty("network", network);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
