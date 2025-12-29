from metrics.node_metrics import (
    node_change_vector,
    node_reassignment_rate
)

partition_before = {
    0: 0,
    1: 0,
    2: 1,
    3: 1
}

partition_after = {
    0: 0,
    1: 1,
    2: 1,
    3: 0
}

print("Change vector:", node_change_vector(partition_before, partition_after))
print("Reassignment rate:", node_reassignment_rate(partition_before, partition_after))
