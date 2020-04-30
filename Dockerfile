FROM ubuntu:16.04 as fetch

RUN set -x \
    && apt-get update && apt-get install -y \
        curl

WORKDIR /tmp
RUN curl -O https://github.com/weizhouUMICH/SAIGE/releases/download/0.36.2/SAIGE_0.36.2_R_x86_64-pc-linux-gnu.tar.gz 
RUN tar -zxvf SAIGE_0.36.2_R_x86_64-pc-linux-gnu.tar.gz


FROM ubuntu:16.04

ENV SRC_DIR=/tmp/saige-src

RUN set -x \
    && apt-get update && apt-get install -y \
        apt-transport-https \
        build-essential \
        cmake \
        curl \
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

COPY --from=fetch /tmp/SAIGE/R ./R
COPY --from=fetch /tmp/SAIGE/build ./build
COPY --from=fetch /tmp/SAIGE/extdata ./extdata
COPY --from=fetch /tmp/SAIGE/man ./man
COPY --from=fetch /tmp/SAIGE/src ./src
COPY --from=fetch /tmp/SAIGE/DESCRIPTION .
COPY --from=fetch /tmp/SAIGE/INDEX .
COPY --from=fetch /tmp/SAIGE/NAMESPACE .
COPY --from=fetch /tmp/SAIGE/thirdParty/bgen ./thirdParty/bgen
COPY --from=fetch /tmp/SAIGE/thirdParty/zlib-1.2.8 ./thirdParty/zlib-1.2.8
COPY --from=fetch /tmp/SAIGE/thirdParty/requirements.txt ./thirdParty/requirements.txt

RUN rm ${SRC_DIR}/src/*.o && rm ${SRC_DIR}/src/*.so

RUN cget install -DUSE_CXX3_ABI=ON -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" --prefix ${SRC_DIR}/thirdParty/cget -f ${SRC_DIR}/thirdParty/requirements.txt
RUN R CMD INSTALL --build ${SRC_DIR}

RUN cp ${SRC_DIR}/extdata/step1_fitNULLGLMM.R ${SRC_DIR}/extdata/step2_SPAtests.R /usr/local/bin/ \
    && rm -rf ${SRC_DIR}

WORKDIR /
