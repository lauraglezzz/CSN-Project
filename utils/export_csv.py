import csv
import os


def save_graph_to_csv(G, prefix, output_dir="data"):
    """Save nodes and edges of a graph to CSV"""
    os.makedirs(output_dir, exist_ok=True)

    nodes_path = os.path.join(output_dir, f"{prefix}_nodes.csv")
    edges_path = os.path.join(output_dir, f"{prefix}_edges.csv")

    with open(nodes_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["node_id"])
        for node in G.nodes():
            writer.writerow([node])

    with open(edges_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["source", "target"])
        for u, v in G.edges():
            writer.writerow([u, v])


def save_lfr_ground_truth_to_csv(ground_truth, output_dir="data"):
    """Save LFR ground-truth communities to CSV"""
    path = os.path.join(output_dir, "lfr_ground_truth.csv")

    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["node_id", "community"])
        for node, comm in ground_truth.items():
            writer.writerow([node, comm])
