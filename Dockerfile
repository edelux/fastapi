# syntax=docker/dockerfile:1
# vim: set filetype=dockerfile
FROM debian AS builder

ARG APP='null'
ARG VERSION='0'

LABEL org.opencontainers.image.title="Static API Simulator Bundle"
LABEL org.opencontainers.image.description="Minimalist image with NGINX and BusyBox, built from Debian to simulate an API or serve static content with embedded metadata."
LABEL org.opencontainers.image.architecture="${TARGETARCH}"
LABEL org.opencontainers.image.supported.architectures="amd64,arm64,ppc64le,s390x,mips64le,riscv64,arm32v6,arm32v7,arm64v8,arm32v5,i386,windows-amd64"
LABEL org.opencontainers.image.platform="linux/${TARGETARCH}"
LABEL org.opencontainers.image.source="https://github.com/edelux/fastapi"
LABEL org.opencontainers.image.url="https://github.com/edelux/fastapi"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="Ernie D'lux (edelux) EDH <edeluquez@hotmail.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LABEL org.opencontainers.image.documentation="https://github.com/edelux/fastapi#readme"
LABEL org.opencontainers.image.vendor="edelux"
LABEL org.opencontainers.image.ref.name="${APP}-${VERSION}"

RUN apt update && apt upgrade -y && apt install -y nginx busybox && \
    rm -fr /var/www/html /etc/nginx/sites* /etc/nginx/modules* && \
    mkdir /scratch && printf '{"data":{"app":"'$APP'","version":"'$VERSION'"}}' >/var/www/index.json && \
    tar cvf - /usr/sbin/nginx /var/log/nginx /var/lib/nginx /usr/share/nginx /etc/nginx /var/www /etc/group /run \
       /usr/lib/*-linux-gnu/ld-linux-*.so* /usr/lib*/ld-linux-*.so* /lib*/ld-linux-*.so* /lib/*-linux-gnu/ld-linux-*.so* \
       /usr/bin/busybox /usr/lib/*-linux-gnu/libresolv.so* /usr/lib/*-linux-gnu/libc.so* /etc/ld.so.conf.d \
       /usr/lib/*-linux-gnu/libcrypt.so* /usr/lib/*-linux-gnu/libpcre*.so* /usr/lib/*-linux-gnu/libssl.so* \
       /usr/lib/*-linux-gnu/libcrypto.so* /usr/lib/*-linux-gnu/libz.so* /usr/lib/*-linux-gnu/libc.so* \
          | (cd /scratch; tar xvfp -)

COPY nginx.conf /scratch/etc/nginx/nginx.conf
COPY nginx.default /scratch/etc/nginx/conf.d/default.conf

RUN egrep 'root|^bin|daemon|www-data|nobody' /etc/passwd >/scratch/etc/passwd && \
    egrep 'root|^bin|daemon|www-data|nobody' /etc/shadow >/scratch/etc/shadow

FROM scratch
COPY --from=builder /scratch /

HEALTHCHECK CMD ["/usr/sbin/nginx", "-t"] || exit 1
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
