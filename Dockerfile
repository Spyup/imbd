FROM docker.io/nvidia/cuda:12.1.1-cudnn8-devel-ubuntu20.04
MAINTAINER Spyup <jason88tu@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends apt-utils && \
    apt install -y net-tools && \
    apt install -y iputils-ping && \
    apt install -y vim nano && \
    apt install -y openssh-server && \
    apt clean

### Python3.8
RUN apt install -y software-properties-common && \
    apt update -y && \
    apt-get install python3.8 -y && \
    apt clean && \
    cd /usr/bin/ ; rm python3 ; ln -s python3.8 python3

### Pip3 && pipenv

RUN apt install -y python3-pip && \
    apt-get install -y python3-apt && \
    apt clean
RUN pip3 install -U pip
RUN pip3 install -U setuptools
RUN pip3 install pipenv

### Build Env (Pytorch version)
ENV WORKON_HOME /envs
RUN mkdir /envs

ENV PIPENV_TIMEOUT 9999
ENV PIPENV_INSTALL_TIMEOUT 9999

WORKDIR /envs
RUN mkdir pytorch
COPY pytorch_version.txt pytorch/requirements.txt
WORKDIR pytorch
RUN pipenv install --verbose --python 3.8 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

### Build Env (Tensorflow_keras version)
WORKDIR /envs
RUN mkdir tf_keras
COPY tf_keras_version.txt tf_keras/requirements.txt
WORKDIR tf_keras
RUN pipenv install --verbose --python 3.8 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

WORKDIR /envs

### R for 4.2.1
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" && \
    apt update -y && \
    apt install r-recommended r-base -y && \
    apt clean

### oracle JAVA 8
COPY jdk-8u333-linux-x64.tar.gz /opt
WORKDIR /opt
RUN tar zxvf jdk-8u333-linux-x64.tar.gz
RUN rm jdk-8u333-linux-x64.tar.gz

ENV JAVA_HOME /opt/jdk1.8.0_333
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV CUDA_PATH /usr/local/cuda-12
ENV PATH=${CUDA_PATH}/bin:${JAVA_HOME}/bin:$PATH
COPY profile /etc/profile

### R packages
RUN R CMD javareconf
RUN apt update -y
RUN apt install ocl-icd-opencl-dev libxml2-dev libgmp3-dev opencl-headers libssl-dev libcurl4-openssl-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libtiff5-dev libudunits2-dev libgdal-dev --fix-missing -y
RUN ln -s /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/libOpenCL.so
RUN Rscript -e "options('repos' = c(CRAN='https://cran.csie.ntu.edu.tw/'))"
RUN Rscript -e "install.packages(c('xgboost', 'readxl', 'xlsx', 'tidyverse', 'klaR', 'ClusterR', 'pracma', 'fields', 'filehashSQLite', 'filehash', 'LatticeKrig', 'spam', 'RSpectra', 'filematrix', 'autoFRK', 'Metrics', 'adabag', 'neuralnet', 'caTools', 'nnet', 'caret', 'ada', 'randomForest', 'inTrees', 'UBL', 'cvTools', 'gdata', 'moments', 'zoo', 'MASS', 'chemometrics', 'rpart', 'e1071'))"

### change permission and create group for user

RUN groupadd imbduser && \
    chown -R root:imbduser /envs && \
    chmod -R 770 /envs

WORKDIR /envs

ENTRYPOINT service ssh restart && /bin/bash
