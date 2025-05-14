# syntax=docker/dockerfile:1
# vim: set filetype=dockerfile
FROM debian AS builder

ARG APP='null'
ARG VERSION='0'

RUN apt update && apt upgrade -y && apt install -y nginx busybox && \
    rm -fr /var/www/html /etc/nginx/sites* /etc/nginx/modules* && \
    mkdir /scratch && printf '{"data":{"app":"'$APP'","version":"'$VERSION'"}}' >/var/www/index.json && \
    tar cvf - /usr/sbin/nginx /var/log/nginx /var/lib/nginx /usr/share/nginx /etc/nginx /var/www /etc/group /run \
      /usr/bin/busybox /usr/lib/*-linux-gnu/libresolv.so* /usr/lib/*-linux-gnu/libc.so* /etc/ld.so.conf.d \
      /usr/lib/*-linux-gnu/ld-linux-*.so* /usr/lib*/ld-linux-*.so* /lib*/ld-linux-*.so* /lib/*-linux-gnu/ld-linux-*.so* \
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
