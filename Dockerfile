# Git 2.26 stage
ARG VERSION_ID=7
ARG REGISTRY_IMAGE=centos
ARG VERSION_ID=7
FROM $REGISTRY_IMAGE:$VERSION_ID
RUN yum install -y \
        wget \
        curl-devel \
        expat-devel \
        gettext-devel \
        openssl-devel \
        zlib-devel \
        gcc \
        make \
        perl-ExtUtils-MakeMaker
RUN cd /usr/src \
    && wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.26.0.tar.gz \
    && tar xz --no-same-owner -f git-2.26.0.tar.gz \
    && cd git-2.26.0 \
    && make prefix=/usr/local/git all \
    && make prefix=/usr/local/git install \
    && tar cvfz /tmp/git.tar.gz /usr/local/git

# Python stage
ARG VERSION_ID=7
ARG REGISTRY_IMAGE=centos
FROM $REGISTRY_IMAGE:$VERSION_ID
ARG PYTHON_VERSION
ARG PYTHON_PIP_VERSION

ENV PYTHON_VERSION $PYTHON_VERSION
ENV PYTHON_PIP_VERSION $PYTHON_PIP_VERSION

ENV LC_ALL en_US.utf-8
ENV LANG en_US.utf-8

ENV PATH /opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/bin/

COPY --from=0 /tmp/git.tar.gz /tmp/git.tar.gz

RUN VERSION_ID=$(rpm -q --queryformat '%{VERSION}' centos-release) \
    && yum install -y \
        bash \
        bzip2-devel \
        ca-certificates \
        curl \
        curl-devel \
        expat-devel \
        gcc \
        gcc-c++ \
        gettext-devel \
        glibc \
        glibc-devel \
        jq \
        kernel-headers \
        krb5-devel \
        krb5-libs \
        libffi-devel \
        make \
        openssl \
        openssl-devel \
        rpm-build \
        ruby-devel \
        rubygems \
        sqlite-devel \
        swig \
        vim \
        zlib-devel \
    && yum remove -y git \
    && yum clean all \
    && rm -rf /var/cache/yum/* \
    && gem install --no-document ffi:1.12.2 fpm:1.11.0 ronn:0.7.3

RUN echo "Adding git" \
    cd / \
    && tar xvfz /tmp/git.tar.gz \
    && echo 'export PATH=/opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/bin:/usr/local/git/bin' >> /etc/bashrc \
    && ln -s /usr/local/git/bin/* /usr/bin/

RUN echo "Processing python $PYTHON_VERSION" \
    && major_version="${PYTHON_VERSION:0:1}" \
    && short_version="${PYTHON_VERSION:0:3}" \
    && digit_version="${major_version}${short_version:2}" \
    && cd /usr/src \
    && curl -s "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" -o  "Python-${PYTHON_VERSION}.tgz" \
    && tar xzf "Python-${PYTHON_VERSION}.tgz" \
    && cd "Python-${PYTHON_VERSION}" \
    && ./configure \
        --build="x86_64-linux-gnu" \
        --enable-loadable-sqlite-extensions \
        --enable-optimizations \
        --enable-shared \
        --enable-unicode=ucs4 \
        --prefix=/opt/python-${digit_version} \
        --with-ensurepip \
        --with-system-expat \
        --with-system-ffi \
        --with-tsc \
        LDFLAGS=-Wl,-rpath=/opt/python-${digit_version}/lib \
    && make -j4 altinstall \
    && ln -s /opt/python-${digit_version}/bin/python${short_version} /usr/bin/py${digit_version} \
    && ln -s /opt/python-${digit_version}/bin/python${short_version} /opt/python-${digit_version}/bin/python \
    && /opt/python-${digit_version}/bin/python${short_version} -m ensurepip \
    && rm -f /opt/python-${digit_version}/bin/pip \
    && rm -f /opt/python-${digit_version}/bin/pip${major_version} \
    && ln -s /opt/python-${digit_version}/bin/pip${short_version} /opt/python-${digit_version}/bin/pip \
    && ln -s /opt/python-${digit_version}/bin/pip${short_version} /opt/python-${digit_version}/bin/pip${major_version} \
    && ln -s /opt/python-${digit_version} /opt/python \
    && (mkdir /apps 2>/dev/null || echo -n) \
    && rm -rf /usr/src/Python-*

RUN echo "Processing python deps" \
    && major_version="${PYTHON_VERSION:0:1}" \
    && short_version="${PYTHON_VERSION:0:3}" \
    && digit_version="${major_version}${short_version:2}" \
    && /opt/python-${digit_version}/bin/python${short_version} -m pip install --no-cache-dir --upgrade \
        pip==$PYTHON_PIP_VERSION \
        pipx \
        setuptools \
        virtualenv \
        wheel

RUN echo "Processing pipx packages" \
    && pipx install bandit \
    && pipx install coverage \
    && pipx install black \
    && pipx install flake8 \
    && pipx inject flake8 flake8-bugbear \
    && pipx install poetry \
    && pipx inject poetry poetry-dynamic-versioning \
    && pipx install pyinstaller \
    && pipx install pylint \
    && pipx install pytest \
    && pipx inject pytest pytest-cov \
    && pipx install tox \
    && pipx install virtualenv \
    && pipx install pipenv \
    && pipx install gunicorn

RUN echo "Adding UPX" \
    && cd tmp \
    && curl -sL https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz -o upx.tar.xz \
    && tar xvf upx.tar.xz \
    && /usr/bin/rm -f upx.tar.xz \
    && mv ./upx-3.96-amd64_linux /opt/upx


WORKDIR /apps

ENV PATH /opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/bin:/usr/local/git/bin
