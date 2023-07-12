ARG BASE_IMAGE=ubuntu:22.04

FROM ${BASE_IMAGE} as builder

ENV DEBIAN_FRONTEND="noninteractive"

WORKDIR /app

RUN apt-get update; \
    apt-get install -y libfontconfig1 libpcre3 libpcre3-dev git dpkg-dev libpng-dev libssl-dev wget

RUN wget http://nginx.org/download/nginx-1.24.0.tar.gz; \
    tar -xzf nginx-1.24.0.tar.gz; \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module; \
    cd /app/nginx-1.24.0; \
    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch; \
    ./configure \
        --prefix=/usr/local/nginx \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-threads \
        --add-module=/app/ngx_http_proxy_connect_module; \
    make -j$(grep processor /proc/cpuinfo | wc -l); \
    make install -j$(grep processor /proc/cpuinfo | wc -l)

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /tini
RUN chmod +x /tini

FROM ${BASE_IMAGE}

COPY config/nginx.conf /usr/local/nginx/conf/nginx.conf
COPY --from=builder /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx
COPY --from=builder /tini /tini

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update; \
    apt-get install -y --no-install-recommends coreutils curl iputils-ping libssl-dev netcat net-tools; \
    mkdir -p /usr/local/nginx/logs/; \
    touch /usr/local/nginx/logs/error.log

EXPOSE 8888

ENTRYPOINT ["/tini", "--"]

CMD ["/usr/local/nginx/sbin/nginx"]