FROM ubuntu:18.04
MAINTAINER Pentestify <contact@pentestify.com>
ENV DEBIAN_FRONTEND noninteractive

USER root

# Migrate!
WORKDIR /opt/warvox

# Set up intrigue
ENV BUNDLE_JOBS=12
ENV PATH /root/.rbenv/bin:$PATH
ENV IDIR=/core
ENV DEBIAN_FRONTEND=noninteractive

# base deps 
# Clean up

RUN apt-get autoremove
RUN apt-get --purge remove
RUN apt-get autoclean
RUN apt-get clean
RUN apt-get update --fix-missing

# Place base deps here so we don't have to reinstall every time
RUN  apt-get -y --fix-broken --no-install-recommends install make \
  sudo \
  gnuplot \
  lame \
  build-essential \
  libssl-dev \
  libcurl4-openssl-dev \
  postgresql \
  postgresql-contrib \
  postgresql-common \
  git-core \
  curl \
  libpq-dev \
  sox \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*s

# create a volume
VOLUME /opt/warvox

# copy intrigue code
COPY . /opt/warvox/

# install intrigue-specific software & config
RUN /bin/bash /opt/warvox/setup.sh
RUN /opt/warvox/bin/adduser admin randompass

# Expose the port
EXPOSE 7777

RUN chmod +x /opt/warvoxbin/warvox
ENTRYPOINT ["/opt/warvoxbin/warvox --address 0.0.0.0"]
