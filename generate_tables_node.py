import os
import csv
from collections import OrderedDict

# ===== CONFIG =====

BASE_DIR = "analysis"
NETWORKS = ["BA", "ER", "LFR"]
PERTURBATIONS = ["add", "del", "rewire"]
PS = ["0.05", "0.01"]

ALGORITHMS = OrderedDict({
    "girven_newman": "Girvan--Newman",
    "infomap": "Infomap",
    "leiden": "Leiden",
    "louvain": "Louvain",
    "spectral": "Spectral",
})

# ==================


def latex_escape(text):
    if text is None:
        return ""
    return text.replace("_", "\\_")


def format_value(x, decimals=4):
    try:
        return f"{float(x):.{decimals}f}"
    except Exception:
        return "NA"


def read_node_properties(csv_path, network, algorithm):
    rows = []

    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({
                "Network": latex_escape(network),
                "Algorithm": latex_escape(algorithm),
                "Node": row["node"],
                "Group": latex_escape(row["group"]),
                "degree": row["degree"],
                "betweenness": row["betweenness"],
                "closeness": row["closeness"],
                "eigenvector": row["eigenvector"],
            })

    return rows


def generate_longtable(perturbation, p):
    rows = []

    for network in NETWORKS:
        for alg_dir, alg_name in ALGORITHMS.items():
            csv_path = os.path.join(
                BASE_DIR, network, perturbation, p, alg_dir, "node_properties.csv"
            )

            if not os.path.exists(csv_path):
                raise FileNotFoundError(csv_path)

            rows.extend(read_node_properties(csv_path, network, alg_name))

    tex = []
    tex.append("\\begin{longtable}{lllccccc}")
    tex.append(
        f"\\caption{{Top and bottom changing nodes under edge {perturbation} ($p={p}$).}}"
        f"\\label{{tab:node_{perturbation}_p{p.replace('.', '')}}}\\\\"
    )
    tex.append("\\toprule")
    tex.append(
        "Network & Algorithm & Node & Group & Degree & Betweenness & Closeness & Eigenvector \\\\"
    )
    tex.append("\\midrule")
    tex.append("\\endfirsthead")

    tex.append("\\toprule")
    tex.append(
        "Network & Algorithm & Node & Group & Degree & Betweenness & Closeness & Eigenvector \\\\"
    )
    tex.append("\\midrule")
    tex.append("\\endhead")

    tex.append("\\midrule")
    tex.append("\\multicolumn{8}{r}{\\emph{Continued on next page}} \\\\")
    tex.append("\\endfoot")

    tex.append("\\bottomrule")
    tex.append("\\endlastfoot")

    for r in rows:
        tex.append(
            f"{r['Network']} & {r['Algorithm']} & {r['Node']} & {r['Group']} & "
            f"{format_value(r['degree'])} & "
            f"{format_value(r['betweenness'])} & "
            f"{format_value(r['closeness'])} & "
            f"{format_value(r['eigenvector'])} \\\\"
        )

    tex.append("\\end{longtable}")

    return "\n".join(tex)


# ===== MAIN =====

if __name__ == "__main__":
    os.makedirs("tables_node", exist_ok=True)

    for pert in PERTURBATIONS:
        for p in PS:
            tex = generate_longtable(pert, p)
            filename = f"tables_node/node_{pert}_p{p.replace('.', '')}.tex"
            with open(filename, "w") as f:
                f.write(tex)

            print(f"Generated: {filename}")
