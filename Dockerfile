FROM aadl/cups:latest

MAINTAINER jakbutler

#########################################
##        ENVIRONMENTAL CONFIG         ##
#########################################
ENV DRIVER_URL='http://gdlp01.c-wss.com/gds/6/0100009236/01/linux-UFRII-drv-v350-usen.tar.gz'
ENV AIRPRINT_GENERATE_URL='https://raw.github.com/tjfontaine/airprint-generate/master/airprint-generate.py'
# ENV CUPS_USER_ADMIN=admin
# ENV CUPS_USER_PASSWORD=secr3t

#########################################
##         DEPENDENCY INSTALL          ##
#########################################
# Base AADL image installs cups (2.2.1), cups-filters, cups-pdf, and whois
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get -y install \
    autoconf \
    automake \
    curl \
	#gcc-libs \
    #libgcc1 \
    inotify-tools \
    libglade2-0 \
    libpango1.0-0 \
    libpng16-16 \
    #libxml2 \
	python-cups \
 && rm -rf /var/lib/apt/lists/*

# TODO: Install golang and google-cloud-print

#########################################
##             CUPS Config             ##
#########################################
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf


#########################################
##            Script Setup             ##
#########################################
RUN rm /root/start_cups.sh
COPY start-cups.sh /root/start-cups.sh
RUN chmod +x /root/start-cups.sh
COPY printer-update.sh /root/printer-update.sh
RUN chmod +x /root/printer-update.sh

## Install and configure AirPrint
RUN curl $AIRPRINT_GENERATE_URL -o /root/airprint-generate.py
RUN chmod +x /root/airprint-generate.py

## Add proper mimetypes for iOS
COPY mime/airprint.convs /share/cups/mime/airprint.convs
COPY mime/airprint.types /share/cups/mime/airprint.types

## Install Canon URFII drivers
# RUN touch /var/lib/dpkg/status
 #&& cp /var/lib/dpkg/available-old /var/lib/dpkg/available
RUN curl $DRIVER_URL | tar xz
RUN dpkg -i *-UFRII-*/64-bit_Driver/Debian/*common*.deb
RUN dpkg -i *-UFRII-*/64-bit_Driver/Debian/*ufr2*.deb
RUN dpkg -i *-UFRII-*/64-bit_Driver/Debian/*utility*.deb
RUN rm -rf *-UFRII-*

#########################################
##         EXPORTS AND VOLUMES         ##
#########################################
VOLUME /etc/cups/ \
       /etc/avahi/services/ \
       /var/log/cups \
       /var/spool/cups \
       /var/spool/cups-pdf \
       /var/cache/cups
# /var/run/dbus

#########################################
##           Startup Command           ##
#########################################
CMD ["/root/start-cups.sh"]

#########################################
##               PORTS                 ##
#########################################
EXPOSE 631