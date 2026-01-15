source("jaccard.R")

compute_best_match <- function(cluster1, cluster2) {
  # Function to compute the best matching clusters between two clusterings
  # Inputs:
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  # Outputs:
  #   - best_match: matrix with two columns, where each row contains a pair
  #                 of best matching cluster IDs (from cluster1 and cluster2)
  
  # Compute Jaccard similarity matrix
  jaccard_similarity <- jaccard_sim(cluster1, cluster2)

  # Find the best match for each cluster in cluster1
  matches <- match_clusters(jaccard_similarity)

  # Prepare output, extracting the cluster IDs
  pairs <- names(matches)

  best_match <- t(
    apply(
      do.call(rbind, strsplit(gsub("[()]", "", pairs), ",")),
      1,
      function(row) as.integer(sub(".*\\.", "", row))
    )
  )

  # Add column with best local jaccard similarities
  jaccard_local <- sapply(1:nrow(best_match), function(i) {
    jaccard_similarity[best_match[i, 1], best_match[i, 2]]
  })

  best_match <- cbind(best_match, jaccard_local)

  # Get unique cluster2 IDs
  c2 <- unique(best_match[, 2])

  # Handle duplicates:  keep only the row with highest jaccard for each cluster2
  for (i in c2) {
    rows <- which(best_match[, 2] == i)
    if (length(rows) > 1) {
      # Select the row with the highest jaccard_local
      jaccards <- best_match[rows, 3]
      max_row <- rows[which.max(jaccards)]
      # Set column 2 to NA for other rows (duplicates with lower similarity)
      rows_to_na <- setdiff(rows, max_row)
      best_match[rows_to_na, 2] <- -1L 
    }
  }

  # Remove the jaccard_local column before returning
  best_match <- best_match[, 1:2, drop = FALSE]
    
  return(best_match)
}

node_refactor <- function(cluster1, cluster2) {
  # Function to identify nodes that have changed clusters between two
  # clusterings, accounting for possible relabeling of clusters. 
  # Inputs: 
  #   - cluster1: first clustering (igraph clustering object)
  #   - cluster2: second clustering (igraph clustering object)
  # Outputs:
  #   - moved :  binary vector indicating which nodes changed clusters

  # 1. Compute Jaccard similarities and cluster matches
  bm <- compute_best_match(cluster1, cluster2)

  # 2. Get membership vectors
  c1 <- membership(cluster1)
  c2 <- membership(cluster2)

  # Create corrected membership based on best matches
  membership1_corrected <- rep(-1L, length(c1))

  # Map cluster1 labels to cluster2 labels using best matches
  # Only iterate over non -1 values in column 2
  valid_matches <- bm[bm[, 2] != -1L, , drop = FALSE]

  for (i in seq_len(nrow(valid_matches))) {
    cl1 <- valid_matches[i, 1]  # cluster ID in cluster1
    cl2 <- valid_matches[i, 2]  # corresponding cluster ID in cluster2
    indices <- which(c1 == cl1)
    membership1_corrected[indices] <- cl2
  }

  # 3. Node is moved if:
  #    - cluster has no best match (-1 in membership1_corrected)
  #    - or mismatch after correction
  moved <- ifelse(
    membership1_corrected == -1L | membership1_corrected != c2,
    1L, 0L
  )

  names(moved) <- seq_along(moved)

  return(moved)
}

# TESTING THE FUNCTIONS
if (FALSE){
  library(igraph)
  g <- make_graph("Zachary")
  cluster1 <- cluster_label_prop(g)
  cluster2 <- cluster_label_prop(g)

  names(cluster1$membership) <- 1:vcount(g)
  names(cluster2$membership) <- 1:vcount(g)

  compute_best_match(cluster1, cluster2)
  node_refactor(cluster1, cluster2)
}

