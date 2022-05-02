FROM ubuntu:22.04

RUN apt update \
  && apt install -y build-essential python-is-python3 g++  gdb unzip \
                    pax bison flex texinfo python3-dev libpython2-dev libncurses5-dev \
                    zlib1g-dev git

WORKDIR /usr/local/src

COPY . .

WORKDIR  /usr/local/src/rtems-source-builder/rtems
RUN ../source-builder/sb-set-builder --prefix=/usr/local/rtems/i386 6/rtems-i386

WORKDIR /usr/local/src/rtems

RUN echo "[i386/pc386]\nRTEMS_POSIX_API=true" > config.ini
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  && ./waf configure --prefix=/usr/local/rtems/i386 \
  && ./waf install
