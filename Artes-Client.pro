QT += quick quickcontrols2

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        src/main.cpp \
        src/network.cpp \
        src/tcpsocket.cpp \
        src/tun.cpp

RESOURCES += src/qml/qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
#win32 {
#    WIN_PWD = $$replace(PWD, /, \\)
#    OUT_PWD_WIN = $$replace(OUT_PWD, /, \\)
#    QMAKE_POST_LINK = "mt.exe -manifest $$quote($$WIN_PWD\\artes.manifest) -outputresource:$$quote($$OUT_PWD_WIN\\${DESTDIR_TARGET};1)"

#    SOURCES += src/wintun/driver.cpp

#    HEADERS +=  src/wintun/wintun.h \
#                src/wintun/driver.h
#}

HEADERS += \
    src/log.h \
    src/network.h \
    src/tcpsocket.h \
    src/tun.h

#DISTFILES += \
#    android/src/com/artes/Tunnel.java \
#    android/AndroidManifest.xml \
#    android/build.gradle \
#    android/gradle/wrapper/gradle-wrapper.jar \
#    android/gradle/wrapper/gradle-wrapper.properties \
#    android/gradlew \
#    android/gradlew.bat \
#    android/res/values/libs.xml

#android: QT += androidextras

#contains(ANDROID_TARGET_ARCH,x86) {
#    ANDROID_PACKAGE_SOURCE_DIR = \
#        $$PWD/android
#}
