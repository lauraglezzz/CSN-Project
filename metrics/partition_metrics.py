from sklearn.metrics import normalized_mutual_info_score, adjusted_rand_score


def _partition_dict_to_labels(partition):
    """
    Convert a partition dictionary {node: community_id}
    into a list of labels ordered by node id.

    Parameters
    ----------
    partition : dict
        Mapping node -> community_id

    Returns
    -------
    labels : list
        Community labels ordered by sorted node ids
    """
    nodes = sorted(partition.keys())
    labels = [partition[node] for node in nodes]
    return labels


def compute_nmi(partition_before, partition_after):
    """
    Compute Normalized Mutual Information (NMI)
    between two partitions.

    Parameters
    ----------
    partition_before : dict
        Mapping node -> community_id (before perturbation)
    partition_after : dict
        Mapping node -> community_id (after perturbation)

    Returns
    -------
    nmi : float
        Normalized Mutual Information score
    """
    labels_before = _partition_dict_to_labels(partition_before)
    labels_after = _partition_dict_to_labels(partition_after)

    return normalized_mutual_info_score(labels_before, labels_after)


def compute_ari(partition_before, partition_after):
    """
    Compute Adjusted Rand Index (ARI)
    between two partitions.

    Parameters
    ----------
    partition_before : dict
        Mapping node -> community_id (before perturbation)
    partition_after : dict
        Mapping node -> community_id (after perturbation)

    Returns
    -------
    ari : float
        Adjusted Rand Index score
    """
    labels_before = _partition_dict_to_labels(partition_before)
    labels_after = _partition_dict_to_labels(partition_after)

    return adjusted_rand_score(labels_before, labels_after)
