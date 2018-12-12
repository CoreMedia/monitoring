
FROM debian:9-slim as builder

ENV \
  TERM=xterm \
  DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update > /dev/null && \
  apt-get dist-upgrade --assume-yes > /dev/null && \
  apt-get install --assume-yes --no-install-recommends \
    bash \
    bzip2 \
    curl \
    ca-certificates \
    cmake \
    file \
    git \
    g++ \
    gnupg2 \
    make \
    libhiredis-dev \
    libev-dev \
    > /dev/null

RUN \
  cd /tmp/ && \
  git clone https://github.com/bodsch/coremedia_icinga2_checks.git && \
  git clone https://github.com/hmartiro/redox.git && \
  git clone https://github.com/nlohmann/json

RUN \
  cd /tmp/redox && \
  cmake -H. -Bbuild && \
  cmake --build build -- -j3 && \
  cd build && \
  make install

RUN \
  cd /tmp/json && \
  cp -ar /tmp/json/include/nlohmann /usr/local/include/ && \
  ls -1 /usr/local/include/

RUN \
  cd /tmp/coremedia_icinga2_checks && \
  cmake -H. -Bbuild && \
  cmake --build build -- -j3

# ---------------------------------------------------------------------------------------

FROM bodsch/docker-icinga2:2.10.1-master

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TERM=xterm \
  DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------------------

COPY build /build

RUN \
  apt-get update > /dev/null && \
  apt-get install --assume-yes --no-install-recommends \
    g++ make ruby-dev \
    libhiredis0.13 libev4 \
    > /dev/null && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem install --quiet --no-rdoc --no-ri \
    io-console bundler && \
  cd /build && \
  bundle install --quiet && \
  for g in $(ls -1 /build/*.gem 2> /dev/null) ; \
  do \
    echo $g; \
    gem install --quiet --no-rdoc --no-ri ${g} ; \
  done && \
  gem uninstall --quiet \
    io-console bundler && \
  apt-get clean > /dev/null && \
  apt autoremove --assume-yes > /dev/null && \
  rm -rf \
    /tmp/* \
    /var/cache/debconf/* \
    /usr/share/doc/* \
    /root/.gem \
    /root/.bundle

COPY --from=builder /tmp/coremedia_icinga2_checks/build/check_*  /usr/lib/monitoring-plugins/
COPY --from=builder /usr/local/lib64 /usr/local/lib64
COPY rootfs/ /

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
