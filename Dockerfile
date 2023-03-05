# base image, I choose a ubuntu 18.04 image which is new enough but not too new to break compatibility of some old software.
# you can switch to another image if you like, or switch to an internal docker-hub image if you do not have internet access.
FROM ubuntu:18.04

# use bash for the support of `source` command, and `-l` option to automatic source bash profile
SHELL [ "/bin/bash", "-l", "-c"]

# your username and password, they are self-explained
ARG user=youkaichao
ARG passwd=whateveryoulike

# adjust apt source
# I obtain the sources.list from tuna mirrors: https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
COPY sources.list /etc/apt/

# update package info
RUN apt update

# install sudo/zsh
RUN apt install -y sudo zsh unzip && apt clean

# create a new user, give it sudo, change password
RUN useradd --create-home --shell /bin/bash ${user}
RUN usermod -aG sudo ${user}
RUN echo "${user}:${passwd}" | chpasswd

# copy miniconda install package
COPY Miniconda3.sh /home/${user}/
RUN chmod +x /home/${user}/Miniconda3.sh

# switch to that user
USER ${user}
WORKDIR /home/${user}

RUN /home/${user}/Miniconda3.sh -b -p /home/${user}/miniconda

# prepare ssh
RUN mkdir /home/${user}/.ssh

# trust my computer
COPY id_rsa.pub /home/${user}/.ssh/
USER root
RUN chown ${user} /home/${user}/.ssh/id_rsa.pub
USER ${user}
RUN mv /home/${user}/.ssh/id_rsa.pub /home/${user}/.ssh/authorized_keys
RUN chmod 644 /home/${user}/.ssh/authorized_keys

# setup zsh
COPY ohmyzsh-master.zip /home/${user}/
RUN unzip /home/${user}/ohmyzsh-master.zip -d /home/${user}/ohmyzsh-master
RUN mv /home/${user}/ohmyzsh-master/ohmyzsh-master /home/${user}/.oh-my-zsh/
RUN echo "export ZSH=/home/${user}/.oh-my-zsh/" >> /home/${user}/.bashrc
RUN echo "/bin/zsh" >> /home/${user}/.bashrc
RUN cp /home/${user}/.oh-my-zsh/templates/zshrc.zsh-template /home/${user}/.zshrc

# conda init

RUN /home/${user}/miniconda/bin/conda init zsh
RUN /home/${user}/miniconda/bin/conda init bash

# copy config of conda and pip

# this condarc is copied from https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/
USER root
COPY .condarc /home/${user}/
RUN chown ${user} /home/${user}/.condarc
USER ${user}

COPY pip.conf /etc/

# show some diagnosis info
RUN /home/${user}/miniconda/bin/conda config --show-sources

# use python3.8 which is new enough but not too new to break compatibility of some old software.
RUN /home/${user}/miniconda/bin/conda create -y -n env python=3.8 && /home/${user}/miniconda/bin/conda clean -a -y

# install pytorch, torchvision, and supporting cuda
RUN /home/${user}/miniconda/bin/conda install -n env -y pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia && /home/${user}/miniconda/bin/conda clean -a -y

# install jupyter lab
RUN /home/${user}/miniconda/bin/conda install -n env -y jupyterlab && /home/${user}/miniconda/bin/conda clean -a -y

# install tensorboard
RUN /home/${user}/miniconda/envs/env/bin/pip install tensorboard && rm -rf /home/${user}/.cache/pip

# expose the ssh port
EXPOSE 22

# finally, switch back to root, as is done in common scenarios
USER root

RUN apt install openssh-server openssh-client -y && apt clean
# let sshd config something, like /run/sshd, as mentioned in https://github.com/microsoft/WSL/issues/3621
RUN service ssh start
