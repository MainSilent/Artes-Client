#include "tun.h"

Tun::Tun(QObject *parent) : QObject(parent){}

Tun::~Tun() {
    tun_down();
}

int Tun::tun_open()
{
#if IS_UNIX
    tun_down();
#endif

#if IS_WINDOWS
    if (open_adapter("artes", &adapter) != 0)
        if (create_adapter("artes", "Wintun", &adapter) != 0)
            return -1;

    if (start_session(adapter,0x400000, &session) != 0)
        return 0;

    read_event = get_read_wait_event(session);

    return 0;
#endif

#if IS_LINUX
    struct ifreq ifr;

    if ((tun_fd = open("/dev/net/tun", O_RDWR)) == -1) {
        perror("Can't open tun file");
        return -1;
    }

    memset(&ifr, 0, sizeof(ifr));
    ifr.ifr_flags = (IFF_TUN | IFF_NO_PI);
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ);

    if (ioctl(tun_fd, TUNSETIFF, (void *) &ifr) == -1) {
        printf("Can't set tun type");
        close(tun_fd);
        return -1;
    }
#endif

#if IS_OSX
    struct sockaddr_ctl addr;
    struct ctl_info info;
    memset(ifname, 0, sizeof(ifname));
    socklen_t ifname_len = sizeof(ifname);
    int err = 0;

    tun_fd = socket (PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
    if (tun_fd < 0) return tun_fd;

    bzero(&info, sizeof (info));
    strncpy(info.ctl_name, UTUN_CONTROL_NAME, MAX_KCTL_NAME);

    err = ioctl(tun_fd, CTLIOCGINFO, &info);
    if (err != 0) goto on_error;

    addr.sc_len = sizeof(addr);
    addr.sc_family = AF_SYSTEM;
    addr.ss_sysaddr = AF_SYS_CONTROL;
    addr.sc_id = info.ctl_id;
    addr.sc_unit = 0;

    err = ::connect(tun_fd, (struct sockaddr *)&addr, sizeof (addr));
    if (err != 0) goto on_error;

    err = getsockopt(tun_fd, SYSPROTO_CONTROL, UTUN_OPT_IFNAME, ifname, &ifname_len);
    if (err != 0) goto on_error;

    err = fcntl(tun_fd, F_SETFL, O_NONBLOCK);
    if (err != 0) goto on_error;

    fcntl(tun_fd, F_SETFD, FD_CLOEXEC);
    if (err != 0) goto on_error;

  on_error:
    if (err != 0) {
      close(tun_fd);
      perror("Can't open tun file");
      return -1;
    }
#endif

    return 0;
}

void Tun::tun_read(unsigned long *size)
{
#if IS_WINDOWS
    read_packet(session, read_event, (unsigned char*)tun_packet, size);
#endif

#if IS_UNIX
    *size = read(tun_fd, tun_packet, sizeof(tun_packet));
#endif
}

void Tun::tun_write(char *packet, int size)
{
#if IS_WINDOWS
    write_packet(session, (unsigned char*)packet, size);
#endif

#if IS_UNIX
    write(tun_fd, packet, size);
#endif
}

int Tun::tun_up(QVector<int> ip) {
#if IS_LINUX
    return system(QString(
        "echo 1 > /proc/sys/net/ipv4/ip_forward && " \

        "ip link set %1 up && " \
        "ip addr add %2.%3.%4.%5/16 dev %1 && " \
        "ip route add default dev %1 && " \
        "ip route change default via %2.%3.0.1 dev %1 && " \

        "resolvectl dns %1 %2.%3.0.1 && " \
        "resolvectl domain %1 ~."
    ).arg(ifname)
     .arg(QString::number(ip[0]))
     .arg(QString::number(ip[1]))
     .arg(QString::number(ip[2]))
     .arg(QString::number(ip[3]))
     .toStdString().c_str());
#endif

#if IS_OSX
    return system(QString(
        "ifconfig %1 %2.%3.%4.%5/16 %2.%3.0.1 && " \
        "mkdir -p /etc/resolver && " \
        "echo \"domain *\nnameserver %2.%3.0.1\nsearch_order 1\" > /etc/resolver/artes.dns"
    ).arg(ifname)
     .arg(QString::number(ip[0]))
     .arg(QString::number(ip[1]))
     .arg(QString::number(ip[2]))
     .arg(QString::number(ip[3]))
     .toStdString().c_str());
#endif

    return 0;
}

void Tun::tun_down() {
#if IS_WINDOWS
    if (session != NULL) {
        end_session(session);
        session = NULL;
    }
#endif

#if IS_UNIX
    close(tun_fd);
#endif
}
