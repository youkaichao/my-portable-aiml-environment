# my-portable-aiml-environment
A Dockerfile to build my portable environment for AI/ML development, with some daily used packages!

The docker image contains:

- GPU support
- jupyter lab/notebook interactive programming based on web UI
- tensorboard visualization
- full-stack ssh capacity
- latest pytorch environment (1.13) with miniconda support
- OpenMMLab MMCV(1.7)/MMDetection/MMClassification support
- MLNX OFED support (version 5.4 for distributed training with RDMA)
- Deepspeed with Huggingface Transformers/Datasets/Accelerate

# Clone this repo (in your laptop) and send necessary files to the machine to build docker:

```bash
git clone https://github.com/youkaichao/my-portable-aiml-environment
cd my-portable-aiml-environment
wget https://mirrors.bfsu.edu.cn/anaconda/miniconda/Miniconda3-py38_23.1.0-1-Linux-x86_64.sh -O Miniconda3.sh
cp ~/.ssh/id_rsa.pub id_rsa.pub
wget https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.zip -O ohmyzsh-master.zip
wget https://download.openmmlab.com/mmcv/dist/cu117/torch1.13.0/mmcv_full-1.7.0-cp38-cp38-manylinux1_x86_64.whl
# download MLNX OFED installer from https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/
# download cuda toolkit dev from https://developer.nvidia.com/cuda-11-7-0-download-archive (installer type: runfile, local)
cd ..
scp -r my-portable-aiml-environment your@machine:/path
```

Note: You can also download files from my Tsinghua Cloud Storage at https://cloud.tsinghua.edu.cn/d/d6527e7e16714f189b67/ .

# Go to The Linux Machine to Install Docker
Command from https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/ :
```bash
export DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
wget -O- https://get.docker.com/ | sh
```
Make sure you are root user.

Check `service docker status` to see if docker is running. If not, run `service docker start`.

# Run docker build in that Linux Machine

In a separate terminal, serve installer files by `python3 -m http.server 8080`.

```bash
export user=youkaichao
export passwd=whatispass
export HOST_IP=$(hostname -I | awk '{print $1}')
export HOST_PORT=8080
docker build --build-arg user=$user --build-arg passwd=$passwd --build-arg HOST_ENDPOINT=$HOST_IP:$HOST_PORT --progress=plain --tag youkaichao/pytorch113_cu117_ubuntu2004:openmmlab-ofed-deepspeed .
```

# Push the image to cloud in that Linux Machine

```bash
docker login
docker push youkaichao/pytorch113_cu117_ubuntu2004:openmmlab-ofed-deepspeed
```

# Try that image

Install the container runtime for GPU, follow the guide at https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html .

Run the image in a container:

`docker compose up`

In a separated shell, try:

`ssh $user@127.0.0.1 -P 3232`

And you should log in with a ZSH shell! Try `nvidia-smi` to see the GPU, and `conda activate env && python -c "from mmdet.apis import init_random_seed, set_random_seed, train_detector; import torch; a=torch.randn(500, 500).cuda(); b=a.max(); print(b)"` to see that GPU is enabled!

Sometimes the password is not set correctly. You can also use `docker exec -it container_id /bin/bash` to attach to that image.

# RDMA support

Note: To test RDMA support, use `show_gids` to see RDMA devices. If the output is not empty, then RDMA support is on!

# DeepSpeed support

To use DeepSpeed, you may set the following environment variables:
```
export CUDA_HOME=/home/youkaichao/cuda/
export PATH=$PATH:/home/youkaichao/cuda/bin
deepspeed --help
```

# Note for usage in internal environment (e.g. inside a company without network acess)

If you are working inside a company, and the computer has no access to the internet, you can replace files in `sources.list`, `pip.conf`, `.condarc` with the apt-source/pip index/conda channel in your company.

As for the Miniconda/Zsh files, just download them with your laptop and upload the machine to build the docker image (or just build the docker image with your laptop).

# Note

If you don't want to build the image yourself, you can also use the image I have built: `youkaichao/pytorch113_cu117_ubuntu2004:openmmlab-ofed-deepspeed`. Since it contains my public key, if you don't want me to be able to log in to your server, remember to delete the public key in it: /home/youkaichao/.ssh/authorized_keys.

For a typical image to train models, oh-my-zsh and tensorboard/jupyterlab are not necessary. Feel free to change the Dockerfile to fit your need!

# Done!

Happy Coding, Happy Life! No more environment setup for every machine!
