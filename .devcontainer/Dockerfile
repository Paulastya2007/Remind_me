FROM dart

RUN apt-get update
RUN apt-get install -y curl git unzip xz-utils zip libglu1-mesa

RUN apt-get clean

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
RUN apt-get update -yqq && \
apt-get install -y \
curl \
expect \
git \
make \
wget \
unzip \
vim \
openssh-client \
locales \
libarchive-tools && \
apt-get clean && rm -rf /var/lib/apt/lists/* && \
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV ANDROID_SDK_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_ROOT /opt/android-sdk-linux
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK /opt/android-sdk-linux
ENV PATH="/flutter/bin:$PATH"
RUN flutter doctor
