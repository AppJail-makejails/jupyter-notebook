ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG PYVER
ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="Jupyter" \
    org.opencontainers.image.description="Web-based notebook environment for interactive computing" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/jupyter-notebook" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/jupyter-notebook" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    pkg update; \
    pkg install -U \
        python \
        py${PYVER}-pip \
        py${PYVER}-notebook \
        py${PYVER}-jupyterlab \
        py${PYVER}-nbclassic \
        py${PYVER}-jupyter-kernel-gateway \
        npm \
        rust \
        FreeBSD-set-base-jail; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

RUN set -xe; \
    \
    umask 0022; \
    \
    npm install -g configurable-http-proxy; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        rm -rf /.npm; \
    fi

RUN set -xe; \
    \
    umask 0022; \
    \
    pip install --break-system-packages jupyterhub; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        rm -rf /.cache; \
        rm -rf /.cargo; \
    fi

RUN mkdir /entrypoint.d
COPY entrypoint.sh start-notebook.py start-singleuser.py /
RUN chmod +x /entrypoint.sh /start-notebook.py /start-singleuser.py

COPY jupyter_server_config.py /usr/local/etc/jupyter
RUN chmod 644 /usr/local/etc/jupyter/jupyter_server_config.py

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT
USER root
WORKDIR /noroot
RUN mkdir -p /noroot && \
    chmod 755 /noroot
ENTRYPOINT ["/entrypoint.sh"]
CMD ["start-notebook.py"]
