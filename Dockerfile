FROM ubuntu:22.04 AS builder

RUN apt update \
  && apt install -y build-essential python-is-python3 g++ gdb unzip \
                    pax bison flex texinfo python3-dev libpython2-dev libncurses5-dev \
                    zlib1g-dev git cmake

WORKDIR /usr/local/src

COPY . .

#
# gdb fails to build for microblaze
#
WORKDIR  /usr/local/src/rtems-source-builder/rtems
RUN ../source-builder/sb-set-builder --prefix=/usr/local/rtems/i386 6/rtems-i386 \
#  && ../source-builder/sb-set-builder --prefix=/usr/local/rtems/lm32 6/rtems-lm32 \
  && ../source-builder/sb-set-builder --prefix=/usr/local/rtems/riscv 6/rtems-riscv

WORKDIR /usr/local/src/rtems

RUN echo "[i386/pc686]\nRTEMS_POSIX_API=True\nBUILD_TESTS=True\nRTEMS_DEBUG=True" > config.ini
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  ./waf configure --prefix=/usr/local/rtems/i386 \
  && ./waf bsp_defaults --rtems-bsps=i386/pc686 \
  && ./waf install \
  && cp /usr/local/src/rtems/waf /usr/local/bin

#RUN echo "[lm32/milkymist]\nRTEMS_POSIX_API=true" > config.ini
#RUN PATH=/usr/local/rtems/lm32/bin:$PATH \
#  ./waf configure --prefix=/usr/local/rtems/lm32 \
#  && ./waf install

RUN echo "[riscv/rv32imafc]\nRTEMS_POSIX_API=True\nBUILD_TESTS=True\nRTEMS_DEBUG=True" > config.ini
RUN PATH=/usr/local/rtems/riscv/bin:$PATH \
  ./waf configure --prefix=/usr/local/rtems/riscv \
  && ./waf install

WORKDIR /usr/local/src/rtems-libbsd
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  ./waf configure --prefix=/usr/local/rtems/i386 --rtems-tools=/usr/local/rtems/i386 --rtems-bsps=i386/pc386 --rtems-version=6 \
  && ./waf install

#
# internal gcc compiler error
#
#RUN PATH=/usr/local/rtems/lm32/bin:$PATH \
#  && ./waf configure --prefix=/usr/local/rtems/lm32 --rtems-tools=/usr/local/rtems/lm32 --rtems-bsps=lm32/milkymist --rtems-version=6 \
#  && ./waf install

WORKDIR /usr/local/src/SOEM
RUN PATH=/usr/local/rtems/i386/bin:$PATH \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_SYSTEM_NAME=rtems -DRTEMS_TOOLS_PATH=/usr/local/rtems/i386 \
           -DHOST=i386-rtems6 -DCMAKE_INSTALL_PREFIX=/usr/local/rtems/i386 \
           -DCMAKE_C_COMPILER=/usr/local/rtems/i386/bin/i386-rtems6-gcc .. \
  && make VERBOSE=1 install

FROM ubuntu:22.04

RUN apt update \
  && apt install -y python-is-python3

COPY --from=builder /usr/local/rtems/i386 /usr/local/rtems/i386
COPY --from=builder /usr/local/rtems/lm32 /usr/local/rtems/lm32
