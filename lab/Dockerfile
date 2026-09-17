# Ubuntu 22.04 with a real systemd as PID 1, so journalctl/systemctl work.
# Built locally because the common pre-built systemd images are amd64-only.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

RUN apt-get update && apt-get install -y --no-install-recommends \
        systemd systemd-sysv dbus dbus-user-session \
        nginx \
        passwd adduser sudo perl \
        vim less tree curl wget file ca-certificates openssl \
        iproute2 iputils-ping dnsutils traceroute net-tools \
        netcat-openbsd tcpdump telnet mtr-tiny \
        procps lsof \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# These units are meaningless inside a container and only produce boot noise.
RUN rm -f /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sysinit.target.wants/systemd-udevd.service \
          /lib/systemd/system/multi-user.target.wants/systemd-logind.service \
    ; systemctl mask systemd-udevd.service systemd-udev-trigger.service \
          systemd-firstboot.service systemd-resolved.service 2>/dev/null || true

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
