def node_change_vector(partition_before, partition_after):
    """
    Compute a binary vector indicating whether each node
    changed its community assignment after perturbation.

    Parameters
    ----------
    partition_before : dict
        Mapping node -> community_id (before)
    partition_after : dict
        Mapping node -> community_id (after)

    Returns
    -------
    change_vector : dict
        Mapping node -> 0 (no change) or 1 (changed)
    """
    change_vector = {}

    for node in partition_before:
        change_vector[node] = int(
            partition_before[node] != partition_after[node]
        )

    return change_vector


def node_reassignment_rate(partition_before, partition_after):
    """
    Compute the fraction of nodes that changed community
    assignment after perturbation.

    Parameters
    ----------
    partition_before : dict
        Mapping node -> community_id (before)
    partition_after : dict
        Mapping node -> community_id (after)

    Returns
    -------
    rate : float
        Fraction of nodes that changed community
    """
    changes = node_change_vector(partition_before, partition_after)
    return sum(changes.values()) / len(changes)
