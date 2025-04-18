import os
import torch
import time
import torch.distributed as dist

local_rank = os.environ['LOCAL_RANK']
rank = os.environ['RANK']
print(f'global rank {rank}, local rank {local_rank}')
device = torch.device(f'cuda:{int(local_rank)}')

torch.distributed.init_process_group('gloo')
world_size = torch.distributed.get_world_size()
nccl_group = torch.distributed.new_group(ranks=list(range(world_size)), backend="nccl")

# warmup dist
for i in range(10):
    tensor = torch.ones((1000, 2), device=device, dtype=torch.float) * int(rank)
    dist.all_reduce(tensor, op=dist.ReduceOp.SUM, group=nccl_group)

torch.cuda.synchronize()

# test dist
tensor = torch.ones((1000, 1000, 1000), device=device, dtype=torch.float) * int(rank)
torch.cuda.synchronize()
torch.distributed.barrier()
now = time.time()
N = 5
for i in range(N):
    dist.all_reduce(tensor, op=dist.ReduceOp.SUM, group=nccl_group)
torch.cuda.synchronize()
torch.distributed.barrier()
elapsed = time.time() - now
time_spent = elapsed / N
speed = 4 / time_spent
print(f'time spent for each trial: {time_spent}')
print(f'param all-reduce speed: {speed} GB/s')
print(f'communication bandwidth (estimated): {speed * 2 * 8} Gb/s')
print(f'answer: {tensor.mean().item()}')
