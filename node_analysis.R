# =====================================================
# Node-level structural analysis based on node_metrics
# =====================================================

library(igraph)
library(data.table)
library(netUtils)


source("helper.R")

# ------------------------
# Parameters
# ------------------------
TOP_K <- 5
RESULTS_DIR <- "results"
ANALYSIS_DIR <- "analysis"

# ------------------------
# Recreate base networks (same as main.Rmd)
# ------------------------
set.seed(123)

n <- 1000
p <- 0.01
# =====================================================
# Node-level structural analysis based on node_metrics
# =====================================================

library(igraph)
library(data.table)
library(netUtils)

source("helper.R")

# ------------------------
# Parameters
# ------------------------
TOP_K <- 5
RESULTS_DIR <- "results"
ANALYSIS_DIR <- "analysis"

# ------------------------
# Recreate base networks (same as main.Rmd)
# ------------------------
set.seed(123)

n <- 1000
p <- 0.01

g_er <- sample_gnp(n, p, directed = FALSE)

g_ba <- sample_pa(
  n = n,
  m = 5,
  directed = FALSE,
  algorithm = "psumtree"
)

g_lfr <- sample_lfr(
  n = 1000,
  tau1 = 2,
  tau2 = 1,
  mu = 0.1,
  average_degree = 10,
  max_degree = 50,
  min_community = 20,
  max_community = 60
)

networks <- list(
  ER  = g_er,
  BA  = g_ba,
  LFR = g_lfr
)

# Consistent node naming
for (g in networks) {
  V(g)$name <- as.character(seq_len(vcount(g)))
}

# ------------------------
# Node properties
# ------------------------
compute_node_properties <- function(G, nodes, group) {
  data.frame(
    node = nodes,
    group = group,
    degree = degree(G)[nodes],
    betweenness = betweenness(G, normalized = TRUE)[nodes],
    closeness = closeness(G, normalized = TRUE)[nodes],
    eigenvector = eigen_centrality(G)$vector[nodes]
  )
}

# ------------------------
# Main loop (FULL structure)
# ------------------------
for (net_name in names(networks)) {

  G <- networks[[net_name]]
  net_path <- file.path(RESULTS_DIR, net_name)
  if (!dir.exists(net_path)) next

  for (pert in list.dirs(net_path, recursive = FALSE)) {
    pert_name <- basename(pert)

    for (frac in list.dirs(pert, recursive = FALSE)) {
      frac_name <- basename(frac)

      for (alg in list.dirs(frac, recursive = FALSE)) {
        alg_name <- basename(alg)

        node_csv <- file.path(alg, "node_metrics.csv")
        if (!file.exists(node_csv)) next

        cat("Processing:", net_name, pert_name, frac_name, alg_name, "\n")

        nm <- load_node_metrics(alg)
        nm <- nm[order(-mean)]

        most_changed  <- head(nm$node, TOP_K)
        least_changed <- tail(nm$node, TOP_K)

        df_most  <- compute_node_properties(G, most_changed,  "most_changed")
        df_least <- compute_node_properties(G, least_changed, "least_changed")

        out <- rbind(df_most, df_least)

        # Output path mirrors results/
        out_dir <- file.path(
          ANALYSIS_DIR,
          net_name,
          pert_name,
          frac_name,
          alg_name
        )

        dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

        write.csv(
          out,
          file.path(out_dir, "node_properties.csv"),
          row.names = FALSE
        )
      }
    }
  }
}

cat("Node-level structural analysis completed.\n")

