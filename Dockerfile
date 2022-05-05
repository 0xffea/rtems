FROM ubuntu:22.04 AS builder

RUN apt update \
  && apt install -y build-essential python-is-python3 g++ gdb unzip \
                    pax bison flex texinfo python3-dev libpython2-dev libncurses5-dev \
                    zlib1g-dev git

WORKDIR /usr/local/src

COPY . .

WORKDIR  /usr/local/src/rtems-source-builder/rtems
RUN ../source-builder/sb-set-builder --prefix=/usr/local/rtems/i386 6/rtems-i386 \
  && ../source-builder/sb-set-builder --prefix=/usr/local/rtems/lm32 6/rtems-lm32

WORKDIR /usr/local/src/rtems

RUN echo "[i386/pc386]\nRTEMS_POSIX_API=true" > config.ini
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  && ./waf configure --prefix=/usr/local/rtems/i386 \
  && ./waf install \
  && cp /usr/local/src/rtems/waf /usr/local/bin

RUN echo "[lm32/milkymist]\nRTEMS_POSIX_API=true" > config.ini
RUN PATH=/usr/local/rtems/lm32/bin:$PATH \
  && ./waf configure --prefix=/usr/local/rtems/lm32 \
  && ./waf install

WORKDIR /usr/local/src/rtems-libbsd
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  && ./waf configure --prefix=/usr/local/rtems/i386 --rtems-tools=/usr/local/rtems/i386 --rtems-bsps=i386/pc386 --rtems-version=6 \
  && ./waf install

FROM ubuntu:22.04

RUN apt update \
  && apt install -y python-is-python3

COPY --from=builder /usr/local/rtems/i386 /usr/local/rtems/i386
COPY --from=builder /usr/local/rtems/lm32 /usr/local/rtems/lm32
