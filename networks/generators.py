import networkx as nx
import random


def generate_er(n, p, seed=None):
    """Erdős–Rényi random graph"""
    return nx.erdos_renyi_graph(n=n, p=p, seed=seed)


def generate_ba(n, m, seed=None):
    """Barabási–Albert scale-free network"""
    return nx.barabasi_albert_graph(n=n, m=m, seed=seed)


def generate_lfr(
    n,
    tau1,
    tau2,
    mu,
    avg_degree,
    max_degree,
    seed=None
):
    """LFR benchmark graph with ground-truth communities"""

    if seed is not None:
        random.seed(seed)

    G = nx.LFR_benchmark_graph(
        n=n,
        tau1=tau1,
        tau2=tau2,
        mu=mu,
        average_degree=avg_degree,
        max_degree=max_degree,
        seed=seed
    )

    # Clean graph
    G = nx.Graph(G)
    G.remove_edges_from(nx.selfloop_edges(G))

    # Extract ground truth
    ground_truth = {
        node: list(data["community"])[0]
        for node, data in G.nodes(data=True)
    }

    return G, ground_truth
