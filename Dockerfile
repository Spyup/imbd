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

### Build Env (Yolov7 version)
WORKDIR /envs
RUN git clone https://github.com/WongKinYiu/yolov7.git
WORKDIR yolov7
RUN pipenv install --verbose --python 3.10 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

WORKDIR /envs

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

### change permission and create group for user

RUN groupadd imbduser && \
    chown -R root:imbduser /envs && \
    chmod -R 770 /envs

WORKDIR /envs/yolov7
RUN wget -4 https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7.pt

WORKDIR /envs
COPY testYolov7.sh testYolov7.sh

WORKDIR /envs

ENTRYPOINT service ssh restart && /bin/bash
