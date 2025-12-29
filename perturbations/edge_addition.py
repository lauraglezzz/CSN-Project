import random


def edge_addition(G, fraction, seed=None):
    """
    Randomly add a fraction of new edges to a graph.

    Parameters
    ----------
    G : networkx.Graph
        Original graph 
    fraction : float
        Fraction of edges to add (0 < fraction < 1),
        relative to the original number of edges
    seed : int or None
        Random seed

    Returns
    -------
    G_perturbed : networkx.Graph
        Graph after edge addition
    """

    if not 0 < fraction < 1:
        raise ValueError("fraction must be between 0 and 1")

    if seed is not None:
        random.seed(seed)

    G_perturbed = G.copy()

    num_edges = G.number_of_edges()
    num_to_add = int(fraction * num_edges)

    nodes = list(G_perturbed.nodes())
    added = 0

    while added < num_to_add:
        u, v = random.sample(nodes, 2)

        # Avoid self-loops and multi-edges
        if u == v or G_perturbed.has_edge(u, v):
            continue

        G_perturbed.add_edge(u, v)
        added += 1

    return G_perturbed
