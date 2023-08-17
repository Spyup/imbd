FROM docker.io/nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
MAINTAINER Spyup <jason88tu@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends apt-utils && \
    apt install -y net-tools && \
    apt install -y iputils-ping && \
    apt install -y vim nano && \
    apt install -y openssh-server && \
    apt install -y git zip htop screen libgl1-mesa-glx && \    
    apt clean

### Python3.10
RUN apt install -y software-properties-common && \
    apt update -y && \
    apt-get install python3.10 -y && \
    apt clean && \
    cd /usr/bin/ ; rm python3 ; ln -s python3.10 python3

### Python3.8
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt update -y && \
    apt-get install python3.8 -y && \
    apt-get install python3.8-distutils -y && \
    apt clean

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
RUN pipenv install --verbose --python 3.10 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

### Build Env (Tensorflow_keras version)
WORKDIR /envs
RUN mkdir tf_keras
COPY tf_keras_version.txt tf_keras/requirements.txt
WORKDIR tf_keras
RUN pipenv install --verbose --python 3.10 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache


### Build Env (Yolov7 version)
WORKDIR /envs
RUN git clone https://github.com/WongKinYiu/yolov7.git
WORKDIR yolov7
RUN pipenv install --verbose --python 3.8 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

WORKDIR /envs

### R for 4.3
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" && \
    apt update -y && \
    apt-get install --no-install-recommends r-base r-base-dev -y && \
    apt clean

### oracle JAVA 8
COPY jdk-8u371-linux-x64.tar.gz /opt
WORKDIR /opt
RUN tar zxvf jdk-8u371-linux-x64.tar.gz
RUN rm jdk-8u371-linux-x64.tar.gz

ENV JAVA_HOME /opt/jdk1.8.0_371
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV CUDA_PATH /usr/local/cuda
ENV PATH=${CUDA_PATH}/bin:${JAVA_HOME}/bin:$PATH
COPY profile /etc/profile

### R packages
RUN R CMD javareconf
RUN apt-get install libxml2-dev libfontconfig1-dev libcurl4-openssl-dev libssl-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libgmp-dev libudunits2-dev libgdal-dev -y
RUN ln -s /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/libOpenCL.so
RUN Rscript -e "options('repos' = c(CRAN='https://cran.csie.ntu.edu.tw/'))"
RUN Rscript -e "install.packages(c('xgboost', 'readxl', 'tidyverse', 'klaR', 'ClusterR', 'pracma', 'fields', 'filehashSQLite', 'filehash', 'LatticeKrig', 'spam', 'RSpectra', 'filematrix', 'autoFRK', 'Metrics', 'adabag', 'neuralnet', 'caTools', 'nnet', 'caret', 'ada', 'randomForest', 'inTrees', 'UBL', 'cvTools', 'gdata', 'moments', 'zoo', 'MASS', 'chemometrics', 'rpart', 'e1071'),verbose=TRUE)"

### change permission and create group for user

RUN groupadd imbduser && \
    chown -R root:imbduser /envs && \
    chmod -R 770 /envs

WORKDIR /envs

ENTRYPOINT service ssh restart && /bin/bash
