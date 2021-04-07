# Images based on alpine:3.13 or newer don't work properly on many linux/arm platforms due to the
# issue described in the following page:
# https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0#musl_1.2
FROM alpine:3.12 AS minidlna-build
WORKDIR /build
RUN apk add --no-cache \
      autoconf \
      automake \
      binutils \
      bsd-compat-headers \
      ca-certificates \
      curl \
      ffmpeg-dev \
      flac-dev \
      g++ \
      gettext-dev \
      git \
      gzip \
      jpeg-dev \
      libc-dev \
      libexif-dev \
      libid3tag-dev \
      libvorbis-dev \
      make \
      patch \
      pkgconf \
      sed \
      sqlite-dev \
      tar \
      zlib-dev
RUN curl -fsSL https://sourceforge.net/projects/minidlna/files/minidlna/1.3.0/minidlna-1.3.0.tar.gz/download | tar -xz --strip-components=1
RUN sh ./autogen.sh
RUN ./configure --enable-lto
COPY ./manual-non-destructive-rescan-v1_3_0.patch ./
RUN patch -p1 <manual-non-destructive-rescan-v1_3_0.patch
RUN make -j $(nproc)
RUN make install
# Modify minidlna.conf for mirakc-timeshift-fs
RUN sed -i -E 's|^#?media_dir=.*$|media_dir=V,/mnt|' minidlna.conf
RUN sed -i -E 's|^#?friendly_name=.*$|friendly_name=Timeshift|' minidlna.conf
RUN sed -i -E 's|^#?db_dir=.*$|db_dir=/var/cache/minidlna|' minidlna.conf
RUN sed -i -E 's|^#?log_level=.*$|log_level=info|' minidlna.conf
# Disable the inotify monitoring.
#
# inotify doesn't work on FUSE filesystems at this point:
# https://github.com/libfuse/libfuse/wiki/Fsnotify-and-FUSE
#
# inotify doesn't work with CIFS mounts:
# https://lists.samba.org/archive/linux-cifs-client/2009-April/004318.html
#
# inotify doesn't work with Docker mounts in some situations:
# https://github.com/moby/moby/issues/18246
RUN sed -i -E 's|^#?inotify=.*$|inotify=no|' minidlna.conf
RUN sed -i -E 's|^#?notify_interval=.*$|notify_interval=300|' minidlna.conf
RUN sed -i -E 's|^#?root_container=.*$|root_container=V|' minidlna.conf

FROM alpine:3.12
LABEL maintainer="Contributors of mirakc"
RUN apk add --no-cache jpeg ffmpeg-libs flac libexif libid3tag libintl libvorbis sqlite-libs tzdata
COPY --from=minidlna-build /usr/local /usr/local/
COPY --from=minidlna-build /build/minidlna.conf /etc/
COPY ./run-minidlna /
HEALTHCHECK --interval=10s --timeout=10s --retries=5 CMD test -f /var/run/minidlna/minidlna.pid
VOLUME /var/cache/minidlna
ENTRYPOINT ["/run-minidlna"]
CMD []
ENV MINIDLNA_REBUILD_INTERVAL=300
EXPOSE 1900/udp
EXPOSE 8200
