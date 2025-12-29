import random
import networkx as nx


def edge_deletion(G, fraction, seed=None):
    """
    Randomly delete a fraction of edges from a graph.

    Parameters
    ----------
    G : networkx.Graph
        Original graph 
    fraction : float
        Fraction of edges to delete (0 < fraction < 1)
    seed : int or None
        Random seed

    Returns
    -------
    G_perturbed : networkx.Graph
        Graph after edge deletion
    """

    if not 0 < fraction < 1:
        raise ValueError("fraction must be between 0 and 1")

    if seed is not None:
        random.seed(seed)

    # Copy graph to avoid side effects
    G_perturbed = G.copy()

    edges = list(G_perturbed.edges())
    num_edges = len(edges)
    num_to_delete = int(fraction * num_edges)

    if num_to_delete == 0:
        return G_perturbed

    edges_to_delete = random.sample(edges, num_to_delete)
    G_perturbed.remove_edges_from(edges_to_delete)

    return G_perturbed
