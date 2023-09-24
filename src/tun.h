#ifndef TUN_H
#define TUN_H

#include <QObject>
#include <QVector>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <fcntl.h>
#include <ctype.h>

#define IS_OSX __APPLE__ && __MACH__
#define IS_LINUX __linux__ && !__ANDROID__
#define IS_WINDOWS _WIN64 || _WIN32
#define IS_UNIX (IS_OSX) || (IS_LINUX)
#define IS_ANDROID __ANDROID__
#define IS_MOBILE IS_ANDROID

#if IS_LINUX
#include <linux/if.h>
#include <linux/if_tun.h>
#endif

#if IS_OSX
#include <sys/kern_event.h>
#include <sys/socket.h>
#include <sys/kern_control.h>

#define UTUN_CONTROL_NAME "com.apple.net.utun_control"
#define UTUN_OPT_IFNAME 2
#endif

#if IS_UNIX
#include <sys/ioctl.h>
#endif

#if IS_WINDOWS
#include "wintun/driver.h"
#endif

#if IS_ANDROID
#include <QAndroidJniObject>
#endif

#define BUFFER_SIZE 65535

class Tun : public QObject
{
    Q_OBJECT
public:
    explicit Tun(QObject *parent = nullptr);
    ~Tun();
    int tun_open();
    void tun_read(unsigned long *size);
    void tun_write(char *packet, int size);
    int tun_up(QVector<int> ip);
    void tun_down();

    int tun_fd;
    char ifname[16] = "artes";
    char tun_packet[BUFFER_SIZE];

    int mod(int dividend, int divisor) {
      if (dividend == 0) return 0;

      if ((dividend > 0) == (divisor > 0))
        return dividend % divisor;
      else
        return (dividend % divisor) + divisor;
    }

private:

#if IS_WINDOWS
    WINTUN_ADAPTER_HANDLE adapter = NULL;
    WINTUN_SESSION_HANDLE session = NULL;
    EVENT read_event = NULL;
#endif
};

#endif // TUN_H
