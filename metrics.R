library(igraph)
library(aricode)
source("cluster_labelling.R")

partition_metrics <- function(cluster1, cluster2) {
  # Function to compute global partition metrics between two clusterings
  # Inputs:
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  # Outputs:
  #   - metrics: list containing NMI, ARI, AMI, NID, and Jaccard indices

  c1 <- membership(cluster1)
  c2 <- membership(cluster2)

  n1 <- names(c1); n2 <- names(c2)
  if (is.null(n1) || is.null(n2)) stop("Membership vectors must have names to align vertices.", call. = FALSE)

  common <- intersect(n1, n2)
  c1 <- as.integer(c1[common])
  c2 <- as.integer(c2[common])

  nmi <- aricode::NMI(c1, c2)
  ari <- aricode::ARI(c1, c2)
  ami <- aricode::AMI(c1, c2)
  nid <- aricode::NID(c1, c2)
  jaccard <- compute_global_jaccard(cluster1, cluster2)

  return(list(
    NMI = nmi,
    ARI = ari,
    AMI = ami,
    NID = nid,
    Jaccard = jaccard
  ))
}

node_metrics <- function(cluster1, cluster2) {
  # Function to compute node-level metrics between two clusterings
  # Inputs:
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  # Outputs:
  #   - list containing:
  #       - moved: binary vector indicating which nodes changed clusters
  #       - proportion_moved: proportion of nodes that changed clusters

  moved.vertices <- node_refactor(cluster1, cluster2)
  proportion.moved <- sum(moved.vertices) / length(moved.vertices)

  return(list(
    moved = moved.vertices,
    proportion.moved = proportion.moved
  ))
}

# TESTING THE FUNCTIONS
if (FALSE) {
  source("perturbations.R")

  g <- make_graph("Zachary")
  g.rew <- edge_rewiring(g, fraction = 0.1, seed = 42)
  g.del <- edge_removal(g, fraction = 0.1, seed = 42)
  g.add <- edge_addition(g, fraction = 0.1, seed = 42)

  
  V(g)$name <- as.character(seq_len(vcount(g)))
  V(g.rew)$name <- V(g)$name
  V(g.del)$name <- V(g)$name
  V(g.add)$name <- V(g)$name

  cl1 <- cluster_walktrap(g)
  cl2 <- cluster_walktrap(g.rew)
  cl3 <- cluster_walktrap(g.del)
  cl4 <- cluster_walktrap(g.add)

  pm <- partition_metrics(cl1, cl2)
  print(pm)
  pm2 <- partition_metrics(cl1, cl3)
  print(pm2)
  pm3 <- partition_metrics(cl1, cl4)
  print(pm3)

  nm <- node_metrics(cl1, cl2)
  print(nm)
}



