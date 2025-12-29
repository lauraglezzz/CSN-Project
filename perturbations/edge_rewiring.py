import random


def edge_rewiring(G, fraction, seed=None):
    """
    Randomly rewire a fraction of edges in a graph.
    Each rewired edge is removed and replaced by a new edge
    between two randomly selected nodes.

    Parameters
    ----------
    G : networkx.Graph
        Original graph 
    fraction : float
        Fraction of edges to rewire (0 < fraction < 1)
    seed : int or None
        Random seed

    Returns
    -------
    G_perturbed : networkx.Graph
        Graph after edge rewiring
    """

    if not 0 < fraction < 1:
        raise ValueError("fraction must be between 0 and 1")

    if seed is not None:
        random.seed(seed)

    # Copy graph to avoid side effects
    G_perturbed = G.copy()

    edges = list(G_perturbed.edges())
    num_edges = len(edges)
    num_to_rewire = int(fraction * num_edges)

    if num_to_rewire == 0:
        return G_perturbed

    nodes = list(G_perturbed.nodes())

    rewired = 0
    used_edges = set(edges)

    while rewired < num_to_rewire:
        # Pick an existing edge to remove
        u, v = random.choice(edges)

        if not G_perturbed.has_edge(u, v):
            continue

        # Pick two random nodes for the new edge
        a, b = random.sample(nodes, 2)

        # Avoid self-loops and multi-edges
        if a == b or G_perturbed.has_edge(a, b):
            continue

        # Perform rewiring
        G_perturbed.remove_edge(u, v)
        G_perturbed.add_edge(a, b)

        rewired += 1

    return G_perturbed
