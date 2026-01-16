source("helper.R")
source("metrics.R")
source("perturbations.R")
source("spectral.R")

library(igraph)

run_analysis <- function(network, network.name, perturbations.list, fractions, clust.alg.list, stocastic.list, iter.stoc = 50, iter.pert = 100, seed = 42) {
  # Function to run the full analysis pipeline
  # Inputs:
  #   - network: igraph object representing the network
  #   - network.name: string name of the network
  #   - perturbations.list: list of perturbation functions
  #   - fractions: vector of fractions of edges/nodes to perturb
  #   - clust.alg.list: named list of clustering algorithm functions
  #   - stocastic.list: named list indicating if each clustering algorithm is stochastic (TRUE/FALSE)
  #   - iter.stoc: number of stochastic iterations for stochastic algorithms
  #   - iter.pert: number of perturbation iterations
  #   - seed: random seed for reproducibility of all the analysis

  set.seed(seed)

  V(network)$name <- as.character(seq_len(vcount(network)))

  for (pert.name in names(perturbations.list)) {
    perturbation <- perturbations.list[[pert.name]]
    cat("Starting analysis for perturbation:", pert.name, "\n")

  for (fraction in fractions) {
    cat("  Fraction:", fraction, "\n")

      iter_results <- list()

      # Precompute deterministic base clusterings for optimization
      base.clusterings <- list()
      for (alg.name in names(clust.alg.list)) {
        if (!stocastic.list[[alg.name]]) {
          base.clusterings[[alg.name]] <- clust.alg.list[[alg.name]](network)
        }
      }

      for (iter in 1:iter.pert) {
        iter_results[[iter]] <- list()

        perturbed_network <- perturbation(network, fraction)
        V(perturbed_network)$name <- V(network)$name

        cat("    Perturbation Iteration:", iter, "\n")

        for (i in seq_along(clust.alg.list)) {

          alg <- clust.alg.list[[i]]
          alg.name <- names(clust.alg.list)[i]

          cat("    Clustering Algorithm:", alg.name, "\n")

          iter_results[[iter]][[alg.name]] <- list()

          if (stocastic.list[[alg.name]]) {
            stoc.results.mean <- list()
            stoc.results.var <- list()

            for (j in 1:iter.stoc) {

              cat(paste("      Stochastic Iteration:", j, "\n"))

              if (alg.name == "leiden"){
                base.clustering <- alg(network, objective_function = "modularity")
                pert.clustering <- alg(perturbed_network, objective_function = "modularity")
              }else{
                base.clustering <- alg(network)
                pert.clustering <- alg(perturbed_network)
              }

              partition.metrics <- partition_metrics(base.clustering, pert.clustering)
              node.metrics <- node_metrics(base.clustering, pert.clustering)

              # Accumulate results for partition metrics
              for (metric.name in names(partition.metrics)) {
                if (is.null(stoc.results.mean[[metric.name]])) {
                  stoc.results.mean[[metric.name]] <- 0
                  stoc.results.var[[metric.name]] <- 0
                }
                stoc.results.mean[[metric.name]] <- stoc.results.mean[[metric.name]] + partition.metrics[[metric.name]]
                stoc.results.var[[metric.name]] <- stoc.results.var[[metric.name]] + partition.metrics[[metric.name]]^2
              }

              # Accumulate results for node metrics
              if (is.null(stoc.results.mean[["proportion.moved"]])) {
                  stoc.results.mean[["proportion.moved"]] <- 0
                  stoc.results.var[["proportion.moved"]] <- 0
              }
              stoc.results.mean[["proportion.moved"]] <- stoc.results.mean[["proportion.moved"]] + node.metrics[["proportion.moved"]]
              stoc.results.var[["proportion.moved"]] <- stoc.results.var[["proportion.moved"]] + node.metrics[["proportion.moved"]]^2

              if (is.null(stoc.results.mean[["moved"]])) {
                  stoc.results.mean[["moved"]] <- rep(0, length(node.metrics[["moved"]]))
                  stoc.results.var[["moved"]] <- rep(0, length(node.metrics[["moved"]]))
              }
              stoc.results.mean[["moved"]] <- stoc.results.mean[["moved"]] + node.metrics[["moved"]]
              stoc.results.var[["moved"]] <- stoc.results.var[["moved"]] + node.metrics[["moved"]]^2
            }

            # Average the results over the iterations
            for (metric.name in names(stoc.results.mean)) {
              stoc.results.mean[[metric.name]] <- stoc.results.mean[[metric.name]] / iter.stoc
              mean.sq <- stoc.results.mean[[metric.name]]^2
              stoc.results.var[[metric.name]] <- (stoc.results.var[[metric.name]] / iter.stoc) - mean.sq
            }

            # Store the averaged results with metadata
            iter_results[[iter]][[alg.name]] <-
              lapply(names(stoc.results.mean), function(m) {
                list(
                  mean = stoc.results.mean[[m]],
                  var  = stoc.results.var[[m]]
                )
              }) |>
              setNames(names(stoc.results.mean))


          } else {

            base.clustering <- base.clusterings[[alg.name]]
            pert.clustering <- alg(perturbed_network)

            partition.metrics <- partition_metrics(base.clustering, pert.clustering)
            node.metrics <- node_metrics(base.clustering, pert.clustering)

            results.mean <- c(partition.metrics, node.metrics)
            results.var <- lapply(results.mean, function(x) {
              if (is.numeric(x)) {
                return(0)
              } else {
                return(rep(0, length(x)))
              }
            })

            iter_results[[iter]][[alg.name]] <-
              lapply(names(results.mean), function(m) {
                list(
                  mean = results.mean[[m]],
                  var  = results.var[[m]]
                )
              }) |>
              setNames(names(results.mean))

          }
        }
      }

      # Aggregate results over all iterations 
      for (alg.name in names(clust.alg.list)) {

        # Extract metric names
        metric.names <- names(iter_results[[1]][[alg.name]])
        
        aggregated <- list()
        
        for (metric.name in metric.names) {
          
          if (metric.name == "moved") {
          
            # Extract matrix node metrics
            moved.means.matrix <- sapply(1:iter.pert, function(iter) {
              iter_results[[iter]][[alg.name]][[metric.name]]$mean
            })  # shape:  (n_nodes, iter.pert)
            
            moved.vars.matrix <- sapply(1:iter.pert, function(iter) {
              iter_results[[iter]][[alg.name]][[metric.name]]$var
            })  # shape: (n_nodes, iter. pert)
            
            # For each node, compute aggregated statistics
            n_nodes <- nrow(moved.means.matrix)

            # Mean of means of each node
            grand.mean <- rowMeans(moved.means.matrix)

            # Var of the means of each node, given by perturbations
            var.between <- apply(moved.means.matrix, 1, var)

            # Means of the variances of each node, given by stocastic clusterings 
            var.within <- rowMeans(moved.vars.matrix)

            # Total Variance
            var.total <- var.between + var.within

            # Standard Error for each node
            se <- sqrt(var.between / iter.pert + var.within / (iter.pert * iter.stoc))

            aggregated[[metric.name]] <- list(
              mean = grand.mean,
              var.total = var.total,
              var.between = var.between,
              var.within = var.within,
              se = se
            )

          } else {
            # Extract means and within variances for each perturbation
            means_i <- sapply(1:iter.pert, function(iter) {
              iter_results[[iter]][[alg.name]][[metric.name]]$mean
            })
            vars_within_i <- sapply(1:iter.pert, function(iter) {
              iter_results[[iter]][[alg.name]][[metric.name]]$var
            })
            
            # Mean of means
            grand.mean <- mean(means_i)
            
            # Variance of means, given by perturbations
            var.between <- var(means_i)
            
            # Mean of within variances, given by stocastic clusterings
            var.within <- mean(vars_within_i)
            
            # Total Variance
            var.total <- var.between + var.within
            
            aggregated[[metric.name]] <- list(
              mean = grand.mean,
              var.total = var.total,
              var.between = var.between,  # Perturbation variance
              var.within = var.within,    # Stochastic variance (0 if deterministic)
              se = sqrt(var.between / iter.pert + var.within / (iter.pert * iter.stoc))
            )
          }
        }

        # Save using helper functions
        result_path <- get_results_dir("results", network.name, pert.name, fraction, alg.name)
        save_scalar_metrics(aggregated, result_path)
        save_node_metrics(aggregated, result_path, node_names = V(network)$name)

      }

      cat("Completed analysis for perturbation:", pert.name, "and fraction:", fraction, "\n")

      # Clean up memory
      rm(aggregated)
      rm(result_path)
      rm(iter_results)
      gc()

    }  
  }

  cat("Analysis completed for all perturbations and fractions!\n")
}

