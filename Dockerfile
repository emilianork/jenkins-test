FROM jenkins/jenkins:2.400-alpine

MAINTAINER Prachetas Prabhu <prachetas@yoink.biz>

# Temporarily elevate privs to do OS package installations
USER root

COPY docker-php-* /usr/local/bin/

COPY install_php.sh /
RUN /install_php.sh

COPY php.ini /usr/local/etc/php/php.ini

# Revert privileges for security
USER jenkins
