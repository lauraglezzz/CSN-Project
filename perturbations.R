library(igraph)

edge_addition <- function(G, fraction, seed = NULL) {
  # Function to add edges to a graph
  # Inputs:
  #   - G: igraph graph object
  #   - fraction: fraction of existing edges to add (between 0 and 1)
  #   - seed: optional random seed for reproducibility
  # Outputs:
  #   - G_perturbed: igraph graph object with added edges

  stopifnot(inherits(G, "igraph"))
  if (!(fraction > 0 && fraction < 1)) stop("fraction must be between 0 and 1", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)

  G_perturbed <- G
  num_to_add <- floor(fraction * ecount(G_perturbed))
  nodes <- seq_len(vcount(G_perturbed))   # usa ID numerici, non V(G)
  added <- 0L
  attempts <- 0L
  max_attempts <- num_to_add * 100L

  while (added < num_to_add && attempts < max_attempts) {
    sampled <- sample(nodes, 2)
    u <- sampled[1]
    v <- sampled[2]

    if (u == v || igraph::are.connected(G_perturbed, u, v)) {
      attempts <- attempts + 1L
      next
    }

    G_perturbed <- igraph::add_edges(G_perturbed, c(u, v))
    added <- added + 1L
    attempts <- attempts + 1L
  }

  if (added < num_to_add) {
    warning("Stopped edge addition early; graph may be close to saturated.")
  }

  G_perturbed
}

edge_removal <- function(G, fraction, seed = NULL) {
  # Function to remove edges from a graph
  # Inputs:
  #   - G: igraph graph object
  #   - fraction: fraction of existing edges to remove (between 0 and 1)
  #   - seed: optional random seed for reproducibility
  # Outputs:
  #   - G_perturbed: igraph graph object with removed edges

  stopifnot(inherits(G, "igraph"))
  if (!(fraction > 0 && fraction < 1)) stop("fraction must be between 0 and 1", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)

  G_perturbed <- G
  num_to_remove <- floor(fraction * igraph::ecount(G_perturbed))
  removed <- 0L

  while (removed < num_to_remove && igraph::ecount(G_perturbed) > 0) {
    edge_to_remove <- sample(igraph::E(G_perturbed), 1)
    G_perturbed <- igraph::delete_edges(G_perturbed, edge_to_remove)
    removed <- removed + 1L
  }

  G_perturbed
}

edge_rewiring <- function(G, fraction, seed = NULL) {
  # Function to rewire edges in a graph
  # Inputs:
  #   - G: igraph graph object
  #   - fraction: fraction of existing edges to rewire (between 0 and 1)
  #   - seed: optional random seed for reproducibility
  # Outputs:
  #   - G_perturbed: igraph graph object with rewired edges
  
  stopifnot(inherits(G, "igraph"))
  if (!(fraction > 0 && fraction < 1)) stop("fraction must be between 0 and 1", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)

  G_perturbed <- G

  num_to_rewire <- floor(fraction * igraph::ecount(G_perturbed))
  if (num_to_rewire == 0L) return(G_perturbed)

  nodes <- seq_len(vcount(G_perturbed))  # ID numerici
  rewired <- 0L
  attempts <- 0L
  max_attempts <- num_to_rewire * 50L

  while (rewired < num_to_rewire && attempts < max_attempts) {
    current_edge <- sample(igraph::E(G_perturbed), 1)

    new_pair <- sample(nodes, 2)
    a <- new_pair[1]
    b <- new_pair[2]

    if (a == b || igraph::are.connected(G_perturbed, a, b)) {
      attempts <- attempts + 1L
      next
    }

    G_perturbed <- igraph::delete_edges(G_perturbed, current_edge)
    G_perturbed <- igraph::add_edges(G_perturbed, c(a, b))

    rewired <- rewired + 1L
    attempts <- attempts + 1L
  }

  if (rewired < num_to_rewire) {
    warning("Stopped rewiring early; graph may already be saturated with edges.")
  }

  G_perturbed
}

# TESTING THE FUNCTIONS
if (FALSE) {
  g <- make_ring(100)

  g_added <- edge_addition(g, fraction = 0.2, seed = 42)
  print(g_added)

  g_removed <- edge_removal(g, fraction = 0.2, seed = 42)
  print(g_removed)

  g_rewired <- edge_rewiring(g, fraction = 0.2, seed = 42)
  print(g_rewired)
}
