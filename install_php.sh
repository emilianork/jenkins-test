#!/bin/sh

# Installs PHP 7.4.33

# Part of this installation was copied from the official PHP Docker repository
# https://github.com/docker-library/php/blob/1361ba95d80570e3984f9de9f765948246191557/7.4/alpine3.16/fpm

# persistent / runtime deps
export PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c"
apk update \
; \
apk add --no-cache \
    ca-certificates \
    curl \
    tar \
    xz \
    libffi-dev \
    openssl

set -eux; \
    \
    adduser -u 82 -D -S -G www-data www-data

export PHP_INI_DIR=/usr/local/etc/php
mkdir -p $PHP_INI_DIR/conf.d; \
    [ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

export PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data"

export PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
export PHP_CPPFLAGS="$PHP_CFLAGS"
export PHP_LDFLAGS="-Wl,-O1 -pie"

export GPG_KEYS="5A52880781F755608BF815FC910DEB46F53EA312"

export PHP_VERSION="7.4.32"
#export PHP_URL="https://www.php.net/distributions/php-7.4.33.tar.xz" 
#export PHP_ASC_URL="https://www.php.net/distributions/php-7.4.33.tar.xz.asc"

export PHP_URL="https://secure.php.net/get/php-7.4.32.tar.xz/from/this/mirror"
export PHP_ASC_URL="https://secure.php.net/get/php-7.4.32.tar.xz.asc/from/this/mirror"
export PHP_SHA256="323332c991e8ef30b1d219cb10f5e30f11b5f319ce4c6642a5470d75ade7864a"

export PHP_MD5=""

set -eux; \
    \
    apk add --no-cache --virtual .fetch-deps \
        gnupg \
    ; \
    \
    mkdir -p /usr/src; \
    cd /usr/src; \
    \
    curl -fsSL -o php.tar.xz "$PHP_URL"; \
    \
    if [ -n "$PHP_SHA256" ]; then \
        echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
    fi; \
    \
    if [ -n "$PHP_ASC_URL" ]; then \
        curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
        export GNUPGHOME="$(mktemp -d)"; \
        for key in $GPG_KEYS; do \
            gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
        done; \
        gpg --batch --verify php.tar.xz.asc php.tar.xz; \
        gpgconf --kill all; \
        rm -rf "$GNUPGHOME"; \
    fi; \
    \
    apk del --no-network .fetch-deps

set -eux; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        argon2-dev \
        coreutils \
        curl-dev \
        gnu-libiconv-dev \
        libsodium-dev \
	libxml2-dev \
        linux-headers \
        oniguruma-dev \
	openssl-dev \
        readline-dev \
        sqlite-dev

set -eux; \
    rm -vf /usr/include/iconv.h \
    && ln -sv /usr/include/gnu-libiconv/*.h /usr/include/ \
    && export CFLAGS="$PHP_CFLAGS" \
        CPPFLAGS="$PHP_CPPFLAGS" \
        LDFLAGS="$PHP_LDFLAGS" \
    && docker-php-source extract \
    && cd /usr/src/php \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure \
        --build="$gnuArch" \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-mhash \
        --with-pic \
        --enable-ftp \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
	--with-sqlite3=/usr \
        --with-iconv=/usr \
        --with-openssl \
        --with-zlib \
        --with-curl \
        --with-readline \
        --disable-phpdbg \
        --with-pear \
        --enable-phpdbg \
	--enable-phpdbg-readline \
        $(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
        --disable-cgi \
        $PHP_EXTRA_CONFIGURE_ARGS \
    && make -j "$(nproc)"; \
    find -type f -name '*.a' -delete; \
    \
    make install \
    && find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
    ; \
    make clean \
    && cp -v php.ini-* "$PHP_INI_DIR/" \
    && cd / \
    && docker-php-source delete \
    && runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
    && apk add --no-cache $runDeps \
    && apk del --no-network .build-deps \
    && pecl update-channels \
    && rm -rf /tmp/pear ~/.pearrc \
    && php --version
