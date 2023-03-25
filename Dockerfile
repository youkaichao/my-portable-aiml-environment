# base image, I choose a ubuntu 18.04 image which is new enough but not too new to break compatibility of some old software.
# you can switch to another image if you like, or switch to an internal docker-hub image if you do not have internet access.
FROM ubuntu:18.04

# use bash for the support of `source` command, and `-l` option to automatic source bash profile
SHELL [ "/bin/bash", "-l", "-c"]

# your username and password, they are self-explained
# HOST_ENDPOINT is used to download installers from host machine, and then delete it in the same RUN command
ARG user=youkaichao
ARG passwd=whateveryoulike
ARG HOST_ENDPOINT=http://host.docker.internal:8080

RUN echo "adjust apt source, update" && \
    wget ${HOST_ENDPOINT}/sources.list -O /etc/apt/sources.list && apt update && \
    echo "install sudo/zsh" && \
    apt install -y sudo zsh unzip && \
    echo "install ssh, let sshd config something, like /run/sshd, as mentioned in https://github.com/microsoft/WSL/issues/3621" && \
    apt install openssh-server openssh-client -y && service ssh start && \
    echo "MLNX OFED support (for distributed training with RDMA)" && \
    wget ${HOST_ENDPOINT}/MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64.tgz -O /MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64.tgz && \
    tar xvfz /MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64.tgz && \
    /MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64/mlnxofedinstall --without-fw-update --user-space-only --all --force --without-neohost-backend --without-neohost-sdk --without-openmpi --with-nvmf --with-nfsrdma && \
    rm -rf /MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64 && \
    rm /MLNX_OFED_LINUX-5.4-3.6.8.1-ubuntu18.04-x86_64.tgz && \
    echo "clean apt" && \
    apt clean && \
    echo "add pip config" && \
    wget ${HOST_ENDPOINT}/pip.conf -O /etc/pip.conf && \
    echo "create a new user, give it sudo, change password" && \
    useradd --create-home --shell /bin/bash ${user} && usermod -aG sudo ${user} && echo "${user}:${passwd}" | chpasswd

# expose the ssh port
EXPOSE 22

# switch to that user
USER ${user}
WORKDIR /home/${user}

RUN echo "install miniconda" && \
    wget ${HOST_ENDPOINT}/Miniconda3.sh -O /home/${user}/Miniconda3.sh && chmod +x /home/${user}/Miniconda3.sh && /home/${user}/Miniconda3.sh -b -p /home/${user}/miniconda && rm /home/${user}/Miniconda3.sh && \
    echo "prepare ssh and trust my computer" && \
    mkdir /home/${user}/.ssh && wget ${HOST_ENDPOINT}/id_rsa.pub -O /home/${user}/.ssh/authorized_keys && chmod 644 /home/${user}/.ssh/authorized_keys && \
    echo "setup zsh" && \
    wget ${HOST_ENDPOINT}/ohmyzsh-master.zip -O /home/${user}/ohmyzsh-master.zip && unzip /home/${user}/ohmyzsh-master.zip -d /home/${user}/ohmyzsh-master && mv /home/${user}/ohmyzsh-master/ohmyzsh-master /home/${user}/.oh-my-zsh/ && echo "export ZSH=/home/${user}/.oh-my-zsh/" >> /home/${user}/.bashrc && echo "/bin/zsh" >> /home/${user}/.bashrc && cp /home/${user}/.oh-my-zsh/templates/zshrc.zsh-template /home/${user}/.zshrc && rm /home/${user}/ohmyzsh-master.zip && rm -rf /home/${user}/ohmyzsh-master && \
    echo "conda init" && \
    /home/${user}/miniconda/bin/conda init zsh && /home/${user}/miniconda/bin/conda init bash && \
    echo "copy config of conda and pip" && \
    wget ${HOST_ENDPOINT}/.condarc -O /home/${user}/.condarc && \
    echo "show some diagnosis info" && \
    /home/${user}/miniconda/bin/conda config --show-sources && \
    echo "create env by conda. use python3.8 which is new enough but not too new to break compatibility of some old software." && \
    /home/${user}/miniconda/bin/conda create -y -n env python=3.8 && \
    echo "install pytorch, torchvision, and supporting cuda" && \
    /home/${user}/miniconda/bin/conda install -n env -y pytorch=1.13 torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia && \
    echo "install jupyter lab" && \
    /home/${user}/miniconda/bin/conda install -n env -y jupyterlab && \
    echo "clean conda" && \
    /home/${user}/miniconda/bin/conda clean -a -y && \
    echo "install tensorboard via pip" && \
    /home/${user}/miniconda/envs/env/bin/pip install tensorboard && \
    echo "copy mmcv wheel" && \
    wget ${HOST_ENDPOINT}/mmcv_full-1.7.0-cp38-cp38-manylinux1_x86_64.whl -O /home/${user}/mmcv_full-1.7.0-cp38-cp38-manylinux1_x86_64.whl && \
    echo "instal openmmlab series" && \
    /home/${user}/miniconda/envs/env/bin/pip install /home/${user}/mmcv_full-1.7.0-cp38-cp38-manylinux1_x86_64.whl && \
    /home/${user}/miniconda/envs/env/bin/pip install mmdet mmcls && \
    echo "uninstall opencv and install opencv headless for servers" && \
    /home/${user}/miniconda/envs/env/bin/pip uninstall -y opencv-python && /home/${user}/miniconda/envs/env/bin/pip install opencv-python-headless && \
    echo "clean pip" && \
    rm -rf /home/${user}/.cache/pip

# finally, switch back to root, as is done in common scenarios
USER root

# not sure if it works, sometimes changing password in Dockerfile does work
RUN echo "${user}:${passwd}" | chpasswd
