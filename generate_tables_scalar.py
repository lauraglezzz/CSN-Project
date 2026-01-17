import os
import csv
from collections import OrderedDict

# ===== CONFIG =====

BASE_DIR = "results"   # carpeta raíz (la del ZIP descomprimido)
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

METRICS = [
    "NMI",
    "ARI",
    "AMI",
    "NID",
    "Jaccard",
    "proportion.moved",
]

# ==================


def format_value(x, decimals=4):
    """
    Safely format numeric values to a fixed number of decimals.
    Keeps NA or non-numeric values unchanged.
    """
    if x is None:
        return "NA"
    try:
        return f"{float(x):.{decimals}f}"
    except ValueError:
        return x


def read_means(csv_path):
    """
    Reads scalar_metrics.csv and returns {metric: mean}
    """
    values = {}
    with open(csv_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            metric = row["metric"]
            if metric in METRICS:
                values[metric] = row["mean"]
    return values


def generate_table(perturbation, p):
    rows = []

    for network in NETWORKS:
        for alg_dir, alg_name in ALGORITHMS.items():
            csv_path = os.path.join(
                BASE_DIR,
                network,
                perturbation,
                p,
                alg_dir,
                "scalar_metrics.csv"
            )

            if not os.path.exists(csv_path):
                raise FileNotFoundError(csv_path)

            means = read_means(csv_path)

            rows.append({
                "Network": network,
                "Algorithm": alg_name,
                **means
            })

    # ----- LaTeX -----

    tex = []
    tex.append("\\begin{table}[t]")
    tex.append("\\centering")
    tex.append(
        f"\\caption{{Partition-level stability under edge {perturbation} ($p={p}$).}}"
    )
    tex.append(
        f"\\label{{tab:{perturbation}_p{p.replace('.', '')}}}"
    )
    tex.append("\\resizebox{\\textwidth}{!}{%")
    tex.append("\\begin{tabular}{llcccccc}")
    tex.append("\\toprule")
    tex.append(
        "Network & Algorithm & NMI & ARI & AMI & NID & Jaccard & Prop. moved \\\\"
    )
    tex.append("\\midrule")

    for r in rows:
        tex.append(
            f"{r['Network']} & {r['Algorithm']} & "
            f"{format_value(r.get('NMI'))} & "
            f"{format_value(r.get('ARI'))} & "
            f"{format_value(r.get('AMI'))} & "
            f"{format_value(r.get('NID'))} & "
            f"{format_value(r.get('Jaccard'))} & "
            f"{format_value(r.get('proportion.moved'))} \\\\"
        )

    tex.append("\\bottomrule")
    tex.append("\\end{tabular}}")
    tex.append("\\end{table}")

    return "\n".join(tex)


# ===== MAIN =====

if __name__ == "__main__":
    os.makedirs("tables", exist_ok=True)

    for pert in PERTURBATIONS:
        for p in PS:
            tex = generate_table(pert, p)
            filename = f"tables/table_{pert}_p{p.replace('.', '')}.tex"
            with open(filename, "w") as f:
                f.write(tex)

            print(f"Generated: {filename}")
