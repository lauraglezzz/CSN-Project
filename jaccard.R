library(igraph)

jaccard_sim <- function(cluster1, cluster2) {
  # Function to compute the Jaccard similarity matrix between two clusterings
  # Inputs: 
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  # Outputs:
  #   - m:  Jaccard similarity matrix
  
  c1 <- membership(cluster1)
  c2 <- membership(cluster2)
  l1 <- length(cluster1)
  l2 <- length(cluster2)
  m <- matrix(nrow = l1, ncol = l2)
  
  for (i in 1:l1) {
    for (j in 1:l2) {
      set1 <- names(c1[unname(c1 == i)])
      set2 <- names(c2[unname(c2 == j)])
      int <- length(intersect(set1, set2))
      uni <- length(union(set1, set2))
      
      jacc <- int / uni
      
      m[i, j] <- jacc
    }
  }
  dimnames(m) <- list(1:l1, 1:l2)
  return(m)
}


match_clusters <- function(JS, name1 = "Cluster1", name2 = "Cluster2") {
  # Function to match clusters based on Jaccard similarity matrix.   
  # It chooses for each cluster in the first clustering the cluster in the
  # second clustering with the highest Jaccard similarity. 
  # Inputs:
  #   - JS: Jaccard similarity matrix with rows as clusters of the first
  #         clustering and columns as clusters of the second clustering
  #   - name1: name of the first clustering
  #   - name2: name of the second clustering
  # Outputs:
  #   - max_jaccard: named vector of maximum Jaccard similarities 
  #                  for each cluster in the first clustering
  
  n_clusters <- nrow(JS)
  
  max_jaccard <- numeric(n_clusters)
  names_vector <- character(n_clusters)
  
  for (i in 1:n_clusters) {
    j <- which.max(JS[i, ])
    max_jaccard[i] <- JS[i, j]
    names_vector[i] <- paste0("(", name1, ".", i, ",", name2, ".", j, ")")
  }
  
  names(max_jaccard) <- names_vector
  
  return(max_jaccard)
}


Wmean <- function(MC, cluster1, cluster2, JS = NULL) {
  # Function to compute the weighted mean of maximum Jaccard similarities
  # Inputs:
  #   - MC: named vector of maximum Jaccard similarities for each cluster
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  #   - JS: (optional) Jaccard similarity matrix between the two clusterings
  # Outputs:  
  #   - weighted_mean: weighted mean of maximum Jaccard similarities
  
  c1 <- membership(cluster1)
  c2 <- membership(cluster2)
  n_total <- length(c1)
  
  n_clusters <- length(MC)
  
  if (is.null(JS)) {
    JS <- jaccard_sim(cluster1, cluster2)
  }
  matched_indices <- apply(JS, 1, which.max)
  
  # Compute weights
  weights <- vapply(
    seq_len(n_clusters),
    function(i) length(which(c1 == i)) / n_total,
    numeric(1)
  )
  
  weighted_mean <- sum(MC * weights)
  
  return(weighted_mean)
}

compute_global_jaccard <- function(cluster1, cluster2, verbose = FALSE) {
  # Function to compute global Jaccard similarity between two clusterings
  # 
  # Inputs:
  #   - cluster1: first clustering (igraph clustering object from original network)
  #   - cluster2: second clustering (igraph clustering object from perturbed network)
  #   - verbose: if TRUE, print detailed information (default: FALSE)
  # 
  # Outputs:
  #   - global_jaccard:  weighted mean Jaccard similarity (scalar)
  
  # Compute Jaccard similarity matrix
  js_matrix <- jaccard_sim(cluster1, cluster2)
  
  # Match clusters
  matched <- match_clusters(js_matrix)
  
  # Compute weighted mean (global Jaccard)
  global_jacc <- Wmean(matched, cluster1, cluster2, js_matrix)
  
  if (verbose) {
    cat("Global Jaccard Similarity:", round(global_jacc, 4), "\n")
    cat("Number of clusters (cluster1):", length(cluster1), "\n")
    cat("Number of clusters (cluster2):", length(cluster2), "\n")
  }
  
  return(global_jacc)
}
