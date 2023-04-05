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

If you want to test the bandwidth of RDMA:

1. Find a machine to be master, and use `hostname -I | awk '{print $1}'` to find its IP.
2. Execute the following command in each machine, with the node-rank changed to an index starting from 0. (The master machine should have node-rank of 0.)

```
export NCCL_IB_GID_INDEX=`show_gids | grep -i v2 | tail -1 | awk '{print $3}'`
export N_NODES=2
export nproc_per_node=8
export MASTER_ADDR=xxx
export NODE_RANK=0
export NCCL_DEBUG=INFO
export UCX_LOG_LEVEL=debug
export MASTER_PORT=12345

echo node rank $NODE_RANK, master at $MASTER_ADDR:$MASTER_PORT

/home/youkaichao/miniconda/envs/env/bin/torchrun --nnodes=$N_NODES --nproc_per_node=$nproc_per_node --node_rank=$NODE_RANK --master_addr=$MASTER_ADDR --master_port=$MASTER_PORT test_rdma.py
```

You should see detailed log from NCCL, and an estimated bandwith in the unit of Gbps.

An example of output (for only the process with local_rank of 0) is shown below:

```
lsp-ws1:7650:7650 [0] NCCL INFO Bootstrap : Using eth0:10.168.3.28<0>
lsp-ws1:7650:7650 [0] NCCL INFO NET/Plugin : No plugin found (libnccl-net.so), using internal implementation
lsp-ws1:7650:7650 [0] NCCL INFO cudaDriverVersion 11040
lsp-ws1:7650:7708 [0] NCCL INFO NET/IB : No device found.
lsp-ws1:7650:7708 [0] NCCL INFO NET/Socket : Using [0]eth0:10.168.3.28<0> [1]eth1:10.168.3.28<0>
lsp-ws1:7650:7708 [0] NCCL INFO Using network Socket
lsp-ws1:7650:7708 [0] NCCL INFO Setting affinity for GPU 0 to ffffffff,00000000,ffffffff
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/02 :    0   7   6   5   4   3   2   1   8  15  14  13  12  11  10   9
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/02 :    0   7   6   5   4   3   2   1   8  15  14  13  12  11  10   9
lsp-ws1:7650:7708 [0] NCCL INFO Trees [0] 1/8/-1->0->-1 [1] 1/-1/-1->0->8
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/0 : 9[51000] -> 0[4b000] [receive] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/0 : 9[51000] -> 0[4b000] [receive] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/0 : 0[4b000] -> 7[cf000] via P2P/IPC/read
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/0 : 0[4b000] -> 7[cf000] via P2P/IPC/read
lsp-ws1:7650:7708 [0] NCCL INFO Connected all rings
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/0 : 0[4b000] -> 1[51000] via P2P/IPC/read
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/0 : 0[4b000] -> 1[51000] via P2P/IPC/read
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/0 : 8[4b000] -> 0[4b000] [receive] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/0 : 8[4b000] -> 0[4b000] [receive] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Channel 00/0 : 0[4b000] -> 8[4b000] [send] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Channel 01/0 : 0[4b000] -> 8[4b000] [send] via NET/Socket/0
lsp-ws1:7650:7708 [0] NCCL INFO Connected all trees
lsp-ws1:7650:7708 [0] NCCL INFO threadThresholds 8/8/64 | 128/8/64 | 512 | 512
lsp-ws1:7650:7708 [0] NCCL INFO 2 coll channels, 2 p2p channels, 2 p2p channels per peer
lsp-ws1:7650:7708 [0] NCCL INFO comm 0x37c6a330 rank 0 nranks 16 cudaDev 0 busId 4b000 - Init COMPLETE
time spent for each trial: 1.650430393218994
param all-reduce speed: 2.4236102391439927 GB/s
communication bandwidth (estimated): 38.77776382630388 Gb/s
answer: 7864320.0
lsp-ws1:7650:7729 [0] NCCL INFO [Service thread] Connection closed by localRank 0
lsp-ws1:7655:7655 [0] NCCL INFO comm 0x4d2d12d0 rank 5 nranks 16 cudaDev 5 busId 92000 - Abort COMPLETE
lsp-ws1:7650:7650 [0] NCCL INFO comm 0x37c6a330 rank 0 nranks 16 cudaDev 0 busId 4b000 - Abort COMPLETE
lsp-ws1:7653:7653 [0] NCCL INFO comm 0x4b0155b0 rank 3 nranks 16 cudaDev 3 busId 6f000 - Abort COMPLETE
lsp-ws1:7654:7654 [0] NCCL INFO comm 0x4a488b20 rank 4 nranks 16 cudaDev 4 busId 8d000 - Abort COMPLETE
lsp-ws1:7652:7652 [0] NCCL INFO comm 0x4caa9e20 rank 2 nranks 16 cudaDev 2 busId 6a000 - Abort COMPLETE
lsp-ws1:7651:7651 [0] NCCL INFO comm 0x4ab5f330 rank 1 nranks 16 cudaDev 1 busId 51000 - Abort COMPLETE
lsp-ws1:7657:7657 [0] NCCL INFO comm 0x4bbd4880 rank 7 nranks 16 cudaDev 7 busId cf000 - Abort COMPLETE
lsp-ws1:7656:7656 [0] NCCL INFO comm 0x4afb1b30 rank 6 nranks 16 cudaDev 6 busId c9000 - Abort COMPLETE
```

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
