FROM centos:latest

LABEL maintainer="Joerg Klein <kwp.klein@gmail.com>" \
      description="Docker base image to build RPM files for CentOS"

RUN dnf update -y  \
    && dnf group install -y "Development Tools" \
    && dnf install -y rpmdevtools rpmlint dnf-utils \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Set locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set Workdir to root/rpmbuild
WORKDIR /root

# Copy files
COPY rpmmacros .rpmmacros

# Setup rpmdev-setuptree
RUN rpmdev-setuptree

