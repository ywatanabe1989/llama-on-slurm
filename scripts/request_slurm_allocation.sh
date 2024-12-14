#!/bin/bash
# Time-stamp: "2024-12-14 16:43:53 (ywatanabe)"
# File: ./llama-on-slurm/scripts/request_slurm_allocation.sh

#SBATCH --job-name=persistent
#SBATCH --ntasks=8
#SBATCH --nodes=8
#SBATCH --tasks-per-node=1
#SBATCH --partition=gpu-a100
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --time=7-00:00:00
#SBATCH --signal=B:USR1@3600

# Parameters
LOS_PRESISTENT_FILE=${LOS_PRESISTENT_FILE:-$LOS_DIR/.persistent_nodes}

_find_available_port() {
    local start_port=$1
    local end_port=$2
    local port

    for port in $(seq $start_port $end_port); do
        if ! netstat -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
    done
    return 1
}

_get_head_node_ip() {
    # Get head node hostname
    head_node=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n1)

    # Get IP address using srun (works across clusters)
    head_node_ip=$(srun --nodes=1 --ntasks=1 -w "$head_node" hostname -i | awk '{print $1}')

    # Find available port
    port=$(_find_available_port 35000 40000)

    echo "$head_node_ip:$port"
}

# Export node information for other scripts to use
echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST" > $LOS_PRESISTENT_FILE
echo "SLURM_JOB_ID=$SLURM_JOB_ID" >> $LOS_PRESISTENT_FILE
echo "SLURM_JOB_HEAD_IP=$(_get_head_node_ip)" >> $LOS_PRESISTENT_FILE
echo "SLURM_NNODES=$SLURM_JOB_NUM_NODES" >> $LOS_PRESISTENT_FILE
echo "SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}" >> $LOS_PRESISTENT_FILE
echo "TIMESTAMP=$(date '+%Y%m%d_%H%M%S')" >> $LOS_PRESISTENT_FILE

# Add job status check
if [ -f $LOS_PRESISTENT_FILE ]; then
    echo "Node information saved at $LOS_PRESISTENT_FILE"
    cat $LOS_PRESISTENT_FILE
fi

# Cleanup on exit
cleanup() {
    rm -f $LOS_PRESISTENT_FILE
}
trap cleanup EXIT

# Auto-resubmit before timeout
resubmit_job() {
    sbatch $0
}
trap 'resubmit_job' USR1

# Keep system alive
while true; do
    sleep 300
done

# sbatch ./scripts/keep_slurm_nodes.sh


# EOF
