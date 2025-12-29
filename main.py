import os
import pickle

from networks.generators import (
    generate_er,
    generate_ba,
    generate_lfr
)

from perturbations.edge_deletion import edge_deletion
from perturbations.edge_rewiring import edge_rewiring
from perturbations.edge_addition import edge_addition

from utils.export_csv import (
    save_graph_to_csv,
    save_lfr_ground_truth_to_csv
)

# Global experiment parameters
SEED = 42
FRACTIONS = [0.01, 0.02, 0.05]


def save_graph_pickle(G, path):
    with open(path, "wb") as f:
        pickle.dump(G, f)


def main():

    # 1. GENERATE BASE NETWORKS

    G_er = generate_er(n=500, p=0.01, seed=SEED)
    G_ba = generate_ba(n=500, m=3, seed=SEED)
    G_lfr, ground_truth = generate_lfr(
        n=500,
        tau1=3,
        tau2=1.5,
        mu=0.1,
        avg_degree=10,
        max_degree=50,
        seed=SEED
    )

    print("ER edges:", G_er.number_of_edges())
    print("BA edges:", G_ba.number_of_edges())
    print("LFR edges:", G_lfr.number_of_edges())
    print("LFR communities:", len(set(ground_truth.values())))

    base_graphs = {
        "er": G_er,
        "ba": G_ba,
        "lfr": G_lfr
    }

    # 2. SAVE BASE NETWORKS

    for name, G in base_graphs.items():
        graph_dir = os.path.join("data", "base", name)
        os.makedirs(graph_dir, exist_ok=True)

        save_graph_pickle(G, os.path.join(graph_dir, f"{name}_graph.gpickle"))
        save_graph_to_csv(G, prefix=name, output_dir=graph_dir)

    save_lfr_ground_truth_to_csv(
        ground_truth,
        output_dir=os.path.join("data", "base", "lfr")
    )

    # 3. EDGE DELETION

    for graph_name, G in base_graphs.items():
        for fraction in FRACTIONS:

            label = f"del_{int(fraction * 100):02d}"
            out = os.path.join("data", "edge_deletion", graph_name, label)
            os.makedirs(out, exist_ok=True)

            G_del = edge_deletion(G, fraction, seed=SEED)

            print(
                f"{graph_name.upper()} | deletion {fraction:.0%} | "
                f"{G.number_of_edges()} -> {G_del.number_of_edges()}"
            )

            save_graph_pickle(
                G_del,
                os.path.join(out, f"{graph_name}_{label}_graph.gpickle")
            )
            save_graph_to_csv(G_del, prefix=f"{graph_name}_{label}", output_dir=out)

    # 4. EDGE REWIRING

    for graph_name, G in base_graphs.items():
        for fraction in FRACTIONS:

            label = f"rew_{int(fraction * 100):02d}"
            out = os.path.join("data", "edge_rewiring", graph_name, label)
            os.makedirs(out, exist_ok=True)

            G_rew = edge_rewiring(G, fraction, seed=SEED)

            print(
                f"{graph_name.upper()} | rewiring {fraction:.0%} | "
                f"{G.number_of_edges()} -> {G_rew.number_of_edges()}"
            )

            save_graph_pickle(
                G_rew,
                os.path.join(out, f"{graph_name}_{label}_graph.gpickle")
            )
            save_graph_to_csv(G_rew, prefix=f"{graph_name}_{label}", output_dir=out)

    # 5. EDGE ADDITION


    for graph_name, G in base_graphs.items():
        for fraction in FRACTIONS:

            label = f"add_{int(fraction * 100):02d}"
            out = os.path.join("data", "edge_addition", graph_name, label)
            os.makedirs(out, exist_ok=True)

            G_add = edge_addition(G, fraction, seed=SEED)

            print(
                f"{graph_name.upper()} | addition {fraction:.0%} | "
                f"{G.number_of_edges()} -> {G_add.number_of_edges()}"
            )

            save_graph_pickle(
                G_add,
                os.path.join(out, f"{graph_name}_{label}_graph.gpickle")
            )
            save_graph_to_csv(G_add, prefix=f"{graph_name}_{label}", output_dir=out)

    print("\nAll base graphs and all perturbations saved successfully.")


if __name__ == "__main__":
    main()
