library(igraph)

spectral_clustering_shi_malik <- function(G, max_k = 50, nstart = 25, show.messages = FALSE, seed = NULL) {
  # Function to perform spectral clustering using the Shi-Malik approach
  # Inputs:
  #   - G: igraph object (undirected, weighted or unweighted)
  #   - max_k: maximum number of clusters to consider for eigengap heuristic
  #   - nstart: number of random starts for k-means
  #   - show.messages: boolean to indicate whether to print messages
  #   - seed: random seed for reproducibility
  # Outputs:
  #   - igraph clustering object with cluster membership
  
  # Step 1: Get the adjacency matrix W
  if (is.null(E(G)$weight)) {
    W <- as.matrix(as_adjacency_matrix(G, sparse = FALSE))
  }else{
    W <- as.matrix(as_adjacency_matrix(G, attr = "weight", sparse = FALSE))
  }

  n <- nrow(W)
  
  # Step 2: Compute the unnormalized Laplacian L = D - W
  D <- diag(rowSums(W))
  L <- D - W
  
  # Step 3: Solve the generalized eigenvalue problem L v = lambda D v
  # This is equivalent to solving D^{-1} L v = lambda v
  # Or finding eigenvalues of D^{-1/2} L D^{-1/2} (symmetric normalized Laplacian)
  
  # Handle potential zero degrees (isolated nodes)
  d <- rowSums(W)
  d_inv <- ifelse(d > 0, 1 / d, 0)
  D_inv <- diag(d_inv)
  
  # Compute D^{-1} L for generalized eigenproblem
  # Eigenvalues of D^{-1} L correspond to generalized eigenproblem Lv = λDv
  L_rw <- D_inv %*% L  # Random walk Laplacian (Shi-Malik approach)
  
  # Compute eigenvalues and eigenvectors
  max_k <- min(max_k, n - 1)
  eigen_decomp <- eigen(L_rw, symmetric = FALSE)
  
  # Eigenvalues should be real and non-negative; sort by ascending order
  eigenvalues <- Re(eigen_decomp$values)
  eigenvectors <- Re(eigen_decomp$vectors)
  
  # Sort eigenvalues in ascending order
  sorted_idx <- order(eigenvalues)
  eigenvalues <- eigenvalues[sorted_idx]
  eigenvectors <- eigenvectors[, sorted_idx]
  
  # Step 4: Apply eigengap heuristic to determine k
  # Look for the largest gap between consecutive eigenvalues
  gaps <- diff(eigenvalues[1:max_k])
  k <- which.max(gaps)
  
  # Ensure k is at least 2
  if (k < 2) k <- 2
  
  if (show.messages) {
    cat("Eigenvalues (first", max_k, "):", round(eigenvalues[1:max_k], 4), "\n")
    cat("Eigengaps:", round(gaps, 4), "\n")
    cat("Selected k =", k, "clusters based on eigengap heuristic\n\n")
  }

  # Step 5: Take the first k eigenvectors as columns of V
  V <- eigenvectors[, 1:k]
  
  # Step 6: Each row yi of V is a point in R^k
  # (Rows are already the points yi)
  Y <- V
  
  # Step 7: Cluster using k-means
  if (!is.null(seed)) set.seed(seed)
  kmeans_result <- kmeans(Y, centers = k, nstart = nstart)
  
  clusters <- kmeans_result$cluster

  # Step 8: Create igraph clustering object
  cluster_graph <- make_clusters(G, membership = clusters, algorithm = "spectral_shi_malik")
  names(cluster_graph$membership) <- V(G)$name

  return(cluster_graph)
}


# TESTING THE FUNCTION
if(FALSE) {
  # Create a sample graph with 3 communities
  set.seed(123)
  G <- sample_islands(islands.n = 3, islands.size = 20, islands.pin = 0.8, n.inter = 3)

  # plot initial graph
  plot(G, 
      vertex.size = 8, 
      vertex.label = NA,
      main = "Original Graph with 3 Communities")

  # Run spectral clustering
  result <- spectral_clustering_shi_malik(G, max_k = 20)

  # View results
  cat("Cluster assignments:\n")
  print(result$membership)
  cat("Number of clusters detected:", length(unique(result$membership)), "\n")

  # Visualize the graph with cluster colors
  V(G)$color <- result$membership
  plot(G, 
      vertex.size = 8, 
      vertex.label = NA,
      main = paste("Spectral Clustering (Shi-Malik) - k =", result$k))
}