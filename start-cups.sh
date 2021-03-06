#!/usr/bin/env sh
set -e
set -x

if [ $(grep -ci $CUPS_USER_ADMIN /etc/shadow) -eq 0 ]; then
    useradd $CUPS_USER_ADMIN --system -G root,lpadmin --no-create-home --password $(mkpasswd $CUPS_USER_PASSWORD)
fi

/etc/init.d/dbus start
/etc/init.d/avahi-daemon start
/root/printer-update.sh &
exec /usr/sbin/cupsd -f