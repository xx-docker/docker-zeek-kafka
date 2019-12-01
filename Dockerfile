FROM alpine:3.10 as builder

LABEL maintainer "Rouzbeh Radparvar"

ENV ZEEK_VERSION 3.0.0

RUN apk add --no-cache zlib openssl libstdc++ libpcap libgcc
RUN apk add --no-cache -t .build-deps \
  libmaxminddb-dev \
  linux-headers \
  openssl-dev \
  libpcap-dev \
  python-dev \
  zlib-dev \
  binutils \
  fts-dev \
  cmake \
  clang \
  bison \
  bash \
  swig \
  perl \
  make \
  flex \
  git \
  g++ \
  fts

RUN echo "===> Cloning zeek..." \
  && cd /tmp \
  && git clone --recursive --branch v$ZEEK_VERSION https://github.com/zeek/zeek.git

RUN echo "===> Compiling zeek..." \
  && cd /tmp/zeek \
  && CC=clang ./configure --prefix=/usr/local/zeek \
  --build-type=MinSizeRel \
  --disable-broker-tests \
  --disable-zeekctl \
  --disable-auxtools \
  --disable-python \
  && make -j 2 \
  && make install

RUN echo "===> Compiling af_packet plugin..." \
  && cd /tmp/zeek/aux/ \
  && git clone https://github.com/J-Gras/bro-af_packet-plugin.git \
  && cd /tmp/zeek/aux/bro-af_packet-plugin \
  && find . -name "*.bro" -exec sh -c 'mv "$1" "${1%.bro}.zeek"' _ {} \; \
  && CC=clang ./configure --with-kernel=/usr --bro-dist=/tmp/zeek \
  && make -j 2 \
  && make install \
  && /usr/local/zeek/bin/zeek -NN Bro::AF_Packet

RUN echo "===> Installing apache/metron-bro-plugin-kafka package..." \
  && cd /tmp/zeek/aux/ \
  && git clone https://github.com/apache/metron-bro-plugin-kafka.git \
  && apk add --no-cache librdkafka-dev \
  && cd /tmp/zeek/aux/metron-bro-plugin-kafka \
  && find . -name "*.bro" -exec sh -c 'mv "$1" "${1%.bro}.zeek"' _ {} \; \
  && CC=clang ./configure --bro-dist=/tmp/zeek \
  && make -j 2 \
  && make install

RUN echo "===> Check if kafka plugin installed..." && /usr/local/zeek/bin/zeek -N Apache::Kafka

RUN echo "===> Shrinking image..." \
  && strip -s /usr/local/zeek/bin/zeek

RUN echo "===> Size of the Zeek install..." \
  && du -sh /usr/local/zeek
####################################################################################################
FROM alpine:3.10

LABEL maintainer "Rouzbeh Radparvar"

RUN apk --no-cache add ca-certificates zlib openssl libstdc++ libpcap libmaxminddb libgcc fts librdkafka

COPY --from=builder /usr/local/zeek /usr/local/zeek
COPY local.zeek /usr/local/zeek/share/zeek/site/local.zeek
COPY scripts /usr/local/zeek/share/zeek/site/scripts
# Add a few zeek scripts

WORKDIR /logs

ENV ZEEKPATH .:/data/config:/usr/local/zeek/share/zeek:/usr/local/zeek/share/zeek/policy:/usr/local/zeek/share/zeek/site
ENV PATH $PATH:/usr/local/zeek/bin

ENTRYPOINT ["zeek"]
CMD ["-h"]