FROM selenium/standalone-chrome:3.5.3

USER root

RUN apt-get update \
 && apt-get install -y --force-yes --no-install-recommends \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      dpkg-dev \
      gcc \
      libbz2-1.0 \
      libdpkg-perl \
      libffi-dev \
      libgdbm3 \
      libssl-dev \
      libtimedate-perl \
      libyaml-dev \
      netbase \
      perl \
      perl-base\
      procps \
      zlib1g-dev \
      zlib1g

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
 && { \
   echo 'install: --no-document'; \
   echo 'update: --no-document'; \
 } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.1
ENV RUBYGEMS_VERSION 2.5.2
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
  && buildDeps=' \
    ruby \
  ' \
  && apt-get update \
  && apt-get install -y --force-yes --no-install-recommends $buildDeps \
    autoconf \
    bison \
    gcc \
    libbz2-dev \
    libgdbm-dev \
    libglib2.0-dev \
    libncurses-dev \
    libncurses5\
    libncursesw5\
    libpcre3-dev \
    libpcre3\
    libpython-stdlib \
    libpython2.7-stdlib \
    libreadline-dev \
    libreadline6-dev \
    libtinfo-dev\
    libtinfo5\
    libxml2-dev \
    libxslt-dev \
    make \
    ncurses-bin\
    python \
    python2.7 \
    libmysqlclient-dev \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
  && mkdir -p /usr/src/ruby \
  && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.gz \
  && cd /usr/src/ruby \
  && { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
  && autoconf \
  && ./configure --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y $buildDeps \
  && gem update --system $RUBYGEMS_VERSION \
  && rm -r /usr/src/ruby

ENV BUNDLER_VERSION 1.16.0.pre.2

RUN gem install bundler --version "$BUNDLER_VERSION"

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN useradd -ms /bin/bash tester
USER tester  