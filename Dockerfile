ARG VERSION_ID=7
ARG REGISTRY_IMAGE=centos
FROM $REGISTRY_IMAGE:$VERSION_ID

ARG PYTHON_VERSION
ARG PYTHON_PIP_VERSION

ENV PYTHON_VERSION $PYTHON_VERSION
ENV PYTHON_PIP_VERSION $PYTHON_PIP_VERSION

ENV LC_ALL en_US.utf-8
ENV LANG en_US.utf-8

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
        git \
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
    && yum clean all \
    && rm -rf /var/cache/yum/* \
    && gem install --no-document ffi:1.12.2 fpm:1.11.0 ronn:0.7.3

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

RUN echo "Processing python $PYTHON_VERSION" \
    && major_version="${PYTHON_VERSION:0:1}" \
    && short_version="${PYTHON_VERSION:0:3}" \
    && digit_version="${major_version}${short_version:2}" \
    && /opt/python-${digit_version}/bin/python${short_version} -m pip install --no-cache-dir --upgrade \
        'black;python_version>="3.6"' \
        flake8 \
        gunicorn \
        pip==$PYTHON_PIP_VERSION \
        pipenv \
        pyinstaller \
        pylint \
        setuptools \
        tox \
        virtualenv \
        wheel

WORKDIR /apps

ENV PATH /opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
