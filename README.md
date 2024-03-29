# DO NOT USE THIS REPOSITORY ANYMORE

We stopped maintaining this repository anymore.

Use [mirakc/timeshift-gerbera](https://hub.docker.com/r/mirakc/timeshift-gerbera) instead.

# docker-minidlna

> Multi-Arch MiniDLNA (ReadyMedia) Docker images based on Alpine, dedicated for mirakc/timeshift-fs

## How to use

```yaml
x-environment: &default-environment
  TZ: Asia/Tokyo

services:
  mirakc:
    ...
    volumes:
      - /path/to/config.yml:/etc/mirakc/config.yml:ro
      - /path/to/timeshift:/var/lib/mirakc/timeshift
    ...

  mirakc-timeshift-fs:
    container_name: mirakc-timeshift-fs
    image: mirakc/timeshift-fs
    init: true
    restart: unless-stopped
    cap_add:
      - SYS_ADMIN
    # In addition, you might have to run with no apparmor security profile
    # in order to avoid "fusermount3: mount failed: Permission denied".
    #security_opt:
    #  - apparmor:unconfined
    devices:
      - /dev/fuse
    volumes:
      # Use the same config.yml
      - /path/to/config.yml:/etc/mirakc/config.yml:ro
      # Timeshift files
      - /path/to/timeshift:/var/lib/mirakc/timeshift
      # Mount point
      - type: bind
        source: /path/to/timeshift-fs
        target: /mnt
        bind:
          propagation: rshared
    environment:
      <<: *default-environment
      RUST_LOG: info

  dlna:
    container_name: dlna
    depends_on:
      - mirakc-timeshift-fs
    image: mirakc/minidlna
    init: true
    restart: unless-stopped
    network_mode: host
    volumes:
      - /path/to/timeshift-fs:/mnt:ro
      - minidlna-cache:/var/cache/minidlna
    environment:
      <<: *default-environment

volumes:
  minidlna-cache:
    name: minidlna_cache
    driver: local
```

The `dlna` service starts listening on 8200/tcp by default.  The `dlna` service also uses 1900/udp
for SSDP multicast.

## How to change /etc/minidlna.conf

First, extract `/etc/minidlna.conf` from the image:

```shell
docker run --rm --entrypoint=cat mirakc/minidlna /etc/minidlna.conf >minidlna.conf
```

Change values, and then run with the `-v $(pwd)/minidlna.conf:/etc/minidlna.conf` option:

```shell
docker run --rm -v $(pwd)/minidlna.conf:/etc/minidlna.conf mirakc/minidlna
```
