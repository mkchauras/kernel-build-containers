ARG UBUNTU_VERSION=default
FROM ubuntu:${UBUNTU_VERSION} AS base
ARG UBUNTU_VERSION

# Rewrite apt sources to HTTPS before the first apt-get update so that
# subsequent package operations work on hosts where port 80 is blocked.
#
# Ubuntu 24.04+ uses DEB822 format (.sources) with 'URIs: http://' lines.
# Older releases use sources.list with 'deb http://' lines.
#
# Bootstrap sequence:
#   1. Rewrite sources HTTP -> HTTPS (no network needed, just sed)
#   2. apt-get update with SSL verification disabled (no ca-certs yet)
#   3. Install ca-certificates
#   4. update-ca-certificates so all subsequent apt calls verify properly
RUN find /etc/apt/sources.list.d/ -name '*.sources' \
        -exec sed -i 's|URIs: http://|URIs: https://|g' {} + && \
    find /etc/apt/ -maxdepth 1 -name 'sources.list' \
        -exec sed -i 's|deb http://|deb https://|g' {} + && \
    apt-get \
        -o Acquire::https::Verify-Peer=false \
        -o Acquire::https::Verify-Host=false \
        update && \
    apt-get \
        -o Acquire::https::Verify-Peer=false \
        -o Acquire::https::Verify-Host=false \
        install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; \
    apt-get update; \
    if [ "${UBUNTU_VERSION%%.*}" -lt 26 ]; then \
      apt-get install -y -q apt-utils dialog exuberant-ctags; \
    else \
      apt-get install -y -q universal-ctags; \
    fi; \
    apt-get install -y -q sudo aptitude flex bison cpio libncurses5-dev make git sparse bc libssl-dev libelf-dev bsdmainutils dwarves xz-utils zstd gawk rsync; \
    apt-get install -y -q python3 python3-venv; \
    apt-get install -y -q python-is-python3 || apt-get install -y -q python

ARG GCC_VERSION
RUN set -ex; \
    if [ "$GCC_VERSION" ]; then \
      ARCH=$(dpkg --print-architecture); \
      apt-get update; \
      apt-get install -y -q gcc-${GCC_VERSION} g++-${GCC_VERSION} gcc-${GCC_VERSION}-plugin-dev \
        gcc-${GCC_VERSION}-arm-linux-gnueabi g++-${GCC_VERSION}-arm-linux-gnueabi; \
      if [ "$ARCH" != "ppc64el" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-powerpc64le-linux-gnu g++-${GCC_VERSION}-powerpc64le-linux-gnu; \
      fi; \
      if [ "$ARCH" != "arm64" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-aarch64-linux-gnu g++-${GCC_VERSION}-aarch64-linux-gnu; \
      fi; \
      if [ "$ARCH" != "amd64" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-x86-64-linux-gnu g++-${GCC_VERSION}-x86-64-linux-gnu; \
      fi; \
      if [ "$GCC_VERSION" != "4.9" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-plugin-dev-arm-linux-gnueabi; \
        if [ "$ARCH" != "ppc64el" ]; then \
          apt-get install -y -q gcc-${GCC_VERSION}-plugin-dev-powerpc64le-linux-gnu; \
        fi; \
        if [ "$ARCH" != "arm64" ]; then \
          apt-get install -y -q gcc-${GCC_VERSION}-plugin-dev-aarch64-linux-gnu; \
        fi; \
        if [ "$ARCH" != "amd64" ]; then \
          apt-get install -y -q gcc-${GCC_VERSION}-plugin-dev-x86-64-linux-gnu; \
        fi; \
      fi; \
      if [ "$GCC_VERSION" != "4.9" ] && [ "$GCC_VERSION" != "5" ] && [ "$GCC_VERSION" != "6" ]; then \
        apt-get install -y -q gcc-${GCC_VERSION}-riscv64-linux-gnu g++-${GCC_VERSION}-riscv64-linux-gnu gcc-${GCC_VERSION}-plugin-dev-riscv64-linux-gnu; \
      fi; \
      update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100; \
      if [ "$ARCH" != "arm64" ]; then \
        update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc-${GCC_VERSION} 100; \
        update-alternatives --install /usr/bin/aarch64-linux-gnu-g++ aarch64-linux-gnu-g++ /usr/bin/aarch64-linux-gnu-g++-${GCC_VERSION} 100; \
      fi; \
      if [ "$ARCH" != "amd64" ]; then \
        update-alternatives --install /usr/bin/x86_64-linux-gnu-gcc x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-${GCC_VERSION} 100; \
        update-alternatives --install /usr/bin/x86_64-linux-gnu-g++ x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-${GCC_VERSION} 100; \
      fi; \
      update-alternatives --install /usr/bin/arm-linux-gnueabi-gcc arm-linux-gnueabi-gcc /usr/bin/arm-linux-gnueabi-gcc-${GCC_VERSION} 100; \
      update-alternatives --install /usr/bin/arm-linux-gnueabi-g++ arm-linux-gnueabi-g++ /usr/bin/arm-linux-gnueabi-g++-${GCC_VERSION} 100; \
      if [ "$ARCH" != "ppc64el" ]; then \
        update-alternatives --install /usr/bin/powerpc64le-linux-gnu-gcc powerpc64le-linux-gnu-gcc /usr/bin/powerpc64le-linux-gnu-gcc-${GCC_VERSION} 100; \
        update-alternatives --install /usr/bin/powerpc64le-linux-gnu-g++ powerpc64le-linux-gnu-g++ /usr/bin/powerpc64le-linux-gnu-g++-${GCC_VERSION} 100; \
      fi; \
      if [ "$GCC_VERSION" != "4.9" ] && [ "$GCC_VERSION" != "5" ] && [ "$GCC_VERSION" != "6" ]; then \
        update-alternatives --install /usr/bin/riscv64-linux-gnu-gcc riscv64-linux-gnu-gcc /usr/bin/riscv64-linux-gnu-gcc-${GCC_VERSION} 100; \
        update-alternatives --install /usr/bin/riscv64-linux-gnu-g++ riscv64-linux-gnu-g++ /usr/bin/riscv64-linux-gnu-g++-${GCC_VERSION} 100; \
      fi; \
    fi

ARG CLANG_VERSION
RUN set -ex; \
    if [ "$CLANG_VERSION" ]; then \
      apt-get update; \
      if [ "$CLANG_VERSION" = "5" ] || [ "$CLANG_VERSION" = "6" ]; then \
        CLANG_VERSION="${CLANG_VERSION}.0"; \
        apt-get install -y -q clang-${CLANG_VERSION} lld-${CLANG_VERSION} clang-tools-6.0; \
      else \
        apt-get install -y -q clang-${CLANG_VERSION} lld-${CLANG_VERSION} clang-tools-${CLANG_VERSION} llvm-${CLANG_VERSION}; \
      fi; \
      if [ "$CLANG_VERSION" != "5.0" ] && [ "$CLANG_VERSION" != "6.0" ]; then \
        update-alternatives --install /usr/bin/llvm-strip llvm-strip /usr/bin/llvm-strip-${CLANG_VERSION} 100; \
        update-alternatives --install /usr/bin/llvm-objcopy llvm-objcopy /usr/bin/llvm-objcopy-${CLANG_VERSION} 100; \
      fi; \
      update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/ld.lld ld.lld /usr/bin/ld.lld-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/bin/llvm-objdump-${CLANG_VERSION} 100; \
      update-alternatives --install /usr/bin/llvm-readelf llvm-readelf /usr/bin/llvm-readelf-${CLANG_VERSION} 100; \
    fi

ARG UNAME
ARG UID
ARG GNAME
ARG GID
RUN set -x; \
    userdel -r `getent passwd ${UID} | cut -d : -f 1` > /dev/null 2>&1; \
    groupdel -f `getent group ${GID} | cut -d : -f 1` > /dev/null 2>&1; \
    groupadd -g ${GID} ${GNAME}; \
    useradd -u $UID -g $GID -G sudo -ms /bin/bash ${UNAME}; \
    mkdir /src; \
    chown -R ${UNAME}:${GNAME} /src; \
    mkdir /out; \
    chown -R ${UNAME}:${GNAME} /out; \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN set -ex; \
    apt-get update; \
    apt-get install -y -q ccache; \
    mkdir -p /home/${UNAME}/.cache/ccache; \
    chown -R ${UNAME}:${GNAME} /home/${UNAME}/.cache; \
    rm -rf /var/lib/apt/lists/*

USER ${UNAME}:${GNAME}
WORKDIR /src

RUN set -ex; \
    id | grep "uid=${UID}(${UNAME}) gid=${GID}(${GNAME})"; \
    sudo ls; \
    pwd | grep "^/src"; \
    touch /src/test; \
    rm /src/test; \
    touch /out/test; \
    rm /out/test

CMD ["bash"]
