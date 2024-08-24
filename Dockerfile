FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "Europe/Copenhagen"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password


LABEL org.opencontainers.image.description="CUPS Printer Server"


# Install dependencies


RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install -qqy \
    apt-utils \
    usbutils \
    cups \
    cups-filters \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    avahi-daemon \
    gnupg \
    inotify-tools \
    python3-cups \
    rsync \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN bash -c 'echo "deb https://www.bchemnet.com/suldr/ debian extra" >> /etc/apt/sources.list'
RUN wget https://www.bchemnet.com/suldr/pool/debian/extra/su/suldr-keyring_2_all.deb
RUN dpkg -i suldr-keyring_2_all.deb
RUN apt update -qq && apt install -qqy suld-driver2-1.00.39 && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 631
EXPOSE 5353/udp

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/IdleExitTimeout/#IdleExitTimeout/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf


# back up cups configs in case used does not add their own
#RUN cp -rp /etc/cups /etc/cups-bak
#VOLUME [ "/etc/cups" ]

#COPY entrypoint.sh /
#RUN chmod +x /entrypoint.sh

#CMD ["/entrypoint.sh"]
