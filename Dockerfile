FROM ruby:2.4.0
MAINTAINER labs-sydney

RUN apt-get update && apt-get install -y postgresql

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g bower
RUN npm install -g gulp

USER postgres 
RUN /etc/init.d/postgresql start && createuser --superuser root
USER root

RUN apt-get update -y && \
  apt-get install -y xvfb
RUN apt-get update -y && \
  apt-get install -y unzip qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x

# Install Chrome WebDriver
RUN CHROMEDRIVER_VERSION='2.27' && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list

RUN apt-get -yqq update && \
    apt-get -yqq install google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Disable the SUID sandbox so that Chrome can launch without being in a privileged container.
# One unfortunate side effect is that `google-chrome --help` will no longer work.
RUN dpkg-divert --add --rename --divert /opt/google/chrome/google-chrome.real /opt/google/chrome/google-chrome && \
    echo "#!/bin/bash\nexec /opt/google/chrome/google-chrome.real --disable-setuid-sandbox \"\$@\"" > /opt/google/chrome/google-chrome && \
    chmod 755 /opt/google/chrome/google-chrome

# Default configuration
ENV DISPLAY :20.0
ENV SCREEN_GEOMETRY "1440x900x24"
ENV CHROMEDRIVER_PORT 4444
ENV CHROMEDRIVER_WHITELISTED_IPS "127.0.0.1"

# Adds ability to run xvfb in daemonized mode
ADD xvfb_init /etc/init.d/xvfb
RUN chmod a+x /etc/init.d/xvfb
ADD daemon-run /usr/bin/daemon-run
RUN chmod a+x /usr/bin/daemon-run

COPY check /opt/resource/check
COPY in /opt/resource/in
COPY out /opt/resource/out

RUN apt-get update && apt-get install -y openjdk-7-jdk

ENTRYPOINT ["/usr/bin/daemon-run"]
