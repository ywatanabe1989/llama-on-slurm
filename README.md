# LLaMA on Slurm

Distributed LLaMA model inference on Slurm clusters. 

## Installation
<details>
<summary>Details</summary>

#### Environment variables
```bash
export LOS_DIR=~/proj/llama-on-slurm # /path/to/this/repository
export LOS_META_DIR=$LOS_DIR/llama-models
export LOS_META_CHECKPOINT_DIR=$LOS_META_DIR/.llama/checkpoints/Llama3.3-70B-Instruct # Adjust this
export LOS_PYTHON_SCRIPT=$LOS_META_DIR/models/scripts/example_chat_completion.py # Adjust this
export LOS_PYTHON_ENV=$LOS_META_DIR/.env
```

#### Clone Repositories
``` bash
git clone git@github.com:ywatanabe1989/llama-on-slurm $LOS_DIR
git clone git@github.com:meta-llama/llama-models.git $LOS_META_DIR
```

#### Python Environment

``` bash
# Cleanup when necessary
deactivate 2>&1 >/dev/null
rm $LOS_PYTHON_ENV -rf 2>&1 >/dev/null

# Module control
module purge
module load GCCcore Python

# Main
python3 -m venv $LOS_PYTHON_ENV --clear
source $LOS_PYTHON_ENV/bin/activate

# Force pip to only use the venv
python3 -m pip install --ignore-installed --no-cache-dir -U pip
python3 -m pip install --ignore-installed --no-cache-dir -Ur requirements.txt
```

#### Download pretrained Llama models

``` bash
# Follow the instruction of Meta `https://github.com/meta-llama/llama-models` and download a model to `$LOS_META_CHECKPOINT_DIR`

# Example:
echo $LOS_META_CHECKPOINT_DIR
# /home/ywatanabe/proj/llama-on-slurm/llama-models/.llama/checkpoints/Llama3.3-70B-Instruct
ls $LOS_META_CHECKPOINT_DIR -L
# checklist.chk        consolidated.02.pth  consolidated.05.pth  params.json
# consolidated.00.pth  consolidated.03.pth  consolidated.06.pth  tokenizer.model
# consolidated.01.pth  consolidated.04.pth  consolidated.07.pth
```

#### Adjust the SBATCH parameters in $LOS_DIR/scripts/request_slurm_allocation.sh
```bash
#SBATCH --job-name=llama-persistent
#SBATCH --ntasks=8
#SBATCH --nodes=8
#SBATCH --tasks-per-node=1
#SBATCH --partition=gpu-a100
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --time=7-00:00:00
#SBATCH --signal=B:USR1@3600
```
</details>

## Usage

The workflow consists of two steps: (1) requesting GPU allocation and (2) attaching to run inference. See [./docs/log.txt](./docs/log.txt) for example output.

```bash
# Request allocation
sbatch $LOS_DIR/scripts/request_slurm_allocation.sh

# Attach and run inference
$LOS_DIR/scripts/attach_llama_job.sh
```

## Contact
ywatanabe@alumni.u-tokyo.ac.jp
