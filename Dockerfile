FROM ubuntu:16.04

ENV SRC_DIR=/tmp/saige-src

RUN set -x \
    && apt-get update && apt-get install -y \
        apt-transport-https \
        build-essential \
        cmake \
        curl \
        git \
        libboost-all-dev \
        python-pip \
        software-properties-common \
        tar \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/' \
    && apt-get update \
    && apt-get install -y \
        r-base \
    && pip install cget

WORKDIR ${SRC_DIR}
COPY install_packages.R ${SRC_DIR}
RUN Rscript install_packages.R

RUN git clone --depth 1 https://github.com/weizhouUMICH/SAIGE.git
RUN rm -rf ${SRC_DIR}/SAIGE/thirdParty/cget \
    && rm ${SRC_DIR}/SAIGE/src/*.o \
    && rm ${SRC_DIR}/SAIGE/src/*.so

RUN cget install -DUSE_CXX3_ABI=ON -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" --prefix ${SRC_DIR}/SAIGE/thirdParty/cget -f ${SRC_DIR}/SAIGE/thirdParty/requirements.txt
RUN R CMD INSTALL --build ${SRC_DIR}/SAIGE

RUN cp ${SRC_DIR}/SAIGE/extdata/step1_fitNULLGLMM.R ${SRC_DIR}/SAIGE/extdata/step2_SPAtests.R /usr/local/bin/ \
    && rm -rf ${SRC_DIR}

WORKDIR /
