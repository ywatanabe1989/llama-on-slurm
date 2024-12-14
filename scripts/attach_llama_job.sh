#!/bin/bash
# Time-stamp: "2024-12-14 17:29:18 (ywatanabe)"
# File: ./llama-on-slurm/scripts/attach_llama_job.sh

# Parameters
LOS_PRESISTENT_FILE=${LOS_PRESISTENT_FILE:-$LOS_DIR/.persistent_nodes}

################################################################################
# Functions
################################################################################
_parse_persistent_info() {
    if [[ ! -f "$LOS_PRESISTENT_FILE" ]]; then
        echo "Error: Info file not found at $LOS_PRESISTENT_FILE" >&2
        exit 1
    fi
    eval $(cat "$LOS_PRESISTENT_FILE" | xargs -I {} echo "export {}")
}

_setup_master_address() {
    MASTER_ADDR=$(echo $SLURM_JOB_HEAD_IP | cut -d: -f1)
    MASTER_PORT=$(echo $SLURM_JOB_HEAD_IP | cut -d: -f2)
    export MASTER_ADDR MASTER_PORT
}

################################################################################
# Main
################################################################################
# Parse persistent node information
_parse_persistent_info

# Setup master address
_setup_master_address

# # Load modules
# module load GCCcore/11.3.0 Python/3.10.4

# Activate Python Env.
source $LOS_META_DIR/.env/bin/activate

# Run the distributed training
PYTHONPATH=$LOS_META_DIR:$PYTHONPATH \
    srun \
    --jobid=$SLURM_JOB_ID \
    --nodes=$SLURM_NNODES \
    --ntasks=$SLURM_NNODES \
    --mem=32GB \
    --export=ALL,MASTER_ADDR=$MASTER_ADDR,MASTER_PORT=$MASTER_PORT \
    torchrun \
    --nnodes=$SLURM_NNODES \
    --nproc_per_node=1 \
    --rdzv_id ${SLURM_JOB_ID} \
    --rdzv_backend c10d \
    --rdzv_endpoint "$MASTER_ADDR:$MASTER_PORT" \
    $LOS_PYTHON_SCRIPT \
    $LOS_META_CHECKPOINT_DIR

# EOF
