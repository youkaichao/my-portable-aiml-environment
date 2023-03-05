# my-portable-aiml-environment
A dockerfile to build my portable environment for AI/ML development, with some daily used packags!

# Clone this repo:

```bash
git clone git@github.com:youkaichao/my-portable-aiml-environment.git
cd my-portable-aiml-environment
```

# Install Docker
Command from https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/ :
```bash
export DOWNLOAD_URL="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
wget -O- https://get.docker.com/ | sh
```
Make sure you are root user.

Check `service docker status` to see if docker is running. If not, run `service docker start`.

# To download some packages:

Mainly download miniconda, oh-my-zsh, and copy public key.

```bash
mkdir docker_build && cd docker_build
wget https://mirrors.bfsu.edu.cn/anaconda/miniconda/Miniconda3-py38_23.1.0-1-Linux-x86_64.sh -O Miniconda3.sh
cp ~/.ssh/id_rsa.pub id_rsa.pub
wget https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.zip -O ohmyzsh-master.zip
```

# Run docker build

```bash
export user=name
export passwd=yourpass
docker build --build-arg user=$user --build-arg passwd=$passwd --progress=plain --tag $user/pytorch113_cu117_ubuntu1804:slim .
```

# Try that image

Install the container runtime for GPU, follow the guide at https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html .

Run the image in a container:

`docker compose up`

In a seperated shell, try:

`ssh $user@127.0.0.1 -P 3232`

And you should log in with a ZSH shell! Try `nvidia-smi` to see the GPU, and `conda activate env && python -c "import torch; a=torch.randn(500, 500).cuda(); b=a.max(); print(b)"` to see that GPU is enabled!

# Push the image to cloud

```bash
docker login docker.io
docker push $user/pytorch113_cu117_ubuntu1804:slim
```

# Note for usage in internal environment (e.g. inside a company without network acess)

If you are working inside a company, and the computer has no access to the internet, you can replace files in `sources.list`, `pip.conf`, `.condarc` with the apt-source/pip index/conda channel in your company.

As for the Miniconda/Zsh files, just download them with your laptop and upload the machine to build the docker image (or just build the docker image with your laptop).

# Note

If you don't want to build the image yourself, you can also use the image I have built: `docker pull youkaichao/pytorch113_cu117_ubuntu1804:slim`. Since it contains my public key, if you don't want me to be able to log in to your server, remember to delete the public key in it: /home/youkaichao/.ssh/authorized_keys.

# Done!

Happy Coding, Happy Life! No more environment setup for every machine!
