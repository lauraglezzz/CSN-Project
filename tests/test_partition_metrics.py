from metrics.partition_metrics import (
    compute_nmi,
    compute_ami,
    compute_ari
)

# Fake partitions (simple and controlled)
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
    3: 1
}

nmi = compute_nmi(partition_before, partition_after)
ami = compute_ami(partition_before, partition_after)
ari = compute_ari(partition_before, partition_after)

print("NMI:", nmi)
print("AMI:", ami)
print("ARI:", ari)
